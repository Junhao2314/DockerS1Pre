#!/bin/bash
# Sentinel-1 Automated Batch Processing Script (Default Monitoring Mode)
# Sentinel-1 自动化批处理脚本（默认监控模式版）

# Default parameter configuration (can be overridden by command line arguments)
# 默认参数配置（可通过命令行参数覆盖）
DEFAULT_INPUT_DIR="./data"
DEFAULT_OUTPUT_DIR="./output"
DEFAULT_RESOLUTION=40
DEFAULT_ORIGIN=0.0
DEFAULT_FILTER="Lee"
# DEM options / DEM选项: 'Copernicus 30m Global DEM', 'SRTM 3Sec', 'SRTM 1Sec HGT', 'ACE30', 'GETASSE30'
DEFAULT_DEM="ACE30"   
DEFAULT_CRS="EPSG:3031"
DEFAULT_GRAPH="graph.xml"
LOG_FILE="$(date +%Y%m%d_%H:%M:%S).log"
TEMP_DIR="/tmp/snap_cache"

# Create necessary directories
# 创建必要目录
mkdir -p logs "$TEMP_DIR"

# SNAP installation function (using aria2c for accelerated download)
# SNAP安装函数（使用aria2c加速下载）
install_snap() {
    echo "⚠️ Starting SNAP 12.0 processing engine installation..."
    echo "⚠️ 开始安装SNAP 12.0处理引擎..." | tee -a "$LOG_FILE"
    
    # Set installation path
    # 设置安装路径
    local SNAP_DIR="/root/snap"
    
    # Skip if already installed
    # 如果已经安装则跳过
    if [[ -f "$SNAP_DIR/bin/gpt" ]]; then
        echo "ℹ️ SNAP installation detected: $SNAP_DIR"
        echo "ℹ️ 检测到已安装SNAP: $SNAP_DIR" | tee -a "$LOG_FILE"
        configure_snap
        return 0
    fi
    
    # Install aria2c if not already installed
    # 安装必备工具aria2c（如果尚未安装）
    if ! command -v aria2c &> /dev/null; then
        echo "  • Installing aria2 download tool..."
        echo "  • 安装aria2下载工具..." | tee -a "$LOG_FILE"
        sudo apt-get update
        sudo apt-get install -y aria2
    fi
    
    # Create temporary installation directory in current working directory (safer and no special permissions needed)
    # 在当前工作目录下创建临时安装目录 (更加安全且不需要特殊权限)
    local INSTALLER_DIR="./installer_temp"
    mkdir -p "$INSTALLER_DIR"
    cd "$INSTALLER_DIR" || { echo "❌ Cannot enter temporary directory: $INSTALLER_DIR" | tee -a "$LOG_FILE"; return 1; }
    
    echo "📂 Created temporary installation directory: $(pwd)"
    echo "📂 创建临时安装目录: $(pwd)" | tee -a "$LOG_FILE"
    echo "⬇️ Downloading SNAP 12.0 installer (using aria2c multi-threaded accelerated download)..."
    echo "⬇️ 下载SNAP 12.0安装包 (使用aria2c多线程加速下载)..." | tee -a "$LOG_FILE"
    local INSTALLER_URL="https://download.esa.int/step/snap/12.0/installers/esa-snap_all_linux-12.0.0.sh"
    local INSTALLER_FILE="esa-snap_all_linux-12.0.0.sh"
    
    # Download using aria2c (multi-threaded acceleration)
    # 使用aria2c下载（多线程加速）
    aria2c -x 16 -s 16 "$INSTALLER_URL" -o "$INSTALLER_FILE" | tee -a "$LOG_FILE"
    
    # Check if download was successful
    # 检查下载是否成功
    if [[ ! -f "$INSTALLER_FILE" ]]; then
        echo "❌ Download failed: Cannot find installation file"
        echo "❌ 下载失败：无法找到安装文件" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Add execute permission
    # 添加执行权限
    chmod +x "$INSTALLER_FILE"
    
    echo "🛠️ Silent installation to $SNAP_DIR..."
    echo "🛠️ 静默安装到$SNAP_DIR..." | tee -a "$LOG_FILE"
    "./$INSTALLER_FILE" -q -dir "$SNAP_DIR" | tee -a "$LOG_FILE"
    
    # Check installation result
    # 检查安装结果
    if [[ $? -eq 0 ]] && [[ -f "$SNAP_DIR/bin/gpt" ]]; then
        echo "✅ SNAP installation successful to $SNAP_DIR"
        echo "✅ SNAP安装成功到$SNAP_DIR" | tee -a "$LOG_FILE"
        # Return to original working directory
        # 返回原工作目录
        cd ..
        configure_snap
        return 0
    else
        echo "❌ SNAP installation failed"
        echo "❌ SNAP安装失败" | tee -a "$LOG_FILE"
        cd ..
        return 1
    fi
}

# Configure SNAP environment
# 配置SNAP环境
configure_snap() {
    local SNAP_DIR="/root/snap"
    
    # Set environment variables
    # 设置环境变量
    export SNAP_HOME="$SNAP_DIR"
    export PATH="$SNAP_HOME/bin:$PATH"
    
    # Permanent configuration
    # 永久生效配置
    echo "export SNAP_HOME=$SNAP_DIR" >> ~/.bashrc
    echo 'export PATH=$SNAP_HOME/bin:$PATH' >> ~/.bashrc
    
    # Verify gpt availability
    # 验证gpt可用性
    if gpt -h &>/dev/null; then
        echo "✅ SNAP configuration successful: $(gpt -h | head -n 1)"
        echo "✅ SNAP配置成功: $(gpt -h | head -n 1)" | tee -a "$LOG_FILE"
        return 0
    else
        echo "❌ SNAP configuration failed"
        echo "❌ SNAP配置失败" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Environment check function
# 环境检查函数
check_environment() {
    # First check SNAP configuration
    # 先检查SNAP配置
    if ! gpt -h &>/dev/null; then
        echo "⚠️ No valid gpt command detected, attempting to install/configure SNAP..."
        echo "⚠️ 未检测到有效的gpt命令，尝试安装/配置SNAP..." | tee -a "$LOG_FILE"
        if ! install_snap; then
            echo "❌ SNAP must be installed for data processing"
            echo "❌ 必须安装SNAP才能进行数据处理" | tee -a "$LOG_FILE"
            return 1
        fi
    fi
    
    # Check curl
    # 检查curl
    if ! command -v curl &> /dev/null; then
        echo "  • Installing curl tool..."
        echo "  • 安装curl工具..." | tee -a "$LOG_FILE"
        sudo apt-get update
        sudo apt-get install -y curl
    fi
    
    # Check inotify-tools (required for monitoring mode)
    # 检查inotify-tools（监控模式需要）
    if ! command -v inotifywait &> /dev/null; then
        echo "  • Installing inotify-tools..."
        echo "  • 安装inotify-tools..." | tee -a "$LOG_FILE"
        sudo apt-get update
        sudo apt-get install -y inotify-tools
    fi
    
    return 0
}

# Process single file (core function)
# 处理单文件（核心功能）
process_file() {
    local input_zip="$1"
    local scene_name=$(basename "$input_zip" .zip)
    local output_tif="${OUTPUT_DIR}/${scene_name}.tif"
    
    # Skip already processed files
    # 跳过已处理文件
    if [[ -f "$output_tif" ]]; then
        echo "⏩ Skipping: ${scene_name} (already exists)"
        echo "⏩ 跳过: ${scene_name} (已存在)" | tee -a "$LOG_FILE"
        return 0
    fi
    
    # Start processing
    # 开始处理
    local start_time=$(date +%s)
    echo "🚀 Processing: ${scene_name}"
    echo "🚀 处理: ${scene_name}" | tee -a "$LOG_FILE"
    
    # GPT processing command (key parameters directly replaced)
    # GPT处理命令（关键参数直接替换）
    gpt "$GRAPH" \
        -Pinput="${input_zip}" \
        -Poutput="${output_tif}" \
        -Presolution="${RESOLUTION}" \
        -Porigin="${ORIGIN}" \
        -Pfilter="${FILTER}" \
        -Pdem="${DEM}" \
        -Pcrs="${CRS}" \
        2>&1 | tee -a "$LOG_FILE"
    
    # Check result
    # 检查结果
    if [[ $? -eq 0 ]] && [[ -f "$output_tif" ]]; then
        local duration=$(( $(date +%s) - start_time ))
        local file_size=$(du -sh "$output_tif" | cut -f1)
        echo "✅ Success: ${file_size} | ${duration}s"
        echo "✅ 成功: ${file_size} | ${duration}秒" | tee -a "$LOG_FILE"
        return 0
    else
        local last_error=$(grep -i "error\|exception" "$LOG_FILE" | tail -n 1)
        echo "❌ Failed: ${last_error}"
        echo "❌ 失败: ${last_error}" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Batch process all files
# 批处理所有文件
batch_process() {
    local count=0
    local processed=0
    
    echo "🔍 Scanning: $INPUT_DIR"
    echo "🔍 扫描: $INPUT_DIR" | tee -a "$LOG_FILE"
    shopt -s nullglob
    
    # Find all ZIP files
    # 查找所有ZIP文件
    for zip_file in "$INPUT_DIR"/*.zip; do
        ((count++))
        
        echo "--------------------------------------------------" | tee -a "$LOG_FILE"
        echo "📂 File $count: $(basename "$zip_file")"
        echo "📂 文件 $count: $(basename "$zip_file")" | tee -a "$LOG_FILE"
        
        # Skip non-Sentinel-1 files
        # 跳过非Sentinel-1文件
        if ! [[ "$(basename "$zip_file")" =~ S1.* ]]; then
            echo "⏭️ Skipping: Not a Sentinel-1 file"
            echo "⏭️ 跳过: 非Sentinel-1文件" | tee -a "$LOG_FILE"
            continue
        fi
        
        if process_file "$zip_file"; then
            ((processed++))
        fi
    done
    
    # Result summary (output to both console and log)
    # 结果摘要（同时输出到控制台和日志）
    {
        echo "=================================================="
        echo "📊 Processing complete | Total: $count | Success: $processed"
        echo "📊 处理完成 | 总计: $count | 成功: $processed"
        echo "⌚ Total time: $(( $(date +%s) - START_TIME ))s"
        echo "⌚ 总时间: $(( $(date +%s) - START_TIME ))秒"
        echo "💾 Output directory: $OUTPUT_DIR"
        echo "💾 输出目录: $OUTPUT_DIR"
        echo "📋 Log file: $LOG_FILE"
        echo "📋 日志文件: $LOG_FILE"
    } | tee -a "$LOG_FILE"
}

# Monitoring mode (real-time processing of new files)
# 监控模式（实时处理新文件）
start_monitoring() {
    echo "🔭 Entering monitoring mode (press Ctrl+C to stop)"
    echo "🔭 进入监控模式 (按Ctrl+C停止)" | tee -a "$LOG_FILE"
    echo "📁 Monitoring directory: $INPUT_DIR"
    echo "📁 监控目录: $INPUT_DIR" | tee -a "$LOG_FILE"
    echo "📤 Output directory: $OUTPUT_DIR"
    echo "📤 输出目录: $OUTPUT_DIR" | tee -a "$LOG_FILE"
    
    # Initial batch processing (process existing files)
    # 初始批处理（处理已存在文件）
    batch_process
    
    echo "🔍 Starting real-time monitoring for new files..."
    echo "🔍 开始实时监控新文件..." | tee -a "$LOG_FILE"
    
    # Real-time monitoring for new files
    # 实时监控新文件
    while true; do
        inotifywait -q -e create,moved_to -r "$INPUT_DIR" |
        while read -r path action file; do
            if [[ "$file" =~ \.zip$ ]]; then
                echo "🆕 New file detected: $file"
                echo "🆕 检测到新文件: $file" | tee -a "$LOG_FILE"
                process_file "${path}${file}"
                
                # Add separator after file processing
                # 文件处理完成后添加分隔线
                echo "--------------------------------------------------" | tee -a "$LOG_FILE"
            fi
        done
    done
}

# Display help information
# 显示帮助信息
show_help() {
    echo "Sentinel-1 Batch Processing Script (v4.0 - Default Monitoring Mode)"
    echo "Sentinel-1 批处理脚本 (v4.0 - 默认监控模式)"
    echo "Usage / 用法: $0 [-i input_dir] [-o output_dir] [-g graph.xml] [other_params]"
    echo ""
    echo "Note: Default behavior is monitoring mode (continuously process new files)"
    echo "注意: 默认行为是监控模式（持续处理新文件）"
    echo ""
    echo "Parameters / 参数:"
    echo "  -i, --input      Input directory / 输入目录 (default / 默认: $DEFAULT_INPUT_DIR)"
    echo "  -o, --output     Output directory / 输出目录 (default / 默认: $DEFAULT_OUTPUT_DIR)"
    echo "  -g, --graph      Graph file / Graph文件 (default / 默认: $DEFAULT_GRAPH)"
    echo "  -r, --resolution Resolution (meters) / 分辨率(米) (default / 默认: $DEFAULT_RESOLUTION)"
    echo "  -a, --origin     Grid origin / 网格原点 (default / 默认: $DEFAULT_ORIGIN)"
    echo "  -f, --filter     Filter method / 滤波方法 (default / 默认: $DEFAULT_FILTER)"
    echo "  -d, --dem        DEM model / 高程模型 (default / 默认: $DEFAULT_DEM)"
    echo "  -c, --crs        Coordinate system / 坐标系 (default / 默认: $DEFAULT_CRS)"
    echo "  -b, --batch      Batch mode (exit after processing existing files) / 批处理模式 (处理现有文件后退出)"
    echo "  -h, --help       Show help / 显示帮助"
    echo ""
    echo "Examples / 示例:"
    echo "  # Default monitoring mode (using default parameters)"
    echo "  # 默认监控模式（使用默认参数）"
    echo "  $0"
    echo ""
    echo "  # Monitoring mode with custom parameters"
    echo "  # 自定义参数的监控模式"
    echo "  $0 -i s1_data -o results -r 50 -d \"Copernicus 30m DEM\""
    echo ""
    echo "  # Single batch processing mode"
    echo "  # 单次批处理模式"
    echo "  $0 -i s1_data -o output --batch"
    exit 0
}

# Parse command line arguments
# 解析命令行参数
parse_arguments() {
    # Set default values
    # 设置默认值
    INPUT_DIR="$DEFAULT_INPUT_DIR"
    OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"
    GRAPH="$DEFAULT_GRAPH"
    RESOLUTION="$DEFAULT_RESOLUTION"
    ORIGIN="$DEFAULT_ORIGIN"
    FILTER="$DEFAULT_FILTER"
    DEM="$DEFAULT_DEM"
    CRS="$DEFAULT_CRS"
    BATCH_MODE=false
    
    # Parameter parsing
    # 参数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--input)
                INPUT_DIR="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -g|--graph)
                GRAPH="$2"
                shift 2
                ;;
            -r|--resolution)
                RESOLUTION="$2"
                shift 2
                ;;
            -a|--origin)
                ORIGIN="$2"
                shift 2
                ;;
            -f|--filter)
                FILTER="$2"
                shift 2
                ;;
            -d|--dem)
                DEM="$2"
                shift 2
                ;;
            -c|--crs)
                CRS="$2"
                shift 2
                ;;
            -b|--batch)
                BATCH_MODE=true
                shift
                ;;
            -h|--help)
                show_help
                ;;
            *)
                echo "❌ Unknown parameter: $1"
                echo "❌ 未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Apply parameters (output to both console and log)
    # 应用参数（同时输出到控制台和日志）
    {
        echo "⚙️ Using parameters / 使用参数:"
        echo "  - Input directory / 输入目录: $INPUT_DIR"
        echo "  - Output directory / 输出目录: $OUTPUT_DIR"
        echo "  - Graph file / Graph文件: $GRAPH"
        echo "  - Resolution / 分辨率: ${RESOLUTION}m / 米"
        echo "  - DEM: $DEM"
        echo "  - Coordinate system / 坐标系: $CRS"
        echo "  - Mode / 模式: $([ "$BATCH_MODE" = true ] && echo "Batch / 批处理" || echo "Monitoring / 监控")"
    } | tee -a "$LOG_FILE"
}

# Main function
# 主函数
main() {
    START_TIME=$(date +%s)
    
    # Parse arguments
    # 解析参数
    parse_arguments "$@"
    
    # Verify environment
    # 验证环境
    if ! check_environment; then
        echo "❌ Environment check failed, cannot continue"
        echo "❌ 环境检查失败，无法继续" | tee -a "$LOG_FILE"
        exit 1
    fi
    
    # Verify input
    # 验证输入
    if [[ ! -d "$INPUT_DIR" ]]; then
        echo "❌ Input directory does not exist: $INPUT_DIR"
        echo "❌ 输入目录不存在: $INPUT_DIR" | tee -a "$LOG_FILE"
        exit 1
    fi
    
    if [[ ! -f "$GRAPH" ]]; then
        echo "❌ Graph file does not exist: $GRAPH"
        echo "❌ Graph文件不存在: $GRAPH" | tee -a "$LOG_FILE"
        exit 1
    fi
    
    # Prepare output directory
    # 准备输出目录
    mkdir -p "$OUTPUT_DIR"
    
    # Display startup information
    # 显示启动信息
    echo "🟢 Starting Sentinel-1 data processing"
    echo "🟢 开始 Sentinel-1 数据处理" | tee -a "$LOG_FILE"
    echo "🕒 Start time / 开始时间: $(date)" | tee -a "$LOG_FILE"
    echo "📂 Working directory / 工作目录: $(pwd)" | tee -a "$LOG_FILE"
    
    # Execute processing
    # 执行处理
    if $BATCH_MODE; then
        batch_process
        echo "🛑 Batch processing complete, program exiting"
        echo "🛑 批处理完成，程序退出" | tee -a "$LOG_FILE"
    else
        start_monitoring
    fi
}

# Start main program
# 启动主程序
main "$@"
