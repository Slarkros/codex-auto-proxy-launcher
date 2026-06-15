param(
    [switch]$NoDesktopShortcut
)

$ErrorActionPreference = 'Stop'

function New-LauncherShortcut {
    param(
        [string]$ShortcutPath,
        [string]$LauncherPath,
        [string]$IconPath
    )

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($ShortcutPath)
    $shortcut.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$LauncherPath`""
    $shortcut.WorkingDirectory = Split-Path -Parent $LauncherPath
    $shortcut.IconLocation = "$IconPath,0"
    $shortcut.Description = '使用当前 Windows 系统代理启动 Codex'
    $shortcut.Save()
}

$sourceLauncher = Join-Path $PSScriptRoot 'CodexAutoProxy.ps1'
if (-not (Test-Path -LiteralPath $sourceLauncher)) {
    throw "安装包不完整，缺少文件：$sourceLauncher"
}

$package = Get-AppxPackage -Name OpenAI.Codex -ErrorAction SilentlyContinue |
    Sort-Object Version -Descending |
    Select-Object -First 1
if (-not $package) {
    throw '未找到已安装的 Codex Windows 应用。请安装 Codex 后重新运行安装脚本。'
}

$codexExecutable = Join-Path $package.InstallLocation 'app\Codex.exe'
if (-not (Test-Path -LiteralPath $codexExecutable)) {
    throw "找到了 Codex 软件包，但没有找到启动文件：$codexExecutable"
}

$installDirectory = Join-Path $env:LOCALAPPDATA 'CodexAutoProxyLauncher'
$installedLauncher = Join-Path $installDirectory 'CodexAutoProxy.ps1'
New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
Copy-Item -LiteralPath $sourceLauncher -Destination $installedLauncher -Force
Unblock-File -LiteralPath $installedLauncher -ErrorAction SilentlyContinue

$startMenuDirectory = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
New-LauncherShortcut `
    -ShortcutPath (Join-Path $startMenuDirectory 'Codex 自动代理.lnk') `
    -LauncherPath $installedLauncher `
    -IconPath $codexExecutable

if (-not $NoDesktopShortcut) {
    New-LauncherShortcut `
        -ShortcutPath (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Codex 自动代理.lnk') `
        -LauncherPath $installedLauncher `
        -IconPath $codexExecutable
}

Write-Host '安装完成。请通过“Codex 自动代理”快捷方式启动 Codex。'
