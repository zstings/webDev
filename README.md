# Volta 一键安装配置脚本

一个用于在 Windows 系统上自动安装和配置 [Volta](https://volta.sh/) 的 PowerShell 脚本。

## 功能特性

- 自动下载并安装 Volta v2.0.2
- 自定义安装路径和数据存放位置
- 自动配置腾讯云镜像源加速 Node.js 下载
- 智能清理和优化用户环境变量
- 无需手动配置，开箱即用

## 使用方法

### 运行脚本

以管理员权限打开 PowerShell，执行：

```powershell
.\webDev.ps1
```

### 输入安装路径

脚本会提示输入存放路径，例如：

```
请输入存放路径 (例如 C:\ccc): C:\dev
```

### 等待安装完成

脚本会自动完成以下步骤：

1. 创建必要的目录结构
2. 下载 Volta MSI 安装包
3. 静默安装 Volta
4. 配置腾讯云镜像源
5. 优化环境变量配置

## 配置说明

### 目录结构

假设你输入的路径是 `C:\dev`，脚本会创建：

```
C:\dev\
├── volta\           # Volta 程序安装目录
└── voltaRoot\       # Volta 数据存放目录 (VOLTA_HOME)
    └── hooks.json   # 镜像源配置文件
```

### 镜像源配置

脚本自动配置腾讯云镜像源，加速 Node.js 下载：

```json
{
  "node": {
    "index": {
      "template": "https://mirrors.cloud.tencent.com/nodejs-release/index.json"
    },
    "distro": {
      "template": "https://mirrors.cloud.tencent.com/nodejs-release/v{{version}}/node-v{{version}}-{{os}}-x64.zip"
    }
  }
}
```

### 环境变量

脚本会自动配置以下用户环境变量：

- `VOLTA_HOME`: 指向数据存放目录（如 `C:\dev\voltaRoot\`）
- `Path`: 添加 `%VOLTA_HOME%\bin`，并清理冗余路径

## 验证安装

安装完成后，**重启终端**，然后执行：

```powershell
volta -v
```

如果显示版本号，说明安装成功。

## 开始使用 Volta

安装 Node.js 版本：

```powershell
# 安装最新 LTS 版本
volta install node

# 安装指定版本
volta install node@18.20.0

# 安装包管理器
volta install npm
volta install yarn
volta install pnpm
```

固定项目 Node.js 版本：

```powershell
# 在项目目录下执行
volta pin node@18.20.0
volta pin npm@10.0.0
```

## 系统要求

- Windows 操作系统
- PowerShell 5.0 或更高版本
- 管理员权限（用于安装 MSI 和配置环境变量）

## 注意事项

- 安装过程需要网络连接
- 首次运行需要管理员权限
- 安装完成后需要重启终端才能使用 Volta 命令
- 脚本会自动清理下载的 MSI 安装包

## 关于 Volta

Volta 是一个快速、可靠的 JavaScript 工具链管理器。它可以：

- 管理多个 Node.js 版本
- 为不同项目自动切换 Node.js 版本
- 确保团队使用相同的工具链版本
- 提供更快的工具安装和切换速度

更多信息请访问：[volta.sh](https://volta.sh/)

## License

MIT
