**中文** | [English](README_EN.md)

# Sentinel-1 数据预处理工具包

这是一个用于 Sentinel-1 SAR 数据自动化处理的工具包，提供完整的数据预处理流程，包括轨道校正、热噪声去除、辐射校正、地形校正等功能。

**支持 Linux 和 Windows 双平台运行。**

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

### Linux
- **操作系统**: Ubuntu 18.04+, CentOS 7+
- **内存**: 建议 8GB 以上
- **存储**: 根据数据量确定，建议预留充足空间
- **网络**: 需要互联网连接下载 SNAP 软件和轨道文件

### Windows
- **操作系统**: Windows 10/11
- **内存**: 建议 8GB 以上
- **存储**: 根据数据量确定，建议预留充足空间
- **软件**: SNAP 12.0+, GDAL (用于镶嵌功能)

## 快速开始

### Linux

#### 1. 一键运行（推荐新手）

```bash
# 克隆或下载项目
cd DockerS1Pre

# 添加执行权限
chmod +x process.sh mosaic.sh

# 直接运行默认监控模式
./process.sh
```

该命令会：
- 自动检测并安装 SNAP（如未安装）
- 监控 `./data` 目录中的新文件
- 将处理结果输出到 `./output` 目录

#### 2. 自定义参数运行

```bash
./process.sh -i /path/to/s1_data -o /path/to/output -r 40 -d "Copernicus 30m Global DEM"
```

#### 3. 批处理模式（处理完退出）

```bash
./process.sh -i ./data -o ./output --batch
```

### Windows

#### 方式一：使用 CMD 批处理脚本

```cmd
:: 使用默认参数运行
process.bat

:: 自定义参数
process.bat -i .\data -o .\output -r 40 -d "SRTM 3Sec"

:: 批处理模式
process.bat -i .\data -o .\output -b
```

#### 方式二：使用 PowerShell 脚本（推荐）

```powershell
# 使用默认参数运行
.\process.ps1

# 自定义参数
.\process.ps1 -InputDir .\data -OutputDir .\output -Resolution 40 -DEM "SRTM 3Sec"

# 查看帮助
Get-Help .\process.ps1 -Detailed
```

> **注意**: 首次运行 PowerShell 脚本可能需要设置执行策略：
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

## 安装指南

### Linux 安装

#### 方法一：自动安装（推荐）

运行处理脚本时会自动检测并安装所需软件：

```bash
./process.sh
```

脚本会自动安装：
- SNAP 12.0（ESA 官方 SAR 处理软件）
- GDAL（地理数据处理库）
- 其他必要依赖

#### 方法二：手动安装

##### 1. 安装 SNAP

详细安装步骤请参考 [SNAP 安装指南（中文）](SNAP安装.md)

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

##### 2. 安装 GDAL（用于镶嵌功能）

```bash
sudo apt-get update
sudo apt-get install -y gdal-bin python3-gdal
```

##### 3. 安装 Docker（可选）

如需容器化部署，请参考 [Docker 安装指南（中文）](Docker安装.md)

### Windows 安装

#### 1. 安装 SNAP

1. 下载 SNAP 安装包：https://step.esa.int/main/download/snap-download/
2. 运行安装程序，选择安装路径（如 `C:\Program Files\snap`）
3. 安装完成后，脚本会自动检测以下常见路径：
   - `C:\Program Files\snap\bin`
   - `%USERPROFILE%\AppData\Local\snap\bin`
   - `%USERPROFILE%\snap\bin`

4. 或手动添加到系统 PATH：
```cmd
setx PATH "%PATH%;C:\Program Files\snap\bin"
```

#### 2. 安装 GDAL（用于镶嵌功能）

**方式一：使用 OSGeo4W（推荐）**
1. 下载 OSGeo4W：https://trac.osgeo.org/osgeo4w/
2. 安装时选择 GDAL 组件
3. 脚本会自动检测 `C:\OSGeo4W64\bin`

**方式二：使用 Conda**
```cmd
conda install -c conda-forge gdal
```

**方式三：使用 QGIS**
- QGIS 安装包自带 GDAL，脚本会自动检测

## 使用说明

### 主要脚本功能

#### 1. 数据处理脚本

| 平台 | 脚本文件 | 说明 |
|------|----------|------|
| Linux | `process.sh` | Bash 脚本，支持监控模式和批处理模式 |
| Windows | `process.bat` | CMD 批处理脚本 |
| Windows | `process.ps1` | PowerShell 脚本（功能更强大，推荐） |

**Linux - process.sh**

```bash
# 默认监控模式（持续监控新文件）
./process.sh

# 批处理模式（处理完退出）
./process.sh --batch

# 自定义参数
./process.sh -i /data/s1 -o /results -r 20 -d "SRTM 3Sec" -c "EPSG:4326"
```

**Windows CMD - process.bat**

```cmd
:: 默认参数运行
process.bat

:: 批处理模式
process.bat -b

:: 自定义参数
process.bat -i .\data -o .\output -r 20 -d "SRTM 3Sec" -c "EPSG:4326"
```

**Windows PowerShell - process.ps1**

```powershell
# 默认参数运行
.\process.ps1

# 自定义参数
.\process.ps1 -InputDir .\data -OutputDir .\output -Resolution 20 -DEM "SRTM 3Sec" -CRS "EPSG:4326"
```

#### 2. 镶嵌脚本

| 平台 | 脚本文件 | 说明 |
|------|----------|------|
| Linux | `mosaic.sh` | Bash 镶嵌脚本 |
| Windows | `mosaic.bat` | CMD 镶嵌脚本 |
| Windows | `mosaic.ps1` | PowerShell 镶嵌脚本（推荐） |

**Linux - mosaic.sh**

```bash
# 编辑脚本中的路径参数
nano mosaic.sh

# 运行镶嵌
./mosaic.sh
```

**Windows CMD - mosaic.bat**

```cmd
:: 默认参数
mosaic.bat

:: 自定义参数
mosaic.bat -i .\output -o .\mosaic\result.tif -r 20
```

**Windows PowerShell - mosaic.ps1**

```powershell
# 默认参数
.\mosaic.ps1

# 自定义参数
.\mosaic.ps1 -InputDir .\output -OutputFile .\mosaic\result.tif -Resolution 20 -Resampling average
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
8. **分贝化** - 线性值转换为分贝值
9. **输出保存** - 保存为 GeoTIFF 格式

## 配置参数

### 命令行参数

#### Linux (process.sh) / Windows CMD (process.bat)

| 参数 | 说明 | 默认值 | 示例 |
|------|------|---------|------|
| `-i, --input` | 输入目录路径 | `./data` | `-i /path/to/s1_data` |
| `-o, --output` | 输出目录路径 | `./output` | `-o /path/to/results` |
| `-g, --graph` | Graph XML 文件 | `graph.xml` | `-g custom_graph.xml` |
| `-r, --resolution` | 输出分辨率（米） | `40` | `-r 20` |
| `-a, --origin` | 网格原点偏移 | `0.0` | `-a 5.0` |
| `-f, --filter` | 去斑滤波方法 | `Lee` | `-f "Refined Lee"` |
| `-d, --dem` | 数字高程模型 | `ACE30` | `-d "SRTM 3Sec"` |
| `-c, --crs` | 坐标参考系统 | `EPSG:3031` | `-c "EPSG:4326"` |
| `-b, --batch` | 批处理模式 | 监控模式 | `--batch` |
| `-h, --help` | 显示帮助信息 | - | `--help` |

#### Windows PowerShell (process.ps1)

| 参数 | 说明 | 默认值 |
|------|------|---------|
| `-InputDir` | 输入目录路径 | `.\data` |
| `-OutputDir` | 输出目录路径 | `.\output` |
| `-Graph` | Graph XML 文件 | `graph.xml` |
| `-Resolution` | 输出分辨率（米） | `40` |
| `-Origin` | 网格原点偏移 | `0.0` |
| `-Filter` | 去斑滤波方法 | `Lee` |
| `-DEM` | 数字高程模型 | `ACE30` |
| `-CRS` | 坐标参考系统 | `EPSG:3031` |

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

### 目录结构

```
DockerS1Pre/
├── process.sh          # Linux 主处理脚本
├── process.bat         # Windows CMD 处理脚本
├── process.ps1         # Windows PowerShell 处理脚本
├── mosaic.sh           # Linux 镶嵌脚本
├── mosaic.bat          # Windows CMD 镶嵌脚本
├── mosaic.ps1          # Windows PowerShell 镶嵌脚本
├── graph.xml           # SNAP 处理流程配置
├── download.ipynb      # 数据下载 Jupyter Notebook
├── data/               # 输入数据目录（默认）
├── output/             # 输出结果目录（默认）
├── logs/               # 日志文件目录
├── roi/                # ROI 矢量文件目录
├── Docker安装.md       # Docker 安装指南
├── SNAP安装.md         # SNAP 安装指南
├── README.md           # 中文用户指南
└── README_EN.md        # 英文用户指南
```

### 核心文件说明

| 文件 | 平台 | 说明 |
|------|------|------|
| `process.sh` | Linux | 主处理脚本，支持监控和批处理模式 |
| `process.bat` | Windows | CMD 批处理脚本 |
| `process.ps1` | Windows | PowerShell 脚本，功能更强大 |
| `mosaic.sh` | Linux | GeoTIFF 镶嵌脚本 |
| `mosaic.bat` | Windows | CMD 镶嵌脚本 |
| `mosaic.ps1` | Windows | PowerShell 镶嵌脚本 |
| `graph.xml` | 通用 | SNAP 处理流程定义文件 |
| `download.ipynb` | 通用 | Sentinel-1 数据下载工具 |

## 故障排除

### Linux 常见问题

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

**3. 换行符问题（从 Windows 复制的脚本）**
```bash
# 转换换行符
sed -i 's/\r$//' process.sh mosaic.sh
```

**4. 内存不足**
```bash
# 编辑SNAP配置，增加内存限制
nano $SNAP_HOME/bin/gpt.vmoptions
# 添加：-Xmx8g（8GB内存）
```

### Windows 常见问题

**1. SNAP 未找到**
```cmd
:: 检查 gpt 是否可用
where gpt

:: 如果未找到，手动添加到 PATH
setx PATH "%PATH%;C:\Program Files\snap\bin"
```

**2. PowerShell 执行策略限制**
```powershell
# 设置执行策略
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**3. GDAL 未找到**
```cmd
:: 检查 GDAL 是否可用
where gdalbuildvrt

:: 如果使用 OSGeo4W，添加到 PATH
setx PATH "%PATH%;C:\OSGeo4W64\bin"
```

**4. 中文路径问题**
- 建议将项目放在纯英文路径下
- 或确保系统区域设置支持 UTF-8

**5. 内存不足**
```
编辑 SNAP 配置文件：
C:\Program Files\snap\bin\gpt.vmoptions
添加：-Xmx8g（8GB内存）
```

### 日志分析

处理日志保存在 `logs/` 目录

**Linux**：
```bash
# 查看实时日志
tail -f logs/$(ls logs/ | tail -1)

# 搜索错误信息
grep -i "error\|exception\|failed" logs/*.log
```

**Windows PowerShell**：
```powershell
# 查看最新日志
Get-Content (Get-ChildItem logs\*.log | Sort-Object LastWriteTime -Descending | Select-Object -First 1) -Tail 50

# 搜索错误信息
Select-String -Path logs\*.log -Pattern "error|exception|failed" -CaseSensitive:$false
```

## 参考资源

### 官方文档

- [SNAP 官方文档](http://step.esa.int/main/doc/) - 完整的SNAP软件使用指南
- [Sentinel-1 用户指南](https://sentinel.esa.int/web/sentinel/user-guides/sentinel-1-sar) - ESA官方Sentinel-1数据说明
- [GDAL 文档](https://gdal.org/) - GDAL地理数据处理库文档

### 技术支持

- [SNAP 论坛](https://forum.step.esa.int/) - ESA官方技术支持论坛

### 数据下载

- [Copernicus Open Access Hub](https://scihub.copernicus.eu/) - 官方数据下载平台
- [Alaska Satellite Facility](https://search.asf.alaska.edu/) - ASF数据检索平台

---

**注意事项**：
- 单景数据处理大约需要 24 分钟
- 处理大量数据时请确保有足够的存储空间
- 首次运行会下载轨道文件和DEM数据，需要网络连接
- 建议在处理前备份重要数据
- Linux 脚本使用 Unix 换行符 (LF)，Windows 脚本使用 Windows 换行符 (CRLF)
- 生产环境建议使用批处理模式定期运行
