$ErrorActionPreference = 'Stop'

$shortcutPaths = @(
    (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Codex 自动代理.lnk'),
    (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Codex 自动代理.lnk')
)

foreach ($shortcutPath in $shortcutPaths) {
    if (Test-Path -LiteralPath $shortcutPath) {
        Remove-Item -LiteralPath $shortcutPath -Force
    }
}

$installDirectory = Join-Path $env:LOCALAPPDATA 'CodexAutoProxyLauncher'
if (Test-Path -LiteralPath $installDirectory) {
    $resolvedPath = (Resolve-Path -LiteralPath $installDirectory).Path
    $expectedPath = [System.IO.Path]::GetFullPath($installDirectory)
    if ($resolvedPath -ne $expectedPath) {
        throw "拒绝删除非预期目录：$resolvedPath"
    }
    Remove-Item -LiteralPath $resolvedPath -Recurse -Force
}

Write-Host '卸载完成。'
