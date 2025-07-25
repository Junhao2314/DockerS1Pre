#!/bin/bash

# 检查 gdal 是否已安装
if ! command -v gdalinfo &> /dev/null; then
    echo "GDAL 未安装，正在为您安装 GDAL..."
    sudo apt-get update
    sudo apt-get install -y gdal-bin python3-gdal
    if ! command -v gdalinfo &> /dev/null; then
        echo "GDAL 安装失败，请检查您的网络或软件源设置。"
        exit 1
    fi
    echo "GDAL 安装完成。"
else
    echo "GDAL 已安装。"
fi

# 输入文件夹和输出文件名
INPUT_DIR="/path/to/tif_folder"
OUTPUT_TIF="/output/mosaic.tif"
RESAMPLING="average"  # 可选: average, min, max, nearest, mode
RESOLUTION=40 # 重采样分辨率
TARGET_SRS="EPSG:4326"  # 目标坐标参考系统

# 生成 VRT 镶嵌虚拟文件，指定重采样方式和分辨率
gdalbuildvrt -tr $RESOLUTION $RESOLUTION -r $RESAMPLING -a_srs $TARGET_SRS mosaic.vrt "$INPUT_DIR"/*.tif

# 将 VRT 转为实际的 GeoTIFF，带压缩和分块
gdal_translate -of GTiff -co COMPRESS=LZW -co TILED=YES mosaic.vrt "$OUTPUT_TIF"

# 创建金字塔
gdaladdo -r $RESAMPLING --config COMPRESS_OVERVIEW LZW "$OUTPUT_TIF" 2 4 8 16

# 清理临时文件
rm mosaic.vrt

echo "Mosaic and pyramid creation complete. Output: $OUTPUT_TIF"