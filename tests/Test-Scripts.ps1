param(
    [switch]$SyntaxOnly
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$scripts = @(
    (Join-Path $projectRoot 'CodexAutoProxy.ps1'),
    (Join-Path $projectRoot 'install.ps1'),
    (Join-Path $projectRoot 'uninstall.ps1')
)

foreach ($script in $scripts) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $script,
        [ref]$tokens,
        [ref]$errors
    ) | Out-Null

    if ($errors.Count -gt 0) {
        throw "脚本语法检查失败：$script`n$($errors | Out-String)"
    }
}

if (-not $SyntaxOnly) {
    $checkOutput = & (Join-Path $projectRoot 'CodexAutoProxy.ps1') -CheckOnly
    if ($LASTEXITCODE -ne 0) {
        throw 'CodexAutoProxy.ps1 -CheckOnly 执行失败。'
    }
    Write-Output $checkOutput
}

Write-Output '全部检查通过。'
