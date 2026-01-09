@echo off
chcp 65001 >nul
REM GeoTIFF Mosaic Script for Windows
REM Windows GeoTIFF镶嵌脚本
REM ============================================================

setlocal enabledelayedexpansion

REM Default configuration / 默认配置
set "INPUT_DIR=.\output"
set "OUTPUT_TIF=.\mosaic\mosaic.tif"
set "RESAMPLING=average"
set "RESOLUTION=40"
set "TARGET_SRS=EPSG:4326"

REM Parse command line arguments / 解析命令行参数
:parse_args
if "%~1"=="" goto :end_parse
if /i "%~1"=="-i" (set "INPUT_DIR=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="--input" (set "INPUT_DIR=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="-o" (set "OUTPUT_TIF=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="--output" (set "OUTPUT_TIF=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="-r" (set "RESOLUTION=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="--resolution" (set "RESOLUTION=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="-s" (set "RESAMPLING=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="--resampling" (set "RESAMPLING=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="-c" (set "TARGET_SRS=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="--crs" (set "TARGET_SRS=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="--help" goto :show_help
echo [ERROR] Unknown parameter: %~1 / 未知参数: %~1
goto :show_help
:end_parse

echo ============================================================
echo GeoTIFF Mosaic Script for Windows
echo Windows GeoTIFF镶嵌脚本
echo ============================================================
echo.

REM Check GDAL installation / 检查GDAL安装
call :check_gdal
if errorlevel 1 (
    echo [ERROR] GDAL check failed / GDAL检查失败
    exit /b 1
)

REM Verify input directory / 验证输入目录
if not exist "%INPUT_DIR%" (
    echo [ERROR] Input directory does not exist: %INPUT_DIR%
    echo [ERROR] 输入目录不存在: %INPUT_DIR%
    exit /b 1
)

REM Create output directory / 创建输出目录
for %%f in ("%OUTPUT_TIF%") do set "OUTPUT_DIR=%%~dpf"
if defined OUTPUT_DIR (
    if not "%OUTPUT_DIR%"=="" (
        if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
    )
)

echo [CONFIG] Configuration / 配置:
echo   - Input directory / 输入目录: %INPUT_DIR%
echo   - Output file / 输出文件: %OUTPUT_TIF%
echo   - Resolution / 分辨率: %RESOLUTION%m
echo   - Resampling / 重采样: %RESAMPLING%
echo   - Target CRS / 目标坐标系: %TARGET_SRS%
echo.

REM Count input files and create file list / 统计输入文件并创建文件列表
REM Windows CMD doesn't support wildcards in gdalbuildvrt, need to create a file list
REM Windows CMD 不支持在 gdalbuildvrt 中使用通配符，需要创建文件列表
set file_count=0
set "FILE_LIST=tif_filelist.txt"
if exist "%FILE_LIST%" del "%FILE_LIST%"

REM Build input pattern: allow user wildcards or plain directory
REM 构建输入通配符模式：支持用户自带通配符或纯目录
set "INPUT_PATTERN=%INPUT_DIR%"

REM If no wildcard in INPUT_DIR, append *.tif / 如果输入中没有通配符，则追加 *.tif
echo %INPUT_PATTERN% | find "*" >nul
if errorlevel 1 (
    echo %INPUT_PATTERN% | find "?" >nul
    if errorlevel 1 (
        set "INPUT_PATTERN=%INPUT_DIR%\*.tif"
    )
)

for %%f in ("%INPUT_PATTERN%") do (
    set /a file_count+=1
    echo %%f>> "%FILE_LIST%"
)

echo [INFO] Found %file_count% TIF files / 找到 %file_count% 个TIF文件
echo.

if %file_count%==0 (
    echo [ERROR] No TIF files found in input directory
    echo [ERROR] 输入目录中未找到TIF文件
    if exist "%FILE_LIST%" del "%FILE_LIST%"
    exit /b 1
)

REM Step 1: Create VRT mosaic using file list / 步骤1：使用文件列表创建VRT镶嵌
echo [STEP 1/3] Creating VRT mosaic file / 创建VRT镶嵌文件...
gdalbuildvrt -tr %RESOLUTION% %RESOLUTION% -r %RESAMPLING% -a_srs %TARGET_SRS% -input_file_list "%FILE_LIST%" mosaic.vrt
if errorlevel 1 (
    echo [ERROR] Failed to create VRT file / 创建VRT文件失败
    if exist "%FILE_LIST%" del "%FILE_LIST%"
    exit /b 1
)
echo [OK] VRT file created / VRT文件创建成功
echo.

REM Clean up file list / 清理文件列表
if exist "%FILE_LIST%" del "%FILE_LIST%"

REM Step 2: Convert VRT to GeoTIFF / 步骤2：转换VRT为GeoTIFF
echo [STEP 2/3] Converting VRT to GeoTIFF / 转换VRT为GeoTIFF...
gdal_translate -of GTiff -co COMPRESS=LZW -co TILED=YES -co BIGTIFF=YES mosaic.vrt "%OUTPUT_TIF%"
if errorlevel 1 (
    echo [ERROR] Failed to create GeoTIFF / 创建GeoTIFF失败
    del mosaic.vrt 2>nul
    exit /b 1
)
echo [OK] GeoTIFF created / GeoTIFF创建成功
echo.

REM Step 3: Create pyramids / 步骤3：创建金字塔
echo [STEP 3/3] Creating pyramids (overviews) / 创建金字塔...
gdaladdo -r %RESAMPLING% --config COMPRESS_OVERVIEW LZW "%OUTPUT_TIF%" 2 4 8 16
if errorlevel 1 (
    echo [WARN] Failed to create pyramids / 创建金字塔失败
) else (
    echo [OK] Pyramids created / 金字塔创建成功
)
echo.

REM Clean up / 清理
del mosaic.vrt 2>nul

REM Get output file size / 获取输出文件大小
for %%f in ("%OUTPUT_TIF%") do set "file_size=%%~zf"
if defined file_size (
    set /a file_size_mb=%file_size% / 1048576
) else (
    set file_size_mb=0
)

echo ============================================================
echo [DONE] Mosaic complete / 镶嵌完成
echo [OUTPUT] Output file / 输出文件: %OUTPUT_TIF%
echo [SIZE] File size / 文件大小: ~%file_size_mb% MB
echo ============================================================
goto :eof

REM ============================================================
REM Functions / 函数
REM ============================================================

:check_gdal
where gdalbuildvrt >nul 2>&1
if errorlevel 1 (
    echo [WARN] GDAL not found in PATH / 未在PATH中找到GDAL
    echo.
    echo [INFO] Please install GDAL. Options / 请安装GDAL。选项:
    echo   1. OSGeo4W: https://trac.osgeo.org/osgeo4w/
    echo   2. Conda: conda install -c conda-forge gdal
    echo   3. QGIS includes GDAL / QGIS包含GDAL
    echo.
    
    REM Try common GDAL paths / 尝试常见GDAL路径
    if exist "C:\OSGeo4W64\bin\gdalbuildvrt.exe" (
        set "PATH=C:\OSGeo4W64\bin;%PATH%"
        echo [INFO] Found GDAL at: C:\OSGeo4W64\bin
        exit /b 0
    )
    if exist "C:\OSGeo4W\bin\gdalbuildvrt.exe" (
        set "PATH=C:\OSGeo4W\bin;%PATH%"
        echo [INFO] Found GDAL at: C:\OSGeo4W\bin
        exit /b 0
    )
    
    REM Check QGIS installations / 检查QGIS安装
    for /d %%d in ("C:\Program Files\QGIS*") do (
        if exist "%%d\bin\gdalbuildvrt.exe" (
            set "PATH=%%d\bin;%PATH%"
            echo [INFO] Found GDAL at: %%d\bin
            exit /b 0
        )
    )
    
    echo [ERROR] GDAL not found. Please install GDAL first.
    echo [ERROR] 未找到GDAL。请先安装GDAL。
    exit /b 1
)
echo [OK] GDAL found / 找到GDAL
exit /b 0

:show_help
echo.
echo GeoTIFF Mosaic Script for Windows
echo Windows GeoTIFF镶嵌脚本
echo.
echo Usage / 用法: %~nx0 [options]
echo.
echo Options / 选项:
echo   -i, --input       Input directory with TIF files / 包含TIF文件的输入目录
echo                     (default: .\output)
echo   -o, --output      Output mosaic file / 输出镶嵌文件
echo                     (default: .\mosaic\mosaic.tif)
echo   -r, --resolution  Output resolution in meters / 输出分辨率(米)
echo                     (default: 40)
echo   -s, --resampling  Resampling method / 重采样方法
echo                     Options: average, min, max, nearest, mode
echo                     (default: average)
echo   -c, --crs         Target coordinate system / 目标坐标系
echo                     (default: EPSG:4326)
echo   -h, --help        Show this help / 显示帮助
echo.
echo Examples / 示例:
echo   %~nx0
echo   %~nx0 -i output -o result\mosaic.tif
echo   %~nx0 -i C:\data\tifs -o C:\result\mosaic.tif -r 20
echo.
exit /b 0
