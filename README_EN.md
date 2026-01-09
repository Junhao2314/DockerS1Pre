**English** | [中文](README.md)

# Sentinel-1 Data Preprocessing Toolkit

A toolkit for automated Sentinel-1 SAR data processing, providing a complete preprocessing workflow including orbit correction, thermal noise removal, radiometric calibration, terrain correction, and more.

**Supports both Linux and Windows platforms.**

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

### Linux
- **Operating System**: Ubuntu 18.04+, CentOS 7+
- **Memory**: 8GB or more recommended
- **Storage**: Depends on data volume, ensure sufficient space
- **Network**: Internet connection required for downloading SNAP software and orbit files

### Windows
- **Operating System**: Windows 10/11
- **Memory**: 8GB or more recommended
- **Storage**: Depends on data volume, ensure sufficient space
- **Software**: SNAP 12.0+, GDAL (for mosaic functionality)

## Quick Start

### Linux

#### 1. One-Click Run (Recommended for Beginners)

```bash
# Clone or download the project
cd DockerS1Pre

# Add execute permission
chmod +x process.sh mosaic.sh

# Run default monitoring mode
./process.sh
```

This command will:
- Automatically detect and install SNAP (if not installed)
- Monitor the `./data` directory for new files
- Output processed results to `./output` directory

#### 2. Run with Custom Parameters

```bash
./process.sh -i /path/to/s1_data -o /path/to/output -r 40 -d "Copernicus 30m Global DEM"
```

#### 3. Batch Mode (Exit After Processing)

```bash
./process.sh -i ./data -o ./output --batch
```

### Windows

#### Option 1: Using CMD Batch Script

```cmd
:: Run with default parameters
process.bat

:: Custom parameters
process.bat -i .\data -o .\output -r 40 -d "SRTM 3Sec"

:: Batch mode
process.bat -i .\data -o .\output -b
```

#### Option 2: Using PowerShell Script (Recommended)

```powershell
# Run with default parameters
.\process.ps1

# Custom parameters
.\process.ps1 -InputDir .\data -OutputDir .\output -Resolution 40 -DEM "SRTM 3Sec"

# View help
Get-Help .\process.ps1 -Detailed
```

> **Note**: First-time PowerShell script execution may require setting execution policy:
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

## Installation Guide

### Linux Installation

#### Method 1: Automatic Installation (Recommended)

The processing script will automatically detect and install required software:

```bash
./process.sh
```

The script will automatically install:
- SNAP 12.0 (ESA official SAR processing software)
- GDAL (Geospatial data processing library)
- Other necessary dependencies

#### Method 2: Manual Installation

##### 1. Install SNAP

For detailed installation steps, refer to [SNAP installation guide (Chinese)](SNAP安装.md)

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

##### 2. Install GDAL (for mosaic functionality)

```bash
sudo apt-get update
sudo apt-get install -y gdal-bin python3-gdal
```

##### 3. Install Docker (Optional)

For containerized deployment, refer to [Docker installation guide (Chinese)](Docker安装.md)

### Windows Installation

#### 1. Install SNAP

1. Download SNAP installer: https://step.esa.int/main/download/snap-download/
2. Run the installer and choose installation path (e.g., `C:\Program Files\snap`)
3. After installation, the script will automatically detect these common paths:
   - `C:\Program Files\snap\bin`
   - `%USERPROFILE%\AppData\Local\snap\bin`
   - `%USERPROFILE%\snap\bin`

4. Or manually add to system PATH:
```cmd
setx PATH "%PATH%;C:\Program Files\snap\bin"
```

#### 2. Install GDAL (for mosaic functionality)

**Option 1: Using OSGeo4W (Recommended)**
1. Download OSGeo4W: https://trac.osgeo.org/osgeo4w/
2. Select GDAL component during installation
3. Script will automatically detect `C:\OSGeo4W64\bin`

**Option 2: Using Conda**
```cmd
conda install -c conda-forge gdal
```

**Option 3: Using QGIS**
- QGIS installation includes GDAL, script will auto-detect

## Usage

### Main Script Functions

#### 1. Data Processing Scripts

| Platform | Script File | Description |
|----------|-------------|-------------|
| Linux | `process.sh` | Bash script, supports monitoring and batch modes |
| Windows | `process.bat` | CMD batch script |
| Windows | `process.ps1` | PowerShell script (more powerful, recommended) |

**Linux - process.sh**

```bash
# Default monitoring mode (continuously monitor new files)
./process.sh

# Batch mode (exit after processing)
./process.sh --batch

# Custom parameters
./process.sh -i /data/s1 -o /results -r 20 -d "SRTM 3Sec" -c "EPSG:4326"
```

**Windows CMD - process.bat**

```cmd
:: Run with default parameters
process.bat

:: Batch mode
process.bat -b

:: Custom parameters
process.bat -i .\data -o .\output -r 20 -d "SRTM 3Sec" -c "EPSG:4326"
```

**Windows PowerShell - process.ps1**

```powershell
# Run with default parameters
.\process.ps1

# Custom parameters
.\process.ps1 -InputDir .\data -OutputDir .\output -Resolution 20 -DEM "SRTM 3Sec" -CRS "EPSG:4326"
```

#### 2. Mosaic Scripts

| Platform | Script File | Description |
|----------|-------------|-------------|
| Linux | `mosaic.sh` | Bash mosaic script |
| Windows | `mosaic.bat` | CMD mosaic script |
| Windows | `mosaic.ps1` | PowerShell mosaic script (recommended) |

**Linux - mosaic.sh**

```bash
# Edit path parameters in the script
nano mosaic.sh

# Run mosaic
./mosaic.sh
```

**Windows CMD - mosaic.bat**

```cmd
:: Default parameters
mosaic.bat

:: Custom parameters
mosaic.bat -i .\output -o .\mosaic\result.tif -r 20
```

**Windows PowerShell - mosaic.ps1**

```powershell
# Default parameters
.\mosaic.ps1

# Custom parameters
.\mosaic.ps1 -InputDir .\output -OutputFile .\mosaic\result.tif -Resolution 20 -Resampling average
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
8. **dB Conversion** - Convert linear values to decibels
9. **Output Saving** - Save as GeoTIFF format

## Configuration Parameters

### Command Line Parameters

#### Linux (process.sh) / Windows CMD (process.bat)

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| `-i, --input` | Input directory path | `./data` | `-i /path/to/s1_data` |
| `-o, --output` | Output directory path | `./output` | `-o /path/to/results` |
| `-g, --graph` | Graph XML file | `graph.xml` | `-g custom_graph.xml` |
| `-r, --resolution` | Output resolution (meters) | `40` | `-r 20` |
| `-a, --origin` | Grid origin offset | `0.0` | `-a 5.0` |
| `-f, --filter` | Speckle filter method | `Lee` | `-f "Refined Lee"` |
| `-d, --dem` | Digital Elevation Model | `ACE30` | `-d "SRTM 3Sec"` |
| `-c, --crs` | Coordinate Reference System | `EPSG:3031` | `-c "EPSG:4326"` |
| `-b, --batch` | Batch mode | Monitor mode | `--batch` |
| `-h, --help` | Show help information | - | `--help` |

#### Windows PowerShell (process.ps1)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-InputDir` | Input directory path | `.\data` |
| `-OutputDir` | Output directory path | `.\output` |
| `-Graph` | Graph XML file | `graph.xml` |
| `-Resolution` | Output resolution (meters) | `40` |
| `-Origin` | Grid origin offset | `0.0` |
| `-Filter` | Speckle filter method | `Lee` |
| `-DEM` | Digital Elevation Model | `ACE30` |
| `-CRS` | Coordinate Reference System | `EPSG:3031` |

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

### Directory Structure

```
DockerS1Pre/
├── process.sh          # Linux main processing script
├── process.bat         # Windows CMD processing script
├── process.ps1         # Windows PowerShell processing script
├── mosaic.sh           # Linux mosaic script
├── mosaic.bat          # Windows CMD mosaic script
├── mosaic.ps1          # Windows PowerShell mosaic script
├── graph.xml           # SNAP processing workflow configuration
├── download.ipynb      # Data download Jupyter Notebook
├── data/               # Input data directory (default)
├── output/             # Output results directory (default)
├── logs/               # Log files directory
├── roi/                # ROI vector files directory
├── Docker安装.md       # Docker installation guide
├── SNAP安装.md         # SNAP installation guide
├── README.md           # Chinese user guide
└── README_EN.md        # English user guide
```

### Core Files Description

| File | Platform | Description |
|------|----------|-------------|
| `process.sh` | Linux | Main processing script, supports monitoring and batch modes |
| `process.bat` | Windows | CMD batch script |
| `process.ps1` | Windows | PowerShell script, more powerful |
| `mosaic.sh` | Linux | GeoTIFF mosaic script |
| `mosaic.bat` | Windows | CMD mosaic script |
| `mosaic.ps1` | Windows | PowerShell mosaic script |
| `graph.xml` | Cross-platform | SNAP processing workflow definition file |
| `download.ipynb` | Cross-platform | Sentinel-1 data download tool |

## Troubleshooting

### Linux Common Issues

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

**3. Line ending issues (scripts copied from Windows)**
```bash
# Convert line endings
sed -i 's/\r$//' process.sh mosaic.sh
```

**4. Insufficient memory**
```bash
# Edit SNAP configuration to increase memory limit
nano $SNAP_HOME/bin/gpt.vmoptions
# Add: -Xmx8g (8GB memory)
```

### Windows Common Issues

**1. SNAP not found**
```cmd
:: Check if gpt is available
where gpt

:: If not found, manually add to PATH
setx PATH "%PATH%;C:\Program Files\snap\bin"
```

**2. PowerShell execution policy restriction**
```powershell
# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**3. GDAL not found**
```cmd
:: Check if GDAL is available
where gdalbuildvrt

:: If using OSGeo4W, add to PATH
setx PATH "%PATH%;C:\OSGeo4W64\bin"
```

**4. Chinese path issues**
- Recommend placing project in pure English path
- Or ensure system locale settings support UTF-8

**5. Insufficient memory**
```
Edit SNAP configuration file:
C:\Program Files\snap\bin\gpt.vmoptions
Add: -Xmx8g (8GB memory)
```

### Log Analysis

Processing logs are saved in the `logs/` directory

**Linux**:
```bash
# View real-time logs
tail -f logs/$(ls logs/ | tail -1)

# Search for error messages
grep -i "error\|exception\|failed" logs/*.log
```

**Windows PowerShell**:
```powershell
# View latest log
Get-Content (Get-ChildItem logs\*.log | Sort-Object LastWriteTime -Descending | Select-Object -First 1) -Tail 50

# Search for error messages
Select-String -Path logs\*.log -Pattern "error|exception|failed" -CaseSensitive:$false
```

## References

### Official Documentation

- [SNAP Official Documentation](http://step.esa.int/main/doc/) - Complete SNAP software user guide
- [Sentinel-1 User Guide](https://sentinel.esa.int/web/sentinel/user-guides/sentinel-1-sar) - ESA official Sentinel-1 data documentation
- [GDAL Documentation](https://gdal.org/) - GDAL geospatial data processing library documentation

### Technical Support

- [SNAP Forum](https://forum.step.esa.int/) - ESA official technical support forum

### Data Download

- [Copernicus Open Access Hub](https://scihub.copernicus.eu/) - Official data download platform
- [Alaska Satellite Facility](https://search.asf.alaska.edu/) - ASF data search platform

---

**Notes**:
- Processing a single scene takes approximately 24 minutes
- Ensure sufficient storage space when processing large amounts of data
- First run will download orbit files and DEM data, requiring network connection
- Backup important data before processing
- Linux scripts use Unix line endings (LF), Windows scripts use Windows line endings (CRLF)
- Batch mode is recommended for production environments
