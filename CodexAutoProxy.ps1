param(
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'

function Show-LauncherMessage {
    param(
        [string]$Message,
        [string]$Title = 'Codex 自动代理',
        [ValidateSet('Info', 'Error')]
        [string]$Type = 'Info'
    )

    if ($CheckOnly) {
        if ($Type -eq 'Error') {
            [Console]::Error.WriteLine($Message)
        } else {
            Write-Output $Message
        }
        return
    }

    try {
        Add-Type -AssemblyName PresentationFramework
        $icon = if ($Type -eq 'Error') {
            [System.Windows.MessageBoxImage]::Error
        } else {
            [System.Windows.MessageBoxImage]::Information
        }
        [System.Windows.MessageBox]::Show(
            $Message,
            $Title,
            [System.Windows.MessageBoxButton]::OK,
            $icon
        ) | Out-Null
    } catch {
        Write-Host "$Title`: $Message"
    }
}

function Get-CurrentSystemProxy {
    $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
    $settings = Get-ItemProperty -Path $path

    if ($settings.ProxyEnable -ne 1 -or [string]::IsNullOrWhiteSpace($settings.ProxyServer)) {
        throw '未检测到已启用的 Windows 系统代理。请先启动代理软件并开启系统代理。'
    }

    $rawProxy = [string]$settings.ProxyServer
    $proxy = $rawProxy.Trim()

    # Windows may store protocol-specific proxies as:
    # http=127.0.0.1:7890;https=127.0.0.1:7890
    if ($proxy -match '=') {
        $entries = @{}
        foreach ($part in $proxy -split ';') {
            if ($part -match '^\s*([^=]+)=(.+?)\s*$') {
                $entries[$matches[1].ToLowerInvariant()] = $matches[2]
            }
        }

        if ($entries.ContainsKey('https')) {
            $proxy = $entries['https']
        } elseif ($entries.ContainsKey('http')) {
            $proxy = $entries['http']
        } else {
            throw "系统代理已开启，但没有找到 HTTP/HTTPS 代理地址：$rawProxy"
        }
    }

    if ($proxy -notmatch '^[a-z][a-z0-9+.-]*://') {
        $proxy = "http://$proxy"
    }

    try {
        $uri = [Uri]$proxy
    } catch {
        throw "系统代理地址格式无效：$proxy"
    }

    if ([string]::IsNullOrWhiteSpace($uri.Host) -or $uri.Port -le 0) {
        throw "系统代理地址格式无效：$proxy"
    }

    return $uri
}

function Test-TcpPort {
    param(
        [string]$HostName,
        [int]$Port,
        [int]$TimeoutMilliseconds = 2000
    )

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $task = $client.ConnectAsync($HostName, $Port)
        if (-not $task.Wait($TimeoutMilliseconds)) {
            return $false
        }
        return $client.Connected
    } catch {
        return $false
    } finally {
        $client.Dispose()
    }
}

function Get-CodexExecutable {
    $package = Get-AppxPackage -Name OpenAI.Codex -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $package) {
        throw '未找到已安装的 Codex Windows 应用。'
    }

    $executable = Join-Path $package.InstallLocation 'app\Codex.exe'
    if (-not (Test-Path -LiteralPath $executable)) {
        throw "找到了 Codex 软件包，但没有找到启动文件：$executable"
    }

    return $executable
}

try {
    $proxyUri = Get-CurrentSystemProxy
    if (-not (Test-TcpPort -HostName $proxyUri.Host -Port $proxyUri.Port)) {
        throw "系统代理已设置为 $($proxyUri.Host):$($proxyUri.Port)，但该端口当前无法连接。请确认代理软件已经启动。"
    }

    $codexExecutable = Get-CodexExecutable

    if ($CheckOnly) {
        Write-Output "检查成功"
        Write-Output "当前代理：$($proxyUri.AbsoluteUri.TrimEnd('/'))"
        Write-Output "Codex 路径：$codexExecutable"
        exit 0
    }

    # These variables are scoped to this launcher process and the Codex process
    # it starts. They do not modify user or machine environment variables.
    $proxyValue = $proxyUri.AbsoluteUri.TrimEnd('/')
    $env:HTTP_PROXY = $proxyValue
    $env:HTTPS_PROXY = $proxyValue
    $env:ALL_PROXY = $proxyValue
    $env:NO_PROXY = 'localhost,127.0.0.1,::1'

    Start-Process -FilePath $codexExecutable
} catch {
    Show-LauncherMessage -Message $_.Exception.Message -Type Error
    exit 1
}
