# Codex 自动代理启动器--专门解决codex-unreconnecting

读取 Windows 当前系统代理，并通过该代理启动 Codex。启动器不会修改系统代理
或全局代理环境变量。

## 安装

下载并解压项目，在项目目录中运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

安装完成后，通过桌面或开始菜单中的“Codex 自动代理”快捷方式启动 Codex。

## 卸载

在项目目录中运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

## License

[MIT](LICENSE)
