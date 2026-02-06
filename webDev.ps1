# ========== 环境变量管理函数 ==========

# 设置环境变量（永久 + 当前会话）
function Set-EnvVariable {
    param(
        [string]$Name,
        [string]$Value
    )
    [Environment]::SetEnvironmentVariable($Name, $Value, "User")
    Set-Item -Path "env:$Name" -Value $Value
}

# 追加路径到 Path 环境变量（自动去重）
function Add-PathVariable {
    param(
        [string]$NewPath
    )

    # 标准化路径格式
    $NewPath = $NewPath.Replace('/', '\').TrimEnd('\')

    # 1. 更新永久的用户级 Path
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $pathList = New-Object System.Collections.Generic.List[string]

    if ($userPath) {
        $userPath.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object {
            $item = $_.Trim()
            if ($item) {
                $pathList.Add($item)
            }
        }
    }

    # 检查用户级 Path 是否已存在（忽略末尾的反斜杠）
    $existsInUser = $false
    foreach ($item in $pathList) {
        if ($item.TrimEnd('\') -eq $NewPath.TrimEnd('\')) {
            $existsInUser = $true
            break
        }
    }

    # 如果不存在，则追加到用户级
    if (-not $existsInUser) {
        $pathList.Add($NewPath)
    }

    # 重新组装用户级 Path（最后不要分号）
    $finalUserPath = [string]::Join(";", $pathList)
    [Environment]::SetEnvironmentVariable("Path", $finalUserPath, "User")

    # 2. 更新当前会话的 Path（始终检查并更新，不依赖 $existsInUser）
    $expandedPath = [Environment]::ExpandEnvironmentVariables($NewPath)
    # 检查当前会话的 Path 中是否已包含（忽略大小写）
    $pathItems = $env:Path.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
    $existsInCurrent = $false
    foreach ($item in $pathItems) {
        if ($item.TrimEnd('\').Trim() -eq $expandedPath.TrimEnd('\')) {
            $existsInCurrent = $true
            break
        }
    }
    if (-not $existsInCurrent) {
        $env:Path = "$env:Path;$expandedPath"
    }
}

# ========== 主脚本开始 ==========

# 1. 询问存放路径
$userInput = Read-Host "请输入存放路径 (例如 E:\webDev)"
$basePath = $userInput.Replace('/', '\').TrimEnd('\')

# 定义路径
$miseDir = "$basePath\mise"
$miseRoot = "$basePath\miseRoot"
$msiPath = "$basePath\mise.zip"
$hooksPath = "$miseRoot\hooks.json"
$downloadUrl = "https://ghfast.top/https://github.com/jdx/mise/releases/download/v2026.2.3/mise-v2026.2.3-windows-x64.zip"

# 创建目录
if (!(Test-Path $basePath)) { New-Item -ItemType Directory -Path $basePath -Force | Out-Null }
if (!(Test-Path $miseRoot)) { New-Item -ItemType Directory -Path $miseRoot -Force | Out-Null }

# 2. 下载 (使用 curl)
Write-Host "正在下载 mise zip..." -ForegroundColor Cyan
& curl.exe --location --fail "$downloadUrl" --output "$msiPath"

# 检查下载是否成功
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 下载失败！curl 返回错误码: $LASTEXITCODE" -ForegroundColor Red
    Write-Host "请检查网络连接或下载地址是否正确" -ForegroundColor Yellow
    Read-Host "`n按回车键退出..."
    exit 1
}

# 验证文件是否存在且有内容
if (!(Test-Path $msiPath)) {
    Write-Host "❌ ZIP 文件不存在！下载可能失败" -ForegroundColor Red
    Read-Host "`n按回车键退出..."
    exit 1
}

$fileSize = (Get-Item $msiPath).Length
if ($fileSize -eq 0) {
    Write-Host "❌ ZIP 文件为空！下载不完整" -ForegroundColor Red
    Remove-Item $msiPath -Force
    Read-Host "`n按回车键退出..."
    exit 1
}

Write-Host "✅ 下载成功！文件大小: $([math]::Round($fileSize/1MB, 2)) MB" -ForegroundColor Green

# 3. 解压安装
Write-Host "正在解压 Mise 到 $miseDir ..." -ForegroundColor Cyan

try {
    # 创建临时解压目录
    $tempExtractPath = "$basePath\temp_extract"
    if (Test-Path $tempExtractPath) { Remove-Item $tempExtractPath -Recurse -Force }
    New-Item -ItemType Directory -Path $tempExtractPath -Force | Out-Null

    # 解压 ZIP 文件
    Expand-Archive -Path $msiPath -DestinationPath $tempExtractPath -Force

    # 检查解压内容，处理可能的嵌套文件夹
    $extractedItems = Get-ChildItem -Path $tempExtractPath

    if ($extractedItems.Count -eq 1 -and $extractedItems[0].PSIsContainer) {
        # 如果只有一个文件夹，将其内容移动到目标目录
        $innerFolder = $extractedItems[0].FullName
        if (Test-Path $miseDir) { Remove-Item $miseDir -Recurse -Force }
        Move-Item -Path $innerFolder -Destination $miseDir -Force
    } else {
        # 如果是多个文件/文件夹，直接移动到目标目录
        if (!(Test-Path $miseDir)) { New-Item -ItemType Directory -Path $miseDir -Force | Out-Null }
        Get-ChildItem -Path $tempExtractPath | Move-Item -Destination $miseDir -Force
    }

    # 清理临时目录和 ZIP 文件
    if (Test-Path $tempExtractPath) { Remove-Item $tempExtractPath -Recurse -Force }
    if (Test-Path $msiPath) { Remove-Item $msiPath -Force }

    Write-Host "✅ 解压完成！" -ForegroundColor Green
} catch {
    Write-Host "❌ 解压失败！错误信息: $($_.Exception.Message)" -ForegroundColor Red
    if (Test-Path $msiPath) { Remove-Item $msiPath -Force }
    Read-Host "`n按回车键退出..."
    exit 1
}

# 验证 Mise 是否安装成功
if (!(Test-Path "$miseDir\bin\mise.exe")) {
    Write-Host "❌ Mise 安装失败！未找到 mise.exe" -ForegroundColor Red
    Read-Host "`n按回车键退出..."
    exit 1
}

Write-Host "✅ Mise 安装成功！" -ForegroundColor Green

# 将 Mise 安装目录添加到当前会话的用户级 Path 和 用户级环境变量
Add-PathVariable -NewPath "$miseDir\bin"

# 5. 用户环境变量深度清理与配置
Write-Host "正在优化用户环境变量..." -ForegroundColor Cyan

# 设置 Mise 所需的环境变量
# mise 存放插件和工具安装的目录
Set-EnvVariable -Name "MISE_DATA_DIR" -Value "$miseRoot\mise"
# mise 存储内部缓存的目录
Set-EnvVariable -Name "MISE_CACHE_DIR" -Value "$miseRoot\cache"
# mise 存储临时文件的目录
Set-EnvVariable -Name "MISE_TMP_DIR" -Value "$miseRoot\tmp"
# mise 存储系统范围配置的目录
Set-EnvVariable -Name "MISE_SYSTEM_DIR" -Value "$miseRoot\system"
Set-EnvVariable -Name "MISE_CONFIG_DIR" -Value "$miseRoot\config"
# 通往配置文件的路径 默认：（通常是 ~/.config/mise/config.toml）$MISE_CONFIG_DIR/config.toml
Set-EnvVariable -Name "MISE_GLOBAL_CONFIG_FILE" -Value "$miseRoot\config\config.toml"

# 配置 mise 下载镜像源（使用国内镜像加速）
Set-EnvVariable -Name "MISE_NODE_MIRROR_URL" -Value "https://npmmirror.com/mirrors/node"

# 追加 Mise 数据目录 到 Path（用于访问 node、pnpm 等工具）
Add-PathVariable -NewPath "$miseRoot\mise\shims"

# 执行mise -v 查看版本信息
Write-Host "正在执行 mise -v 查看版本信息..." -ForegroundColor Cyan
& mise -v

# 检查 mise 命令是否可用
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Mise 命令执行失败！请检查安装是否正确" -ForegroundColor Red
    Read-Host "`n按回车键退出..."
    exit 1
}

# 执行mise install node
Write-Host "正在安装 Node.js..." -ForegroundColor Cyan
& mise install node

# 检查 Node.js 安装是否成功
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Node.js 安装失败！请检查网络连接或镜像配置" -ForegroundColor Red
    Read-Host "`n按回车键退出..."
    exit 1
}
# 执行mise use -g node（全局激活）
& mise use -g node


# 验证 node 和 npm 是否可用
$nodeVersion = & node -v 2>$null
$npmVersion = & npm -v 2>$null

if ([string]::IsNullOrEmpty($nodeVersion)) {
    Write-Host "❌ Node.js 安装失败！node 命令不可用" -ForegroundColor Red
    Read-Host "`n按回车键退出..."
    exit 1
}

if ([string]::IsNullOrEmpty($npmVersion)) {
    Write-Host "❌ npm 不可用！请检查 Node.js 安装" -ForegroundColor Red
    Read-Host "`n按回车键退出..."
    exit 1
}

Write-Host "Node.js 版本:" -ForegroundColor Green
Write-Host $nodeVersion -ForegroundColor White
Write-Host "npm 版本:" -ForegroundColor Green
Write-Host $npmVersion -ForegroundColor White

# 配置 npm 镜像源
Write-Host "正在配置 npm 镜像源..." -ForegroundColor Cyan
& npm config set registry https://registry.npmmirror.com

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ npm 镜像源配置失败" -ForegroundColor Red
    Read-Host "`n按回车键退出..."
    exit 1
}

Write-Host "当前 npm 源:" -ForegroundColor Green
& npm config get registry

Write-Host "正在配置 npm 全局目录..." -ForegroundColor Cyan
& npm config set cache "$basePath\npm\global"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ npm 全局目录配置失败" -ForegroundColor Red
    Read-Host "`n按回车键退出..."
    exit 1
}

Write-Host "当前 npm 全局目录:" -ForegroundColor Green
& npm config get global

Write-Host "正在配置 npm 缓存目录..." -ForegroundColor Cyan
& npm config set cache "$basePath\npm-cache"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ npm 缓存目录配置失败" -ForegroundColor Red
    Read-Host "`n按回车键退出..."
    exit 1
}

Write-Host "当前 npm 缓存目录:" -ForegroundColor Green
& npm config get cache

# 安装 pnpm
Write-Host "正在安装 pnpm..." -ForegroundColor Cyan
& mise install pnpm

# 全局激活 pnpm
& mise use -g pnpm

if ($LASTEXITCODE -eq 0) {
    # 验证 pnpm 是否可用
    $pnpmVersion = & pnpm -v 2>$null

    if ([string]::IsNullOrEmpty($pnpmVersion)) {
        Write-Host "❌ pnpm 安装失败！pnpm 命令不可用" -ForegroundColor Red
    } else {
        Write-Host "✅ pnpm 安装成功！" -ForegroundColor Green
        Write-Host "pnpm 版本:" -ForegroundColor Green
        Write-Host $pnpmVersion -ForegroundColor White

        # 配置 pnpm 存储目录
        Write-Host "正在配置 pnpm 存储目录..." -ForegroundColor Cyan
        $pnpmBaseDir = "$basePath\pnpm"
        & pnpm config set store-dir "$pnpmBaseDir\store\.pnpm-store"
        & pnpm config set global-dir "$pnpmBaseDir\global-dir"
        & pnpm config set global-bin-dir "$pnpmBaseDir\global-dir\.bin"
        & pnpm config set state-dir "$pnpmBaseDir\state-dir"
        & pnpm config set cache-dir "$pnpmBaseDir\cache-dir"

        Write-Host "pnpm 配置完成:" -ForegroundColor Green
        Write-Host "  store-dir: $pnpmBaseDir\store\.pnpm-store" -ForegroundColor White
        Write-Host "  global-bin-dir: $pnpmBaseDir\global-dir\.bin" -ForegroundColor White
    }
} else {
    Write-Host "❌ pnpm 安装失败！错误码: $LASTEXITCODE" -ForegroundColor Red
    Write-Host "请检查网络或 VOLTA_FEATURE_PNPM 环境变量" -ForegroundColor Yellow
    exit 1
}



Write-Host "`n✅ 安装与配置已完成！" -ForegroundColor Green
Write-Host "--------------------------------------------------" -ForegroundColor Cyan
Write-Host "软件安装位置: $miseDir\" -ForegroundColor White
Write-Host "数据存放位置 (MISE_DATA_DIR): $miseRoot\" -ForegroundColor White
Write-Host "已安装工具: Node.js, npm, pnpm" -ForegroundColor White
Write-Host "npm 镜像源: https://registry.npmmirror.com" -ForegroundColor White
Write-Host "--------------------------------------------------" -ForegroundColor Cyan
Write-Host "💡 新终端窗口将自动识别这些工具。" -ForegroundColor Yellow
Write-Host "💡 当前窗口已可以直接使用 mise, node, npm, pnpm 命令。" -ForegroundColor Yellow

# 保持窗口开启
Read-Host "`n全部执行完毕，按回车键关闭窗口..."