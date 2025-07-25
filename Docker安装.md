# Docker 安装指南

## 一、准备工作

### 1. 卸载旧版本（如有）

**Ubuntu/Debian:**
```bash
sudo apt remove docker docker-engine docker.io containerd runc
```

**CentOS/RHEL:**
```bash
sudo yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
```

### 2. 安装依赖工具

**Ubuntu/Debian:**
```bash
sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
```

**CentOS/RHEL:**
```bash
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
```

## 二、安装Docker引擎

### 方法1：通过官方仓库安装（推荐）

**Ubuntu/Debian:**

1. 添加Docker官方GPG密钥
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

2. 设置稳定版仓库
```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

3. 安装Docker引擎
```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
```

**CentOS/RHEL:**

1. 添加Docker仓库
```bash
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

2. 安装Docker引擎
```bash
sudo yum install -y docker-ce docker-ce-cli containerd.io
```

### 方法2：使用脚本快速安装（适合测试环境）

```bash
curl -fsSL https://get.docker.com | sudo sh
```

## 三、配置镜像加速器

### 中科大镜像加速

1. 创建配置目录并设置镜像源
```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
}
EOF
```

2. 重启Docker服务生效
```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```
