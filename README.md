# Mise 一键安装配置脚本

一个用于在 Windows 系统上自动安装和配置 [Mise](https://mise.jdx.dev/) 的 PowerShell 脚本，包含完整的 Node.js 开发环境配置。

## 功能特性

- ✅ 自动下载并安装 Mise v2026.5.5
- ✅ 支持自定义安装路径和数据存放位置
- ✅ **支持离线安装**（指定本地 ZIP 文件跳过下载）
- ✅ 自动配置国内镜像源（腾讯云 Node.js 镜像 + npm 淘宝镜像）
- ✅ 自动安装 Node.js、npm、pnpm
- ✅ 智能环境变量管理（永久 + 当前会话）
- ✅ 自动配置 npm 和 pnpm 目录
- ✅ 无需管理员权限
- ✅ 当前窗口立即可用，无需重启

## 使用方法

### 1. 运行脚本

在 PowerShell 中执行（**无需管理员权限**）：

```powershell
.\webDev.ps1
```

### 2. 输入安装路径

脚本支持两种输入格式：

#### 格式一：自动下载（需要网络）
```
请输入存放路径，格式如下：
  - 只输入路径: E:\webDev (将自动下载)
  - 带zip文件: E:\webDev E:\mise-v2026.2.3-windows-x64.zip (跳过下载)
输入: E:\webDev
```

#### 格式二：离线安装（跳过下载）
```
输入: E:\webDev E:\mise-v2026.2.3-windows-x64.zip
```

> 💡 **提示**：如果网络不好或需要离线安装，可以提前下载 [Mise ZIP 文件](https://github.com/jdx/mise/releases)，然后使用格式二安装。

### 3. 自动完成安装

脚本会自动完成以下步骤：

1. 下载并解压 Mise（或使用指定的 ZIP 文件）
2. 配置 Mise 环境变量和数据目录
3. 配置 Node.js 国内镜像源
4. 安装 Node.js（最新版本）
5. 配置 npm 镜像源、全局目录和缓存目录
6. 安装 pnpm（优先使用 mise，失败时使用 npm）
7. 配置 pnpm 存储目录
8. 当前窗口立即生效

## 配置说明

### 目录结构

假设你输入的路径是 `E:\webDev`，脚本会创建：

```
E:\webDev\
├── mise\                   # Mise 程序安装目录
│   └── bin\
│       └── mise.exe       # Mise 可执行文件
├── miseRoot\              # Mise 数据存放目录
│   ├── mise\              # 工具安装目录 (MISE_DATA_DIR)
│   │   └── shims\         # 工具的 shim 可执行文件
│   ├── cache\             # 缓存目录 (MISE_CACHE_DIR)
│   ├── tmp\               # 临时文件目录 (MISE_TMP_DIR)
│   ├── system\            # 系统配置目录 (MISE_SYSTEM_DIR)
│   └── config\            # 配置目录 (MISE_CONFIG_DIR)
│       └── config.toml    # 全局配置文件
├── npm\                   # npm 目录
│   ├── global\            # npm 全局包安装目录
│   └── cache\             # npm 缓存目录
└── pnpm\                  # pnpm 目录
    ├── store\             # pnpm 包存储（所有项目共享）
    │   └── .pnpm-store
    ├── global-dir\        # pnpm 全局包
    │   └── .bin\          # 全局可执行文件
    ├── cache-dir\         # pnpm 缓存
    └── state-dir\         # pnpm 状态文件
```

### 环境变量

脚本会自动配置以下用户环境变量：

#### Mise 相关
- `MISE_DATA_DIR`: 工具安装目录（如 `E:\webDev\miseRoot\mise`）
- `MISE_CACHE_DIR`: 缓存目录（如 `E:\webDev\miseRoot\cache`）
- `MISE_TMP_DIR`: 临时文件目录（如 `E:\webDev\miseRoot\tmp`）
- `MISE_SYSTEM_DIR`: 系统配置目录（如 `E:\webDev\miseRoot\system`）
- `MISE_CONFIG_DIR`: 配置目录（如 `E:\webDev\miseRoot\config`）
- `MISE_GLOBAL_CONFIG_FILE`: 全局配置文件路径（如 `E:\webDev\miseRoot\config\config.toml`）
- `MISE_NODE_MIRROR_URL`: Node.js 镜像源（`https://mirrors.cloud.tencent.com/nodejs-release/`）

#### Path 环境变量
自动添加以下路径到 Path（自动去重）：
- `E:\webDev\mise\bin` - Mise 可执行文件
- `E:\webDev\miseRoot\mise\shims` - 工具的 shim 文件（node、npm、pnpm 等）

**特点**：
- 永久生效（用户级环境变量）
- 当前窗口立即生效（无需重启终端）
- 自动去重，避免重复路径

### npm 配置

自动配置 npm：

```bash
registry=https://registry.npmmirror.com
prefix=E:\webDev\npm\global
cache=E:\webDev\npm\cache
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
mise -v       # 显示 Mise 版本
node -v       # 显示 Node.js 版本
npm -v        # 显示 npm 版本
pnpm -v       # 显示 pnpm 版本
```

查看配置：

```powershell
mise list                    # 查看所有已安装的工具
npm config get registry      # 查看 npm 镜像源
npm config get prefix        # 查看 npm 全局目录
pnpm config get store-dir    # 查看 pnpm 存储目录
```

## 使用 Mise

### 安装其他工具

```powershell
# 安装指定版本的 Node.js
mise install node@20.11.0

# 安装 Python
mise install python

# 安装 Go
mise install go

# 查看可用工具
mise plugins list
```

### 全局激活工具

```powershell
# 全局激活 Node.js
mise use -g node@20.11.0

# 全局激活 Python
mise use -g python@3.12
```

### 项目级版本管理

在项目目录下创建 `.mise.toml` 文件：

```toml
[tools]
node = "20.11.0"
pnpm = "9.0.0"
```

进入该目录时，mise 会自动切换到指定版本。

### 查看已安装的工具

```powershell
mise list              # 列出所有已安装的工具
mise current          # 显示当前激活的工具版本
```

## 系统要求

- Windows 操作系统（Windows 10/11）
- PowerShell 5.0 或更高版本
- **无需管理员权限**（仅操作用户级环境变量）
- 网络连接（用于下载安装包，离线安装除外）

## 注意事项

### ✅ 正常情况
- 脚本运行后当前窗口立即可用，无需重启
- 新打开的终端窗口会自动识别环境变量
- 脚本会自动清理下载的 ZIP 文件
- 支持重复运行，会自动更新配置
### 🔧 手动解决 GitHub API 限制

现在安装包时如果源头是gitbub，会默认使用反代镜像（ghfast.top），避免 API 限制问题。

如果需要手动添加 GitHub Token，可以：

```powershell
# 设置 GitHub Token（获取方式见下文）
$env:GITHUB_TOKEN = "your_github_token_here"

# 然后运行脚本
.\webDev.ps1
```
或者手动环境变量（Windows 10/11）
- 变量名：`GITHUB_TOKEN`
- 值：你的 GitHub 个人访问令牌（PAT）

如何获取 GitHub Token：
1. 访问 [GitHub Settings → Tokens](https://github.com/settings/tokens)
2. 点击 "Generate new token (classic)"
3. 勾选 `public_repo` 权限
4. 复制生成的 token

## 关于 Mise

Mise 是一个通用的开发工具版本管理器（类似于 asdf 但更快更强大）。它可以：

- 管理多种语言和工具（Node.js、Python、Go、Ruby 等）
- 为不同项目自动切换工具版本
- 比传统版本管理器更快（用 Rust 编写）
- 支持全局和项目级配置
- 无需手动配置 PATH 或版本切换命令
- 支持任务运行器功能（类似 make/just）

更多信息请访问：[mise.jdx.dev](https://mise.jdx.dev/)

## 与 Volta 的对比

| 特性 | Mise | Volta |
|------|------|-------|
| 支持语言 | Node.js、Python、Go、Ruby 等 20+ | 仅 Node.js 生态 |
| 性能 | 极快（Rust） | 快（Rust） |
| 配置文件 | `.mise.toml`、`.tool-versions` | `package.json` |
| 社区支持 | 活跃 | 不活跃（基本停止更新） |
| Windows 支持 | 完整支持 | 完整支持 |
| 学习曲线 | 中等 | 简单 |
| 适用场景 | 多语言项目、全栈开发 | 纯前端项目 |

## 常见问题

### Q: 为什么不需要管理员权限？
A: 脚本只操作用户级环境变量和用户目录，不涉及系统级配置。

### Q: 当前窗口为什么能立即使用？
A: 脚本同时设置了永久环境变量和当前会话的环境变量。

### Q: pnpm 的 store-dir 有什么用？
A: pnpm 使用硬链接共享依赖，所有项目共用一个 store，大幅节省磁盘空间和安装时间。

### Q: 可以修改安装路径吗？
A: 可以，重新运行脚本并输入新路径即可。旧的环境变量会被自动更新。

### Q: 如何卸载？
1. 删除安装目录（如 `E:\webDev`）
2. 删除用户环境变量：`MISE_*` 开头的变量
3. 从 Path 中删除相关路径

### Q: Mise 和 nvm 有什么区别？
- **nvm**: 只管理 Node.js 版本
- **mise**: 管理多种语言和工具（Node.js、Python、Go、Ruby 等）
- **性能**: mise 更快（Rust vs Shell）
- **推荐**: 多语言项目用 mise，纯 Node.js 项目两者皆可

## 故障排除

### 问题：mise 命令找不到
**解决**：
```powershell
# 检查环境变量
$env:Path
# 应包含：E:\webDev\mise\bin

# 手动添加到 Path
$env:Path += ";E:\webDev\mise\bin"
```

### 问题：node/npm/pnpm 命令找不到
**解决**：
```powershell
# 检查 shims 目录是否在 Path 中
$env:Path
# 应包含：E:\webDev\miseRoot\mise\shims

# 查看已安装的工具
mise list

# 确认工具已全局激活
mise use -g node
mise use -g pnpm
```

### 问题：下载速度慢
**解决**：
1. 使用离线安装方式（提前下载 ZIP 文件）
2. 使用代理或 VPN
3. 更换镜像源（脚本已配置国内镜像）

## 更新日志

### v2026.5.5 (2026-05-11)
- ✅ 更新 Mise 版本至 v2026.5.5
- ✅ 为 pnpm 添加 GitHub 反代镜像配置（ghfast.top），避免 API 限制
- ✅ 更新 README，移除过时的 GitHub API 限制说明

### v2026.4.6 (2026-04-09)
- ✅ 更新 Mise 版本至 v2026.4.6

### v2026.3.0 (2026-03-08)
- ✅ 添加 Windows 环境变量配置说明

### v2026.2.3 (2026-02-06)
- ✅ 支持通过指定 ZIP 文件路径跳过下载
- ✅ 更新 Node.js 镜像源为腾讯云
- ✅ 优化 pnpm 安装逻辑（mise 失败时自动使用 npm）
- ✅ 使用 mise 替代传统包管理器
- ✅ 为 mise 命令添加 --verbose 参数增强调试信息
- ✅ 修正 npm 全局目录配置并改进 pnpm 安装流程

## License

MIT

---

**维护者**：如有问题请提交 Issue
**最后更新**：2026-05-11
