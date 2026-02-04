# 1. 询问存放路径
$userInput = Read-Host "请输入存放路径 (例如 C:\ccc)"
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

# 4. 创建 hooks.json (无 BOM UTF-8)
Write-Host "配置 hooks.json (腾讯云镜像)..." -ForegroundColor Cyan
$hooksContent = '{"node":{"index":{"template":"https://mirrors.cloud.tencent.com/nodejs-release/index.json"},"distro":{"template":"https://mirrors.cloud.tencent.com/nodejs-release/v{{version}}/node-v{{version}}-{{os}}-x64.zip"}}}'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($hooksPath, $hooksContent, $Utf8NoBom)

# 5. 用户环境变量深度清理与配置
Write-Host "正在优化用户环境变量..." -ForegroundColor Cyan

# 设置自定义的 VOLTA_HOME
[Environment]::SetEnvironmentVariable("VOLTA_HOME", "$voltaRoot\", "User")
[Environment]::SetEnvironmentVariable("VOLTA_FEATURE_PNPM", "1", "User")

# 获取当前用户 Path
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$userAppDataVolta = "$env:LOCALAPPDATA\Volta\bin"

$pathList = New-Object System.Collections.Generic.List[string]

if ($userPath) {
    $userPath.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object {
        $item = $_.Trim()
        $trimmedItem = $item.TrimEnd('\')
        
        # 排除规则：
        # 1. 排除 MSI 默认生成的 AppData 路径
        # 2. 排除已有的 %VOLTA_HOME%\bin（防止重复添加）
        if ($trimmedItem -ne $userAppDataVolta.TrimEnd('\') -and $item -ne "%VOLTA_HOME%\bin") {
            $pathList.Add($item)
        }
    }
}

# 仅追加我们自定义的数据 bin 目录
$pathList.Add("%VOLTA_HOME%\bin")

# 重新组装并写入
$finalUserPath = [string]::Join(";", $pathList)
[Environment]::SetEnvironmentVariable("Path", $finalUserPath, "User")

Write-Host "`n✅ 安装与配置已完成！" -ForegroundColor Green
Write-Host "--------------------------------------------------"
Write-Host "软件安装位置 (系统变量): $voltaDir\"
Write-Host "数据存放位置 (VOLTA_HOME): $voltaRoot\"
Write-Host "已清理多余路径: $userAppDataVolta"
Write-Host "--------------------------------------------------"
Write-Host "💡 请重启终端后，输入 'volta -v' 验证。"

# 保持窗口开启
Read-Host "`n全部执行完毕，按回车键关闭窗口..."