# Sentinel-1 数据预处理工具包

这是一个用于 Sentinel-1 SAR 数据自动化处理的工具包，提供完整的数据预处理流程，包括轨道校正、热噪声去除、辐射校正、地形校正等功能。

## 目录

- [系统要求](#系统要求)
- [快速开始](#快速开始)
- [安装指南](#安装指南)
- [使用说明](#使用说明)
- [配置参数](#配置参数)
- [文件说明](#文件说明)
- [故障排除](#故障排除)
- [参考资源](#参考资源)

## 系统要求

- **操作系统**: Linux (Ubuntu 18.04+, CentOS 7+)
- **内存**: 建议 8GB 以上
- **存储**: 根据数据量确定，建议预留充足空间
- **网络**: 需要互联网连接下载 SNAP 软件和轨道文件

## 快速开始

### 1. 一键运行（推荐新手）

```bash
# 克隆或下载项目
cd DockerS1Pre

# 直接运行默认监控模式
./process.sh
```

该命令会：
- 自动检测并安装 SNAP（如未安装）
- 监控 `./data` 目录中的新文件
- 将处理结果输出到 `./output` 目录

### 2. 自定义参数运行

```bash
# 指定输入输出目录和参数
./process.sh -i /path/to/s1_data -o /path/to/output -r 40 -d "Copernicus 30m Global DEM"
```

### 3. 批处理模式（处理完退出）

```bash
# 处理现有文件后退出，不监控新文件
./process.sh -i ./data -o ./output --batch
```

## 安装指南

### 方法一：自动安装（推荐）

运行处理脚本时会自动检测并安装所需软件：

```bash
./process.sh
```

脚本会自动安装：
- SNAP 12.0（ESA 官方 SAR 处理软件）
- GDAL（地理数据处理库）
- 其他必要依赖

### 方法二：手动安装

#### 1. 安装 SNAP

详细安装步骤请参考 [SNAP安装.md](SNAP安装.md)

**快速安装：**
```bash
# 下载安装包
aria2c -x 16 -s 16 https://download.esa.int/step/snap/12.0/installers/esa-snap_all_linux-12.0.0.sh

# 静默安装
chmod +x esa-snap_all_linux-12.0.0.sh
./esa-snap_all_linux-12.0.0.sh -q -dir /root/snap

# 配置环境变量
export SNAP_HOME=/root/snap
export PATH=$SNAP_HOME/bin:$PATH
echo 'export SNAP_HOME=/root/snap' >> ~/.bashrc
echo 'export PATH=$SNAP_HOME/bin:$PATH' >> ~/.bashrc
```

#### 2. 安装 GDAL（用于镶嵌功能）

```bash
sudo apt-get update
sudo apt-get install -y gdal-bin python3-gdal
```

#### 3. 安装 Docker（可选）

如需容器化部署，请参考 [Docker安装.md](Docker安装.md)

## 使用说明

### 主要脚本功能

#### 1. process.sh - 主处理脚本

**默认监控模式**（推荐）：
```bash
./process.sh
```
- 持续监控输入目录
- 自动处理新的 Sentinel-1 数据
- 适合生产环境长期运行

**批处理模式**：
```bash
./process.sh --batch
```
- 处理现有文件后退出
- 适合一次性数据处理

**自定义参数**：
```bash
./process.sh -i /data/s1 -o /results -r 20 -d "SRTM 3Sec" -c "EPSG:4326"
```

#### 2. mosaic.sh - 镶嵌脚本

用于将多个处理后的 GeoTIFF 文件拼接成一个大的镶嵌图：

```bash
# 编辑脚本中的路径参数
nano mosaic.sh

# 运行镶嵌
chmod +x mosaic.sh
./mosaic.sh
```

### 处理流程说明

脚本使用 SNAP 的 Graph Processing Tool (GPT) 执行以下处理步骤：

1. **数据读取** - 读取 Sentinel-1 GRD 产品
2. **轨道校正** - 应用精确轨道文件
3. **热噪声去除** - 去除传感器热噪声
4. **黑边去除** - 去除图像边缘噪声
5. **辐射校正** - 转换为后向散射系数
6. **去斑滤波** - 降低相干斑噪声（可选）
7. **地形校正** - Range-Doppler 地形校正
8. **投影转换** - 投影到指定坐标系
9. **输出保存** - 保存为 GeoTIFF 格式

## 配置参数

### 命令行参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|---------|------|
| `-i, --input` | 输入目录路径 | `./data` | `-i /path/to/s1_data` |
| `-o, --output` | 输出目录路径 | `./output` | `-o /path/to/results` |
| `-g, --graph` | Graph XML 文件 | `graph.xml` | `-g custom_graph.xml` |
| `-r, --resolution` | 输出分辨率（米） | `40` | `-r 20` |
| `-a, --origin` | 网格原点偏移 | `0.0` | `-a 5.0` |
| `-f, --filter` | 去斑滤波方法 | `Lee` | `-f Refined Lee` |
| `-d, --dem` | 数字高程模型 | `ACE30` | `-d "SRTM 3Sec"` |
| `-c, --crs` | 坐标参考系统 | `EPSG:3031` | `-c "EPSG:4326"` |
| `-b, --batch` | 批处理模式 | 监控模式 | `--batch` |
| `-h, --help` | 显示帮助信息 | - | `--help` |

### DEM 选项

- `Copernicus 30m Global DEM` - 30米全球DEM（推荐）
- `SRTM 3Sec` - SRTM 90米DEM
- `SRTM 1Sec HGT` - SRTM 30米DEM
- `ACE30` - 30弧秒DEM（默认）
- `GETASSE30` - GETASSE 30弧秒DEM

### 滤波选项

- `Lee` - Lee滤波（默认）
- `Refined Lee` - 精化Lee滤波
- `Frost` - Frost滤波
- `Gamma Map` - Gamma Map滤波
- `None` - 不使用滤波

## 文件说明

### 核心文件

- **process.sh** - 主处理脚本，支持监控和批处理模式
- **mosaic.sh** - GeoTIFF镶嵌脚本
- **graph.xml** - SNAP处理流程定义文件

### 安装指南

- **Docker安装.md** - Docker 容器平台安装指南
- **SNAP安装.md** - SNAP 软件安装指南

### 配置文件

- **graph.xml** - 定义完整的 Sentinel-1 预处理流程

### 目录结构

```
DockerS1Pre/
├── process.sh          # 主处理脚本
├── mosaic.sh           # 镶嵌脚本
├── graph.xml           # 处理流程配置
├── data/               # 输入数据目录（默认）
├── output/             # 输出结果目录（默认）
├── logs/               # 日志文件目录
├── Docker安装.md       # Docker安装指南
├── SNAP安装.md         # SNAP安装指南
└── README.md           # 本用户指南
```

## 故障排除

### 常见问题

**1. SNAP 未安装或无法找到 gpt 命令**
```bash
# 检查SNAP是否安装
which gpt

# 如果未找到，运行安装
./process.sh  # 会自动安装
```

**2. 权限错误**
```bash
# 给脚本添加执行权限
chmod +x process.sh mosaic.sh
```

**3. 内存不足**
```bash
# 编辑SNAP配置，增加内存限制
nano $SNAP_HOME/bin/gpt.vmoptions
# 添加：-Xmx8g（8GB内存）
```

**4. 网络连接问题**
```bash
# 检查网络连接
ping download.esa.int

# 使用代理（如需要）
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port
```

**5. 处理失败**
```bash
# 查看详细日志
tail -f logs/$(ls logs/ | tail -1)

# 检查输入数据格式
ls data/*.zip
```

### 日志分析

处理日志保存在 `logs/` 目录，文件名格式为 `YYYYMMDD_HH:MM:SS.log`

**查看实时日志**：
```bash
tail -f logs/$(ls logs/ | tail -1)
```

**搜索错误信息**：
```bash
grep -i "error\|exception\|failed" logs/*.log
```

## 参考资源

### 官方文档

- [SNAP 官方文档](http://step.esa.int/main/doc/) - 完整的SNAP软件使用指南
- [Sentinel-1 用户指南](https://sentinel.esa.int/web/sentinel/user-guides/sentinel-1-sar) - ESA官方Sentinel-1数据说明
- [GDAL 文档](https://gdal.org/) - GDAL地理数据处理库文档

### 技术支持

- [SNAP 论坛](https://forum.step.esa.int/) - ESA官方技术支持论坛
- [GitHub Issues](https://github.com/nasa/delta) - 相关开源项目

### 数据下载

- [Copernicus Open Access Hub](https://scihub.copernicus.eu/) - 官方数据下载平台
- [Alaska Satellite Facility](https://search.asf.alaska.edu/) - ASF数据检索平台

---

**注意事项**：
- 处理大量数据时请确保有足够的存储空间
- 首次运行会下载轨道文件和DEM数据，需要网络连接
- 建议在处理前备份重要数据
- 生产环境建议使用批处理模式定期运行