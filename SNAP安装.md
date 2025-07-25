# SNAP 安装指南

## 下载安装包

### 标准下载

```bash
wget https://download.esa.int/step/snap/12.0/installers/esa-snap_all_linux-12.0.0.sh
```

### 快速下载（推荐）

使用 aria2c 多线程下载，aria2 是一款支持多线程的命令行下载工具，通常比 wget 更快。

1. 安装 aria2（Ubuntu）：
```bash
sudo apt-get update
sudo apt-get install -y aria2
```

2. 用 aria2c 下载 SNAP 安装包：
```bash
aria2c -x 16 -s 16 https://download.esa.int/step/snap/12.0/installers/esa-snap_all_linux-12.0.0.sh
```

其中 `-x 16 -s 16` 表示最多16个连接并发下载，通常能显著提升速度。


## 步骤一：使用 -q（quiet）和 -dir 参数安装

```bash
cd /hy-tmp
chmod +x esa-snap_all_linux-12.0.0.sh
./esa-snap_all_linux-12.0.0.sh -q -dir /root/snap
```

**参数说明：**
- `-q`：静默模式（无图形界面）
- `-dir`：指定安装目录（可以是你希望的任意路径，如 /root/snap）

> 📝 如果你没有权限写 /root/snap，可以换成 /opt/snap 或 /home/youruser/snap

## 步骤二：验证安装是否成功

```bash
ls /root/snap/bin/gpt
```

你应该看到输出：
```
/root/snap/bin/gpt
```

## 步骤三：配置环境变量（可选但推荐）

```bash
export SNAP_HOME=/root/snap
export PATH=$SNAP_HOME/bin:$PATH
```

你可以将上面两行加入 ~/.bashrc 或 ~/.zshrc，使每次登录时自动生效：

```bash
echo 'export SNAP_HOME=/root/snap' >> ~/.bashrc
echo 'export PATH=$SNAP_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

## 步骤四：验证 gpt 是否可用

```bash
gpt -h
```