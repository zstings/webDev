# Volta 一键安装配置脚本

一个用于在 Windows 系统上自动安装和配置 [Volta](https://volta.sh/) 的 PowerShell 脚本，包含完整的 Node.js 开发环境配置。

## 功能特性

- ✅ 自动下载并安装 Volta v2.0.2
- ✅ 自定义安装路径和数据存放位置
- ✅ 自动配置国内镜像源（腾讯云 + 淘宝镜像）
- ✅ 自动安装 Node.js、npm、pnpm
- ✅ 智能环境变量管理（永久 + 当前会话）
- ✅ 自动配置 npm 和 pnpm 缓存目录
- ✅ 支持 pnpm、yarn 包管理器
- ✅ 无需管理员权限
- ✅ 当前窗口立即可用，无需重启

## 使用方法

### 1. 运行脚本

在 PowerShell 中执行（**无需管理员权限**）：

```powershell
.\webDev.ps1
```

### 2. 输入安装路径

脚本会提示输入存放路径，例如：

```
请输入存放路径 (例如 E:\webDev): E:\webDev
```

### 3. 自动完成安装

脚本会自动完成以下步骤：

1. 下载并安装 Volta
2. 配置镜像源（Node.js、pnpm、yarn）
3. 设置环境变量（VOLTA_HOME、VOLTA_FEATURE_PNPM、Path）
4. 安装 Node.js（最新 LTS 版本）
5. 配置 npm 镜像源和缓存目录
6. 安装 pnpm 并配置存储目录
7. 当前窗口立即生效

## 配置说明

### 目录结构

假设你输入的路径是 `E:\webDev`，脚本会创建：

```
E:\webDev\
├── volta\              # Volta 程序安装目录
├── voltaRoot\          # Volta 数据存放目录 (VOLTA_HOME)
│   ├── hooks.json      # 镜像源配置文件
│   ├── tools\          # Node.js、npm、pnpm 等工具
│   └── bin\            # 工具的可执行文件链接
├── npm-cache\          # npm 缓存目录
└── pnpm\               # pnpm 存储目录
    ├── store\          # pnpm 包存储（所有项目共享）
    ├── global-dir\     # pnpm 全局包
    ├── cache-dir\      # pnpm 缓存
    └── state-dir\      # pnpm 状态文件
```

### 镜像源配置

脚本自动配置国内镜像源，加速下载：

```json
{
  "node": {
    "index": {
      "template": "https://mirrors.cloud.tencent.com/nodejs-release/index.json"
    },
    "distro": {
      "template": "https://mirrors.cloud.tencent.com/nodejs-release/v{{version}}/node-v{{version}}-{{os}}-x64.zip"
    }
  },
  "pnpm": {
    "index": {
      "template": "https://registry.npmmirror.com/pnpm"
    },
    "distro": {
      "template": "https://registry.npmmirror.com/pnpm/-/pnpm-{{version}}.tgz"
    }
  },
  "yarn": {
    "index": {
      "template": "https://registry.npmmirror.com/yarn"
    },
    "distro": {
      "template": "https://registry.npmmirror.com/yarn/-/yarn-{{version}}.tgz"
    }
  }
}
```

### 环境变量

脚本会自动配置以下用户环境变量：

- `VOLTA_HOME`: 数据存放目录（如 `E:\webDev\voltaRoot\`）
- `VOLTA_FEATURE_PNPM`: 启用 pnpm 支持（值为 `1`）
- `Path`: 添加 `%VOLTA_HOME%\bin`，自动去重

**特点**：
- 永久生效（用户级环境变量）
- 当前窗口立即生效（无需重启终端）
- 自动清理旧的 Volta 路径

### npm 配置

自动配置 npm：

```bash
registry=https://registry.npmmirror.com
cache=E:\webDev\npm-cache
```

### pnpm 配置

自动配置 pnpm 存储目录：

```bash
store-dir=E:\webDev\pnpm\store\.pnpm-store
global-dir=E:\webDev\pnpm\global-dir
global-bin-dir=E:\webDev\pnpm\global-dir\.bin
state-dir=E:\webDev\pnpm\state-dir
cache-dir=E:\webDev\pnpm\cache-dir
```

**优势**：
- 所有项目共享依赖，节省磁盘空间
- 统一管理在非系统盘，避免占用 C 盘
- 安装速度更快

## 验证安装

安装完成后，**在当前窗口**即可验证：

```powershell
volta -v      # 显示 Volta 版本
node -v       # 显示 Node.js 版本
npm -v        # 显示 npm 版本
pnpm -v       # 显示 pnpm 版本
```

查看配置：

```powershell
volta list all           # 查看所有已安装的工具
npm config get registry  # 查看 npm 镜像源
pnpm config get store-dir # 查看 pnpm 存储目录
```

## 使用 Volta

### 安装其他工具

```powershell
# 安装 yarn
volta install yarn

# 安装指定版本的 Node.js
volta install node@18.20.0

# 安装指定版本的 pnpm
volta install pnpm@9.0.0
```

### 固定项目版本

在项目目录下执行：

```powershell
volta pin node@18.20.0
volta pin pnpm@9.0.0
```

这会在 `package.json` 中添加 `volta` 字段，确保团队成员使用相同版本。

### 切换 Node.js 版本

```powershell
# 安装多个版本
volta install node@18
volta install node@20

# Volta 会根据项目的 package.json 自动切换版本
cd project-with-node18  # 自动使用 Node 18
cd project-with-node20  # 自动使用 Node 20
```

## 系统要求

- Windows 操作系统
- PowerShell 5.0 或更高版本
- **无需管理员权限**（仅操作用户级环境变量）
- 网络连接（用于下载安装包）

## 注意事项

- ✅ 脚本运行后当前窗口立即可用，无需重启
- ✅ 新打开的终端窗口会自动识别环境变量
- ✅ 脚本会自动清理下载的 MSI 安装包
- ✅ 支持重复运行，会自动去重和更新配置
- ⚠️ 如果 `volta install pnpm` 失败，脚本会自动使用 `npm install -g pnpm` 作为备用方案

## 高级功能

### 环境变量管理函数

脚本提供了两个实用函数：

#### Set-EnvVariable
设置环境变量（永久 + 当前会话）：

```powershell
Set-EnvVariable -Name "MY_VAR" -Value "my_value"
```

#### Add-PathVariable
追加路径到 Path（自动去重）：

```powershell
Add-PathVariable -NewPath "C:\my\path"
```

### 自定义配置

如果需要修改配置，可以编辑以下文件：

- **镜像源**：`E:\webDev\voltaRoot\hooks.json`
- **npm 配置**：`%USERPROFILE%\.npmrc`
- **pnpm 配置**：`%USERPROFILE%\.npmrc` 或 `pnpm config set`

## 关于 Volta

Volta 是一个快速、可靠的 JavaScript 工具链管理器。它可以：

- 管理多个 Node.js 版本
- 为不同项目自动切换 Node.js 版本
- 确保团队使用相同的工具链版本
- 提供更快的工具安装和切换速度
- 无需手动配置 PATH 或版本切换命令

更多信息请访问：[volta.sh](https://volta.sh/)

## 常见问题

### Q: 为什么不需要管理员权限？
A: 脚本只操作用户级环境变量和用户目录，不涉及系统级配置。

### Q: 当前窗口为什么能立即使用？
A: 脚本同时设置了永久环境变量和当前会话的环境变量。

### Q: pnpm 的 store-dir 有什么用？
A: pnpm 使用硬链接共享依赖，所有项目共用一个 store，大幅节省磁盘空间和安装时间。

### Q: 可以修改安装路径吗？
A: 可以，重新运行脚本并输入新路径即可。旧的环境变量会被自动更新。

## License

MIT
