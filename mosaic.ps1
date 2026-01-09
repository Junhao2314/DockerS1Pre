<#
.SYNOPSIS
    GeoTIFF Mosaic Script for Windows (PowerShell)
    Windows GeoTIFF镶嵌脚本 (PowerShell版)

.DESCRIPTION
    This script creates a mosaic from multiple GeoTIFF files using GDAL.
    此脚本使用GDAL从多个GeoTIFF文件创建镶嵌。

.PARAMETER InputDir
    Input directory containing TIF files / 包含TIF文件的输入目录

.PARAMETER OutputFile
    Output mosaic file path / 输出镶嵌文件路径

.PARAMETER Resolution
    Output resolution in meters / 输出分辨率(米)

.PARAMETER Resampling
    Resampling method (average, min, max, nearest, mode) / 重采样方法

.PARAMETER CRS
    Target coordinate reference system / 目标坐标参考系统

.EXAMPLE
    .\mosaic.ps1
    .\mosaic.ps1 -InputDir ".\output" -OutputFile ".\mosaic\result.tif" -Resolution 20
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage="Input directory with TIF files / 包含TIF文件的输入目录")]
    [string]$InputDir = ".\output",
    
    [Parameter(HelpMessage="Output mosaic file / 输出镶嵌文件")]
    [string]$OutputFile = ".\mosaic\mosaic.tif",
    
    [Parameter(HelpMessage="Resolution in meters / 分辨率(米)")]
    [int]$Resolution = 40,
    
    [Parameter(HelpMessage="Resampling method / 重采样方法")]
    [ValidateSet("average", "min", "max", "nearest", "mode")]
    [string]$Resampling = "average",
    
    [Parameter(HelpMessage="Target CRS / 目标坐标系")]
    [string]$CRS = "EPSG:4326"
)

# Set console encoding / 设置控制台编码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Check GDAL installation / 检查GDAL安装
function Test-GdalInstallation {
    Write-Host "[CHECK] Checking GDAL installation / 检查GDAL安装..."
    
    # Try to find gdalbuildvrt in PATH / 尝试在PATH中查找gdalbuildvrt
    $gdalPath = Get-Command gdalbuildvrt -ErrorAction SilentlyContinue
    if ($gdalPath) {
        Write-Host "[OK] Found GDAL at: $($gdalPath.Source)" -ForegroundColor Green
        return $true
    }
    
    # Common GDAL installation paths / 常见GDAL安装路径
    $gdalPaths = @(
        "C:\OSGeo4W64\bin",
        "C:\OSGeo4W\bin",
        "C:\Program Files\GDAL\bin",
        "$env:USERPROFILE\anaconda3\Library\bin",
        "$env:USERPROFILE\miniconda3\Library\bin"
    )
    
    # Also check QGIS installations / 也检查QGIS安装
    $qgisPaths = Get-ChildItem "C:\Program Files\QGIS*" -Directory -ErrorAction SilentlyContinue
    foreach ($qgis in $qgisPaths) {
        $gdalPaths += "$($qgis.FullName)\bin"
    }
    
    foreach ($path in $gdalPaths) {
        if (Test-Path "$path\gdalbuildvrt.exe") {
            $env:PATH = "$path;$env:PATH"
            Write-Host "[OK] Found GDAL at / 找到GDAL: $path" -ForegroundColor Green
            return $true
        }
    }
    
    Write-Host "[ERROR] GDAL not found. Please install GDAL first." -ForegroundColor Red
    Write-Host "[ERROR] 未找到GDAL。请先安装GDAL。" -ForegroundColor Red
    Write-Host ""
    Write-Host "[INFO] Installation options / 安装选项:"
    Write-Host "  1. OSGeo4W: https://trac.osgeo.org/osgeo4w/"
    Write-Host "  2. Conda: conda install -c conda-forge gdal"
    Write-Host "  3. QGIS includes GDAL / QGIS包含GDAL"
    return $false
}

# Main execution / 主执行
function Main {
    Write-Host "============================================================"
    Write-Host "GeoTIFF Mosaic Script for Windows (PowerShell)"
    Write-Host "Windows GeoTIFF镶嵌脚本 (PowerShell版)"
    Write-Host "============================================================"
    Write-Host ""
    
    # Check GDAL / 检查GDAL
    if (-not (Test-GdalInstallation)) {
        exit 1
    }
    
    # Verify input directory / 验证输入目录
    if (-not (Test-Path $InputDir)) {
        Write-Host "[ERROR] Input directory does not exist / 输入目录不存在: $InputDir" -ForegroundColor Red
        exit 1
    }
    
    # Create output directory / 创建输出目录
    $outputDir = Split-Path $OutputFile -Parent
    if ($outputDir -and -not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        Write-Host "[INFO] Created output directory / 创建输出目录: $outputDir"
    }
    
    # Count input files and handle wildcards / 统计输入文件并处理通配符
    $hasWildcard = $InputDir.Contains("*") -or $InputDir.Contains("?")
    if ($hasWildcard) {
        # User passed a wildcard pattern (e.g. .\output\*.tif) / 用户传入带通配符的路径
        $tifFiles = Get-ChildItem -Path $InputDir -File
        $inputPattern = $InputDir
    } else {
        # Plain directory, append *.tif / 纯目录，自动追加 *.tif
        $tifFiles = Get-ChildItem -Path $InputDir -Filter "*.tif" -File
        $inputPattern = Join-Path $InputDir "*.tif"
    }
    $fileCount = $tifFiles.Count
    
    Write-Host ""
    Write-Host "[CONFIG] Configuration / 配置:"
    Write-Host "  - Input directory / 输入目录: $InputDir"
    Write-Host "  - Output file / 输出文件: $OutputFile"
    Write-Host "  - Resolution / 分辨率: ${Resolution}m"
    Write-Host "  - Resampling / 重采样: $Resampling"
    Write-Host "  - Target CRS / 目标坐标系: $CRS"
    Write-Host "  - Input files / 输入文件数: $fileCount"
    Write-Host ""
    
    if ($fileCount -eq 0) {
        Write-Host "[ERROR] No TIF files found in input directory" -ForegroundColor Red
        Write-Host "[ERROR] 输入目录中未找到TIF文件" -ForegroundColor Red
        exit 1
    }
    
    $startTime = Get-Date
    $vrtFile = "mosaic_temp.vrt"
    
    # Step 1: Create VRT / 步骤1：创建VRT
    Write-Host "[STEP 1/3] Creating VRT mosaic file / 创建VRT镶嵌文件..."
    
    try {
        & gdalbuildvrt -tr $Resolution $Resolution -r $Resampling -a_srs $CRS $vrtFile $inputPattern 2>&1 | Out-Null
        if (-not (Test-Path $vrtFile)) {
            throw "VRT file not created"
        }
        Write-Host "[OK] VRT file created / VRT文件创建成功" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to create VRT file / 创建VRT文件失败" -ForegroundColor Red
        Write-Host "Error: $_"
        exit 1
    }
    Write-Host ""
    
    # Step 2: Convert to GeoTIFF / 步骤2：转换为GeoTIFF
    Write-Host "[STEP 2/3] Converting VRT to GeoTIFF / 转换VRT为GeoTIFF..."
    try {
        & gdal_translate -of GTiff -co COMPRESS=LZW -co TILED=YES -co BIGTIFF=YES $vrtFile $OutputFile 2>&1 | Out-Null
        if (-not (Test-Path $OutputFile)) {
            throw "GeoTIFF file not created"
        }
        Write-Host "[OK] GeoTIFF created / GeoTIFF创建成功" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to create GeoTIFF / 创建GeoTIFF失败" -ForegroundColor Red
        Write-Host "Error: $_"
        Remove-Item $vrtFile -Force -ErrorAction SilentlyContinue
        exit 1
    }
    Write-Host ""
    
    # Step 3: Create pyramids / 步骤3：创建金字塔
    Write-Host "[STEP 3/3] Creating pyramids (overviews) / 创建金字塔..."
    try {
        & gdaladdo -r $Resampling --config COMPRESS_OVERVIEW LZW $OutputFile 2 4 8 16 2>&1 | Out-Null
        Write-Host "[OK] Pyramids created / 金字塔创建成功" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Failed to create pyramids / 创建金字塔失败" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Clean up / 清理
    Remove-Item $vrtFile -Force -ErrorAction SilentlyContinue
    
    # Summary / 摘要
    $duration = (Get-Date) - $startTime
    $fileSize = (Get-Item $OutputFile).Length / 1MB
    
    Write-Host "============================================================"
    Write-Host "[DONE] Mosaic complete / 镶嵌完成" -ForegroundColor Green
    Write-Host "[OUTPUT] Output file / 输出文件: $OutputFile"
    Write-Host "[SIZE] File size / 文件大小: $([math]::Round($fileSize, 2)) MB"
    Write-Host "[TIME] Duration / 耗时: $([math]::Round($duration.TotalSeconds, 0)) seconds / 秒"
    Write-Host "============================================================"
}

# Run main / 运行主函数
Main
