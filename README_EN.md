[English](README_EN.md) | [中文](README.md)

# Sentinel-1 Data Preprocessing Toolkit

A toolkit for automated Sentinel-1 SAR data processing, providing a complete preprocessing workflow including orbit correction, thermal noise removal, radiometric calibration, terrain correction, and more.

## Table of Contents

- [System Requirements](#system-requirements)
- [Quick Start](#quick-start)
- [Installation Guide](#installation-guide)
- [Usage](#usage)
- [Configuration Parameters](#configuration-parameters)
- [File Description](#file-description)
- [Troubleshooting](#troubleshooting)
- [References](#references)

## System Requirements

- **Operating System**: Linux (Ubuntu 18.04+, CentOS 7+)
- **Memory**: 8GB or more recommended
- **Storage**: Depends on data volume, ensure sufficient space
- **Network**: Internet connection required for downloading SNAP software and orbit files

## Quick Start

### 1. One-Click Run (Recommended for Beginners)

```bash
# Clone or download the project
cd DockerS1Pre

# Run default monitoring mode
./process.sh
```

This command will:
- Automatically detect and install SNAP (if not installed)
- Monitor the `./data` directory for new files
- Output processed results to `./output` directory

### 2. Run with Custom Parameters

```bash
# Specify input/output directories and parameters
./process.sh -i /path/to/s1_data -o /path/to/output -r 40 -d "Copernicus 30m Global DEM"
```

### 3. Batch Mode (Exit After Processing)

```bash
# Process existing files and exit without monitoring
./process.sh -i ./data -o ./output --batch
```

## Installation Guide

### Method 1: Automatic Installation (Recommended)

The processing script will automatically detect and install required software:

```bash
./process.sh
```

The script will automatically install:
- SNAP 12.0 (ESA official SAR processing software)
- GDAL (Geospatial data processing library)
- Other necessary dependencies

### Method 2: Manual Installation

#### 1. Install SNAP

For detailed installation steps, refer to [SNAP安装.md](SNAP安装.md)

**Quick Installation:**
```bash
# Download installer
aria2c -x 16 -s 16 https://download.esa.int/step/snap/12.0/installers/esa-snap_all_linux-12.0.0.sh

# Silent installation
chmod +x esa-snap_all_linux-12.0.0.sh
./esa-snap_all_linux-12.0.0.sh -q -dir /root/snap

# Configure environment variables
export SNAP_HOME=/root/snap
export PATH=$SNAP_HOME/bin:$PATH
echo 'export SNAP_HOME=/root/snap' >> ~/.bashrc
echo 'export PATH=$SNAP_HOME/bin:$PATH' >> ~/.bashrc
```

#### 2. Install GDAL (for mosaic functionality)

```bash
sudo apt-get update
sudo apt-get install -y gdal-bin python3-gdal
```

#### 3. Install Docker (Optional)

For containerized deployment, refer to [Docker安装.md](Docker安装.md)

## Usage

### Main Script Functions

#### 1. process.sh - Main Processing Script

**Default Monitoring Mode** (Recommended):
```bash
./process.sh
```
- Continuously monitors input directory
- Automatically processes new Sentinel-1 data
- Suitable for long-term production environment

**Batch Mode**:
```bash
./process.sh --batch
```
- Exits after processing existing files
- Suitable for one-time data processing

**Custom Parameters**:
```bash
./process.sh -i /data/s1 -o /results -r 20 -d "SRTM 3Sec" -c "EPSG:4326"
```


#### 2. mosaic.sh - Mosaic Script

Used to merge multiple processed GeoTIFF files into a single mosaic:

```bash
# Edit path parameters in the script
nano mosaic.sh

# Run mosaic
chmod +x mosaic.sh
./mosaic.sh
```

### Processing Workflow

The script uses SNAP's Graph Processing Tool (GPT) to execute the following processing steps:

1. **Data Reading** - Read Sentinel-1 GRD products
2. **Orbit Correction** - Apply precise orbit files
3. **Thermal Noise Removal** - Remove sensor thermal noise
4. **Border Noise Removal** - Remove image edge noise
5. **Radiometric Calibration** - Convert to backscatter coefficient
6. **Speckle Filtering** - Reduce speckle noise (optional)
7. **Terrain Correction** - Range-Doppler terrain correction
8. **Projection Conversion** - Project to specified coordinate system
9. **Output Saving** - Save as GeoTIFF format

## Configuration Parameters

### Command Line Parameters

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| `-i, --input` | Input directory path | `./data` | `-i /path/to/s1_data` |
| `-o, --output` | Output directory path | `./output` | `-o /path/to/results` |
| `-g, --graph` | Graph XML file | `graph.xml` | `-g custom_graph.xml` |
| `-r, --resolution` | Output resolution (meters) | `40` | `-r 20` |
| `-a, --origin` | Grid origin offset | `0.0` | `-a 5.0` |
| `-f, --filter` | Speckle filter method | `Lee` | `-f Refined Lee` |
| `-d, --dem` | Digital Elevation Model | `ACE30` | `-d "SRTM 3Sec"` |
| `-c, --crs` | Coordinate Reference System | `EPSG:3031` | `-c "EPSG:4326"` |
| `-b, --batch` | Batch mode | Monitor mode | `--batch` |
| `-h, --help` | Show help information | - | `--help` |

### DEM Options

- `Copernicus 30m Global DEM` - 30m Global DEM (Recommended)
- `SRTM 3Sec` - SRTM 90m DEM
- `SRTM 1Sec HGT` - SRTM 30m DEM
- `ACE30` - 30 arc-second DEM (Default)
- `GETASSE30` - GETASSE 30 arc-second DEM

### Filter Options

- `Lee` - Lee filter (Default)
- `Refined Lee` - Refined Lee filter
- `Frost` - Frost filter
- `Gamma Map` - Gamma Map filter
- `None` - No filtering

## File Description

### Core Files

- **process.sh** - Main processing script, supports monitoring and batch modes
- **mosaic.sh** - GeoTIFF mosaic script
- **graph.xml** - SNAP processing workflow definition file

### Installation Guides

- **Docker安装.md** - Docker container platform installation guide
- **SNAP安装.md** - SNAP software installation guide

### Configuration Files

- **graph.xml** - Defines complete Sentinel-1 preprocessing workflow

### Directory Structure

```
DockerS1Pre/
├── process.sh          # Main processing script
├── mosaic.sh           # Mosaic script
├── graph.xml           # Processing workflow configuration
├── data/               # Input data directory (default)
├── output/             # Output results directory (default)
├── logs/               # Log files directory
├── Docker安装.md       # Docker installation guide
├── SNAP安装.md         # SNAP installation guide
└── README.md           # User guide
```

## Troubleshooting

### Common Issues

**1. SNAP not installed or gpt command not found**
```bash
# Check if SNAP is installed
which gpt

# If not found, run installation
./process.sh  # Will install automatically
```

**2. Permission errors**
```bash
# Add execute permission to scripts
chmod +x process.sh mosaic.sh
```

**3. Insufficient memory**
```bash
# Edit SNAP configuration to increase memory limit
nano $SNAP_HOME/bin/gpt.vmoptions
# Add: -Xmx8g (8GB memory)
```

**4. Network connection issues**
```bash
# Check network connection
ping download.esa.int

# Use proxy (if needed)
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port
```

**5. Processing failure**
```bash
# View detailed logs
tail -f logs/$(ls logs/ | tail -1)

# Check input data format
ls data/*.zip
```

### Log Analysis

Processing logs are saved in the `logs/` directory with filename format `YYYYMMDD_HH:MM:SS.log`

**View real-time logs**:
```bash
tail -f logs/$(ls logs/ | tail -1)
```

**Search for error messages**:
```bash
grep -i "error\|exception\|failed" logs/*.log
```

## References

### Official Documentation

- [SNAP Official Documentation](http://step.esa.int/main/doc/) - Complete SNAP software user guide
- [Sentinel-1 User Guide](https://sentinel.esa.int/web/sentinel/user-guides/sentinel-1-sar) - ESA official Sentinel-1 data documentation
- [GDAL Documentation](https://gdal.org/) - GDAL geospatial data processing library documentation

### Technical Support

- [SNAP Forum](https://forum.step.esa.int/) - ESA official technical support forum
- [GitHub Issues](https://github.com/nasa/delta) - Related open source projects

### Data Download

- [Copernicus Open Access Hub](https://scihub.copernicus.eu/) - Official data download platform
- [Alaska Satellite Facility](https://search.asf.alaska.edu/) - ASF data search platform

---

**Notes**:
- Ensure sufficient storage space when processing large amounts of data
- First run will download orbit files and DEM data, requiring network connection
- Backup important data before processing
- Batch mode is recommended for production environments
