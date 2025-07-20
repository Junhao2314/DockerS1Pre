# Docker Sentinel-1 数据预处理

本项目提供了一个基于Docker的Sentinel-1卫星数据预处理流程。

## 项目概述

本项目通过Docker容器化技术，提供一个标准化、可重现的Sentinel-1数据预处理环境。

## 主要功能

- **数据下载**: 自动化下载Sentinel-1数据
- **数据预处理**: 包括辐射校正、几何校正、滤波等
- **格式转换**: 支持多种输出格式
- **批量处理**: 支持大量数据的自动化处理
- **可视化**: 生成处理结果的可视化图像


## 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/Junhao2314/DockerS1Pre.git
cd DockerS1Pre
```

### 2. 构建Docker镜像

```bash
docker build -t sentinel1-processor .
```

### 3. 运行容器

```bash
docker run -v /path/to/your/data:/data -v /path/to/output:/output sentinel1-processor
```

## 使用指南

### 数据准备

1. 将Sentinel-1数据文件放置在指定的输入目录
2. 确保数据格式为`.zip`或`.SAFE`格式
3. 检查数据完整性

### 配置参数

通过环境变量或配置文件设置处理参数：

```bash
docker run -e PROCESSING_LEVEL=GRD -e OUTPUT_FORMAT=GEOTIFF -v /data:/input -v /output:/output sentinel1-processor
```

### 支持的参数

- `PROCESSING_LEVEL`: 处理级别 (SLC, GRD, OCN)
- `OUTPUT_FORMAT`: 输出格式 (GEOTIFF, NETCDF, HDF5)
- `POLARIZATION`: 极化方式 (VV, VH, HH, HV)
- `RESOLUTION`: 输出分辨率 (10m, 20m, 40m)

## 输出结果

处理完成后，输出目录将包含：

- 预处理后的SAR图像
- 元数据文件
- 处理日志
- 可视化图像（如果启用）

## 目录结构

```
DockerS1Pre/
├── Dockerfile              # Docker构建文件
├── docker-compose.yml      # Docker Compose配置
├── scripts/                # 处理脚本
│   ├── preprocess.py       # 主处理脚本
│   ├── download.py         # 数据下载脚本
│   └── utils.py           # 工具函数
├── config/                 # 配置文件
│   └── processing.yaml     # 处理参数配置
├── requirements.txt        # Python依赖
├── data/                   # 示例数据目录
├── output/                 # 输出目录
└── README.md              # 本文件
```

## 环境变量配置

| 变量名 | 描述 | 默认值 |
|--------|------|--------|
| `INPUT_DIR` | 输入数据目录 | `/data/input` |
| `OUTPUT_DIR` | 输出数据目录 | `/data/output` |
| `TEMP_DIR` | 临时文件目录 | `/tmp` |
| `LOG_LEVEL` | 日志级别 | `INFO` |

## 故障排除

### 常见问题

1. **内存不足错误**
   - 增加Docker容器的内存限制
   - 减少并行处理的数据量

2. **权限问题**
   - 确保输入输出目录有正确的读写权限
   - 检查Docker用户权限设置

3. **数据格式错误**
   - 验证Sentinel-1数据的完整性
   - 检查数据是否已损坏



---

*注: 本项目仅用于研究和教育目的。使用Sentinel-1数据请遵守ESA的使用条款。*
