<#
.SYNOPSIS
    Sentinel-1 Automated Batch Processing Script for Windows (PowerShell)
    Sentinel-1 Windows自动化批处理脚本 (PowerShell版)

.DESCRIPTION
    This script processes Sentinel-1 GRD data using SNAP GPT.
    此脚本使用SNAP GPT处理Sentinel-1 GRD数据。

.PARAMETER InputDir
    Input directory containing Sentinel-1 ZIP files / 包含Sentinel-1 ZIP文件的输入目录

.PARAMETER OutputDir
    Output directory for processed files / 处理后文件的输出目录

.PARAMETER Graph
    SNAP Graph XML file / SNAP Graph XML文件

.PARAMETER Resolution
    Output resolution in meters / 输出分辨率(米)

.PARAMETER DEM
    Digital Elevation Model / 数字高程模型

.PARAMETER CRS
    Coordinate Reference System / 坐标参考系统

.EXAMPLE
    .\process.ps1
    .\process.ps1 -InputDir ".\data" -OutputDir ".\output" -Resolution 20
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage="Input directory / 输入目录")]
    [string]$InputDir = ".\data",
    
    [Parameter(HelpMessage="Output directory / 输出目录")]
    [string]$OutputDir = ".\output",
    
    [Parameter(HelpMessage="Graph XML file / Graph XML文件")]
    [string]$Graph = "graph.xml",
    
    [Parameter(HelpMessage="Resolution in meters / 分辨率(米)")]
    [int]$Resolution = 40,
    
    [Parameter(HelpMessage="Grid origin / 网格原点")]
    [double]$Origin = 0.0,
    
    [Parameter(HelpMessage="Speckle filter / 斑点滤波")]
    [string]$Filter = "Lee",
    
    [Parameter(HelpMessage="DEM model / 高程模型")]
    [string]$DEM = "ACE30",
    
    [Parameter(HelpMessage="Coordinate system / 坐标系")]
    [string]$CRS = "EPSG:3031",
    
    [Parameter(HelpMessage="Show help / 显示帮助")]
    [switch]$Help
)

# Set console encoding to UTF-8 / 设置控制台编码为UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# Script configuration / 脚本配置
$script:StartTime = Get-Date
$script:LogDir = ".\logs"
$script:LogFile = Join-Path $LogDir "$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:ProcessedCount = 0
$script:TotalCount = 0

# Initialize processing directories / 初始化处理目录
function Initialize-ProcessingDirectories {
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Log "[INFO] Created output directory / 创建输出目录: $OutputDir"
    }
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
}

# Logging function / 日志函数
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $Message
    Add-Content -Path $script:LogFile -Value $logMessage -Encoding UTF8
}

# Check SNAP installation / 检查SNAP安装
function Test-SnapInstallation {
    Write-Log "[CHECK] Checking SNAP installation / 检查SNAP安装..."
    
    # Try to find gpt in PATH / 尝试在PATH中查找gpt
    $gptPath = Get-Command gpt -ErrorAction SilentlyContinue
    if ($gptPath) {
        Write-Log "[OK] Found gpt at: $($gptPath.Source)"
        return $true
    }
    
    # Common SNAP installation paths / 常见SNAP安装路径
    $snapPaths = @(
        "C:\Program Files\snap\bin\gpt.exe",
        "$env:USERPROFILE\AppData\Local\snap\bin\gpt.exe",
        "$env:USERPROFILE\snap\bin\gpt.exe",
        "C:\snap\bin\gpt.exe"
    )
    
    foreach ($path in $snapPaths) {
        if (Test-Path $path) {
            $snapBin = Split-Path $path -Parent
            $env:PATH = "$snapBin;$env:PATH"
            Write-Log "[OK] Found SNAP at / 找到SNAP: $snapBin"
            return $true
        }
    }
    
    Write-Log "[ERROR] SNAP not found. Please install SNAP first."
    Write-Log "[ERROR] 未找到SNAP。请先安装SNAP。"
    Write-Log "[INFO] Download from / 下载地址: https://step.esa.int/main/download/snap-download/"
    return $false
}

# Invoke Sentinel-1 file processing / 调用Sentinel-1文件处理
function Invoke-Sentinel1FileProcessing {
    param(
        [string]$InputFile
    )
    
    $sceneName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
    $outputTif = Join-Path $OutputDir "$sceneName.tif"
    
    # Skip if already processed / 跳过已处理文件
    if (Test-Path $outputTif) {
        Write-Log "[SKIP] Already exists / 已存在: $sceneName"
        return $true
    }
    
    Write-Log "[PROC] Processing / 处理中: $sceneName"
    $procStart = Get-Date
    
    # Build GPT command / 构建GPT命令
    $gptArgs = @(
        $Graph,
        "-Pinput=`"$InputFile`"",
        "-Poutput=`"$outputTif`"",
        "-Presolution=$Resolution",
        "-Porigin=$Origin",
        "-Pfilter=$Filter",
        "-Pdem=$DEM",
        "-Pcrs=$CRS"
    )
    
    try {
        $process = Start-Process -FilePath "gpt" -ArgumentList $gptArgs -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$LogDir\gpt_stdout.tmp" -RedirectStandardError "$LogDir\gpt_stderr.tmp"
        
        # Append GPT output to log / 将GPT输出追加到日志
        if (Test-Path "$LogDir\gpt_stdout.tmp") {
            Get-Content "$LogDir\gpt_stdout.tmp" | Add-Content $script:LogFile
            Remove-Item "$LogDir\gpt_stdout.tmp" -Force
        }
        if (Test-Path "$LogDir\gpt_stderr.tmp") {
            Get-Content "$LogDir\gpt_stderr.tmp" | Add-Content $script:LogFile
            Remove-Item "$LogDir\gpt_stderr.tmp" -Force
        }
        
        if ($process.ExitCode -eq 0 -and (Test-Path $outputTif)) {
            $duration = (Get-Date) - $procStart
            $fileSize = (Get-Item $outputTif).Length / 1MB
            Write-Log "[OK] Success / 成功: $sceneName ($([math]::Round($fileSize, 2)) MB, $([math]::Round($duration.TotalSeconds, 0))s)"
            return $true
        } else {
            Write-Log "[FAIL] Processing failed / 处理失败: $sceneName"
            return $false
        }
    } catch {
        Write-Log "[ERROR] Exception / 异常: $_"
        return $false
    }
}

# Invoke Sentinel-1 batch processing / 调用Sentinel-1批处理
function Invoke-Sentinel1BatchProcessing {
    Write-Log "[SCAN] Scanning directory / 扫描目录: $InputDir"
    
    $zipFiles = Get-ChildItem -Path $InputDir -Filter "*.zip" -File
    $script:TotalCount = $zipFiles.Count
    
    if ($TotalCount -eq 0) {
        Write-Log "[WARN] No ZIP files found / 未找到ZIP文件"
        return
    }
    
    Write-Log "[INFO] Found $TotalCount ZIP files / 找到 $TotalCount 个ZIP文件"
    Write-Host ""
    
    $current = 0
    foreach ($zipFile in $zipFiles) {
        $current++
        Write-Log "--------------------------------------------------------"
        Write-Log "[FILE] File $current/$TotalCount : $($zipFile.Name)"
        
        # Check if Sentinel-1 file / 检查是否为Sentinel-1文件
        if ($zipFile.Name -notmatch "^S1") {
            Write-Log "[SKIP] Not a Sentinel-1 file / 非Sentinel-1文件"
            continue
        }
        
        if (Invoke-Sentinel1FileProcessing -InputFile $zipFile.FullName) {
            $script:ProcessedCount++
        }
    }
}

# Write processing summary / 输出处理摘要
function Write-ProcessingSummary {
    $duration = (Get-Date) - $script:StartTime
    
    Write-Host ""
    Write-Log "========================================================"
    Write-Log "[SUMMARY] Processing complete / 处理完成"
    Write-Log "[SUMMARY] Total files / 总文件数: $script:TotalCount"
    Write-Log "[SUMMARY] Successfully processed / 成功处理: $script:ProcessedCount"
    Write-Log "[SUMMARY] Total time / 总时间: $([math]::Round($duration.TotalMinutes, 2)) minutes / 分钟"
    Write-Log "[SUMMARY] Output directory / 输出目录: $OutputDir"
    Write-Log "[SUMMARY] Log file / 日志文件: $script:LogFile"
    Write-Log "========================================================"
}

# Main execution / 主执行
function Invoke-Sentinel1Processing {
    Write-Host "============================================================"
    Write-Host "Sentinel-1 Batch Processing Script for Windows (PowerShell)"
    Write-Host "Sentinel-1 Windows批处理脚本 (PowerShell版)"
    Write-Host "============================================================"
    Write-Host ""
    
    # Initialize / 初始化
    Initialize-ProcessingDirectories
    
    Write-Log "[CONFIG] Using parameters / 使用参数:"
    Write-Log "  - Input directory / 输入目录: $InputDir"
    Write-Log "  - Output directory / 输出目录: $OutputDir"
    Write-Log "  - Graph file / Graph文件: $Graph"
    Write-Log "  - Resolution / 分辨率: ${Resolution}m"
    Write-Log "  - DEM: $DEM"
    Write-Log "  - Coordinate system / 坐标系: $CRS"
    Write-Host ""
    
    # Check environment / 检查环境
    if (-not (Test-SnapInstallation)) {
        exit 1
    }
    
    # Verify input directory / 验证输入目录
    if (-not (Test-Path $InputDir)) {
        Write-Log "[ERROR] Input directory does not exist / 输入目录不存在: $InputDir"
        exit 1
    }
    
    # Verify graph file / 验证Graph文件
    if (-not (Test-Path $Graph)) {
        Write-Log "[ERROR] Graph file does not exist / Graph文件不存在: $Graph"
        exit 1
    }
    
    Write-Host ""
    Write-Log "[START] Starting Sentinel-1 data processing / 开始Sentinel-1数据处理"
    Write-Log "[TIME] Start time / 开始时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host ""
    
    # Process files / 处理文件
    Invoke-Sentinel1BatchProcessing
    
    # Show summary / 显示摘要
    Write-ProcessingSummary
}

# Run main / 运行主函数
Invoke-Sentinel1Processing
