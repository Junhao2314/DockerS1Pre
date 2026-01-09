@echo off
chcp 65001 >nul
REM Sentinel-1 Automated Batch Processing Script for Windows
REM Sentinel-1 Windows自动化批处理脚本
REM ============================================================

setlocal enabledelayedexpansion

REM Default parameter configuration / 默认参数配置
set "DEFAULT_INPUT_DIR=.\data"
set "DEFAULT_OUTPUT_DIR=.\output"
set "DEFAULT_RESOLUTION=40"
set "DEFAULT_ORIGIN=0.0"
set "DEFAULT_FILTER=Lee"
set "DEFAULT_DEM=ACE30"
set "DEFAULT_CRS=EPSG:3031"
set "DEFAULT_GRAPH=graph.xml"

REM Initialize parameters / 初始化参数
set "INPUT_DIR=%DEFAULT_INPUT_DIR%"
set "OUTPUT_DIR=%DEFAULT_OUTPUT_DIR%"
set "RESOLUTION=%DEFAULT_RESOLUTION%"
set "ORIGIN=%DEFAULT_ORIGIN%"
set "FILTER=%DEFAULT_FILTER%"
set "DEM=%DEFAULT_DEM%"
set "CRS=%DEFAULT_CRS%"
set "GRAPH=%DEFAULT_GRAPH%"
set "BATCH_MODE=false"

REM Parse command line arguments / 解析命令行参数
:parse_args
if "%~1"=="" goto :end_parse
if /i "%~1"=="-i" (set "INPUT_DIR=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="--input" (set "INPUT_DIR=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="-o" (set "OUTPUT_DIR=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="--output" (set "OUTPUT_DIR=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="-g" (set "GRAPH=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="--graph" (set "GRAPH=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="-r" (set "RESOLUTION=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="--resolution" (set "RESOLUTION=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="-a" (set "ORIGIN=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="--origin" (set "ORIGIN=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="-f" (set "FILTER=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="--filter" (set "FILTER=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="-d" (set "DEM=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="--dem" (set "DEM=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="-c" (set "CRS=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="--crs" (set "CRS=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="-b" (set "BATCH_MODE=true" & shift & goto :parse_args)
if /i "%~1"=="--batch" (set "BATCH_MODE=true" & shift & goto :parse_args)
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="--help" goto :show_help
echo [ERROR] Unknown parameter: %~1 / 未知参数: %~1
goto :show_help
:end_parse

REM Create output directory / 创建输出目录
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
if not exist "logs" mkdir "logs"

REM Generate log filename / 生成日志文件名
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set "LOG_FILE=logs\%datetime:~0,8%_%datetime:~8,6%.log"

REM Display configuration / 显示配置
echo ============================================================
echo Sentinel-1 Batch Processing Script for Windows
echo Sentinel-1 Windows批处理脚本
echo ============================================================
echo.
echo [CONFIG] Using parameters / 使用参数:
echo   - Input directory / 输入目录: %INPUT_DIR%
echo   - Output directory / 输出目录: %OUTPUT_DIR%
echo   - Graph file / Graph文件: %GRAPH%
echo   - Resolution / 分辨率: %RESOLUTION%m
echo   - DEM: %DEM%
echo   - Coordinate system / 坐标系: %CRS%
echo   - Mode / 模式: %BATCH_MODE%
echo.

REM Check environment / 检查环境
call :check_environment
if errorlevel 1 (
    echo [ERROR] Environment check failed / 环境检查失败
    exit /b 1
)

REM Verify input directory / 验证输入目录
if not exist "%INPUT_DIR%" (
    echo [ERROR] Input directory does not exist: %INPUT_DIR%
    echo [ERROR] 输入目录不存在: %INPUT_DIR%
    exit /b 1
)

REM Verify graph file / 验证Graph文件
if not exist "%GRAPH%" (
    echo [ERROR] Graph file does not exist: %GRAPH%
    echo [ERROR] Graph文件不存在: %GRAPH%
    exit /b 1
)

REM Start processing / 开始处理
echo [START] Starting Sentinel-1 data processing / 开始Sentinel-1数据处理
echo [TIME] Start time / 开始时间: %date% %time%
echo.

call :batch_process

echo.
echo [DONE] Processing complete / 处理完成
echo [LOG] Log file / 日志文件: %LOG_FILE%
goto :eof

REM ============================================================
REM Functions / 函数
REM ============================================================

:check_environment
REM Check if gpt command is available / 检查gpt命令是否可用
where gpt >nul 2>&1
if errorlevel 1 (
    echo [WARN] gpt command not found in PATH / 未在PATH中找到gpt命令
    echo [INFO] Please ensure SNAP is installed and gpt.exe is in PATH
    echo [INFO] 请确保已安装SNAP并且gpt.exe在PATH中
    echo.
    echo [INFO] Typical SNAP installation paths / 典型SNAP安装路径:
    echo        C:\Program Files\snap\bin\gpt.exe
    echo        C:\Users\USERNAME\AppData\Local\snap\bin\gpt.exe
    echo.
    
    REM Try common SNAP paths / 尝试常见SNAP路径
    if exist "C:\Program Files\snap\bin\gpt.exe" (
        set "PATH=C:\Program Files\snap\bin;%PATH%"
        echo [INFO] Found SNAP at: C:\Program Files\snap\bin
        exit /b 0
    )
    if exist "%USERPROFILE%\AppData\Local\snap\bin\gpt.exe" (
        set "PATH=%USERPROFILE%\AppData\Local\snap\bin;%PATH%"
        echo [INFO] Found SNAP at: %USERPROFILE%\AppData\Local\snap\bin
        exit /b 0
    )
    if exist "%USERPROFILE%\snap\bin\gpt.exe" (
        set "PATH=%USERPROFILE%\snap\bin;%PATH%"
        echo [INFO] Found SNAP at: %USERPROFILE%\snap\bin
        exit /b 0
    )
    
    echo [ERROR] SNAP not found. Please install SNAP first.
    echo [ERROR] 未找到SNAP。请先安装SNAP。
    echo [INFO] Download from / 下载地址: https://step.esa.int/main/download/snap-download/
    exit /b 1
)
echo [OK] gpt command found / 找到gpt命令
exit /b 0

:batch_process
set count=0
set processed=0

echo [SCAN] Scanning directory: %INPUT_DIR% / 扫描目录: %INPUT_DIR%
echo.

for %%f in ("%INPUT_DIR%\*.zip") do (
    set /a count+=1
    set "zip_file=%%f"
    set "scene_name=%%~nf"
    
    echo --------------------------------------------------
    echo [FILE] Processing file !count!: !scene_name!
    echo [FILE] 处理文件 !count!: !scene_name!
    
    REM Check if it's a Sentinel-1 file / 检查是否为Sentinel-1文件
    echo !scene_name! | findstr /b "S1" >nul
    if errorlevel 1 (
        echo [SKIP] Not a Sentinel-1 file / 非Sentinel-1文件
    ) else (
        call :process_file "%%f" "!scene_name!"
        if not errorlevel 1 set /a processed+=1
    )
)

echo ==================================================
echo [SUMMARY] Processing complete / 处理完成
echo [SUMMARY] Total files / 总文件数: %count%
echo [SUMMARY] Successfully processed / 成功处理: %processed%
echo [SUMMARY] Output directory / 输出目录: %OUTPUT_DIR%
exit /b 0

:process_file
set "input_zip=%~1"
set "scene_name=%~2"
set "output_tif=%OUTPUT_DIR%\%scene_name%.tif"

REM Skip if already processed / 跳过已处理文件
if exist "%output_tif%" (
    echo [SKIP] Already exists / 已存在: %scene_name%
    exit /b 0
)

echo [PROC] Processing / 处理中: %scene_name%

REM Run GPT processing / 运行GPT处理
gpt "%GRAPH%" ^
    -Pinput="%input_zip%" ^
    -Poutput="%output_tif%" ^
    -Presolution="%RESOLUTION%" ^
    -Porigin="%ORIGIN%" ^
    -Pfilter="%FILTER%" ^
    -Pdem="%DEM%" ^
    -Pcrs="%CRS%" ^
    >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    echo [FAIL] Processing failed / 处理失败: %scene_name%
    exit /b 1
)

if exist "%output_tif%" (
    echo [OK] Success / 成功: %scene_name%
    exit /b 0
) else (
    echo [FAIL] Output file not created / 输出文件未创建: %scene_name%
    exit /b 1
)

:show_help
echo.
echo Sentinel-1 Batch Processing Script for Windows (v4.0)
echo Sentinel-1 Windows批处理脚本 (v4.0)
echo.
echo Usage / 用法: %~nx0 [options]
echo.
echo Options / 选项:
echo   -i, --input      Input directory / 输入目录 (default: %DEFAULT_INPUT_DIR%)
echo   -o, --output     Output directory / 输出目录 (default: %DEFAULT_OUTPUT_DIR%)
echo   -g, --graph      Graph file / Graph文件 (default: %DEFAULT_GRAPH%)
echo   -r, --resolution Resolution in meters / 分辨率(米) (default: %DEFAULT_RESOLUTION%)
echo   -a, --origin     Grid origin / 网格原点 (default: %DEFAULT_ORIGIN%)
echo   -f, --filter     Filter method / 滤波方法 (default: %DEFAULT_FILTER%)
echo   -d, --dem        DEM model / 高程模型 (default: %DEFAULT_DEM%)
echo   -c, --crs        Coordinate system / 坐标系 (default: %DEFAULT_CRS%)
echo   -b, --batch      Batch mode / 批处理模式
echo   -h, --help       Show this help / 显示帮助
echo.
echo Examples / 示例:
echo   %~nx0
echo   %~nx0 -i data -o output -r 20
echo   %~nx0 -i C:\s1_data -o C:\results -d "SRTM 3Sec"
echo.
exit /b 0
