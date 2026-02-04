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

    # 2. 更新当前会话的 Path（追加展开后的路径）
    if (-not $existsInUser) {
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
}

# ========== 主脚本开始 ==========

# 1. 询问存放路径
$userInput = Read-Host "请输入存放路径 (例如 E:\webDev)"
$basePath = $userInput.Replace('/', '\').TrimEnd('\')

# 定义路径
$voltaDir = "$basePath\volta"
$voltaRoot = "$basePath\voltaRoot"
$msiPath = "$basePath\volta.msi"
$hooksPath = "$voltaRoot\hooks.json"
$downloadUrl = "https://ghfast.top/https://github.com/volta-cli/volta/releases/download/v2.0.2/volta-2.0.2-windows-x86_64.msi"

# 创建目录
if (!(Test-Path $basePath)) { New-Item -ItemType Directory -Path $basePath -Force | Out-Null }
if (!(Test-Path $voltaRoot)) { New-Item -ItemType Directory -Path $voltaRoot -Force | Out-Null }

# 2. 下载 (使用 curl)
Write-Host "正在下载 Volta MSI..." -ForegroundColor Cyan
& curl.exe --location --fail "$downloadUrl" --output "$msiPath"

# 3. 启动安装
Write-Host "正在安装 Volta 到 $voltaDir ..." -ForegroundColor Cyan
# MSI 会自动处理系统环境变量
$args = "/i `"$msiPath`" /qn /norestart INSTALLDIR=`"$voltaDir\`""
$process = Start-Process msiexec.exe -ArgumentList $args -Wait -PassThru

if (Test-Path $msiPath) { Remove-Item $msiPath -Force }

# MSI 安装后，将 Volta 安装目录添加到当前会话的 Path（系统级 Path 已由 MSI 添加，但当前窗口还未生效）
$env:Path = "$voltaDir;$env:Path"

# 4. 创建 hooks.json (无 BOM UTF-8)
Write-Host "配置 hooks.json (腾讯云镜像)..." -ForegroundColor Cyan
$hooksContent = @'
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
'@
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($hooksPath, $hooksContent, $Utf8NoBom)

# 5. 用户环境变量深度清理与配置
Write-Host "正在优化用户环境变量..." -ForegroundColor Cyan

# 设置自定义的 VOLTA_HOME 和 VOLTA_FEATURE_PNPM
Set-EnvVariable -Name "VOLTA_HOME" -Value "$voltaRoot\"
Set-EnvVariable -Name "VOLTA_FEATURE_PNPM" -Value "1"

# 清理旧的 AppData Volta 路径（如果存在）
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$userAppDataVolta = "$env:LOCALAPPDATA\Volta\bin"

if ($userPath -and $userPath.Contains($userAppDataVolta)) {
    $pathList = New-Object System.Collections.Generic.List[string]
    $userPath.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object {
        $item = $_.Trim()
        $trimmedItem = $item.TrimEnd('\')
        # 排除 MSI 默认生成的 AppData 路径
        if ($trimmedItem -ne $userAppDataVolta.TrimEnd('\')) {
            $pathList.Add($item)
        }
    }
    $cleanedPath = [string]::Join(";", $pathList)
    [Environment]::SetEnvironmentVariable("Path", $cleanedPath, "User")

    Write-Host "已清理旧路径: $userAppDataVolta" -ForegroundColor Yellow
}

# 追加自定义的 Volta bin 目录到 Path
Add-PathVariable -NewPath "%VOLTA_HOME%\bin"

# 执行volta -v 查看版本信息
Write-Host "正在执行 volta -v 查看版本信息..." -ForegroundColor Cyan
& volta -v

# 执行volta install node
Write-Host "正在安装 Node.js..." -ForegroundColor Cyan
& volta install node
Write-Host "Node.js 版本:" -ForegroundColor Green
& node -v
Write-Host "npm 版本:" -ForegroundColor Green
& npm -v

# 配置 npm 镜像源
Write-Host "正在配置 npm 镜像源..." -ForegroundColor Cyan
& npm config set registry https://registry.npmmirror.com
Write-Host "当前 npm 源:" -ForegroundColor Green
& npm config get registry
Write-Host "当前配置 npm 缓存目录:" -ForegroundColor Green
npm config set cache "$basePath\npm-cache"
Write-Host "当前 npm 缓存目录:" -ForegroundColor Green
& npm config get cache


# 安装 pnpm
Write-Host "正在安装 pnpm..." -ForegroundColor Cyan
& volta install pnpm
if ($LASTEXITCODE -eq 0) {
    Write-Host "pnpm 版本:" -ForegroundColor Green
    & pnpm -v
} else {
    Write-Host "pnpm 安装失败，请检查网络或 VOLTA_FEATURE_PNPM 环境变量" -ForegroundColor Red
}



Write-Host "`n✅ 安装与配置已完成！" -ForegroundColor Green
Write-Host "--------------------------------------------------" -ForegroundColor Cyan
Write-Host "软件安装位置: $voltaDir\" -ForegroundColor White
Write-Host "数据存放位置 (VOLTA_HOME): $voltaRoot\" -ForegroundColor White
Write-Host "已安装工具: Node.js, npm, pnpm" -ForegroundColor White
Write-Host "npm 镜像源: https://registry.npmmirror.com" -ForegroundColor White
Write-Host "--------------------------------------------------" -ForegroundColor Cyan
Write-Host "💡 新终端窗口将自动识别这些工具。" -ForegroundColor Yellow
Write-Host "💡 当前窗口已可以直接使用 volta, node, npm, pnpm 命令。" -ForegroundColor Yellow

# 保持窗口开启
Read-Host "`n全部执行完毕，按回车键关闭窗口..."