---
title: 修复 Windows 无法启动安全中心
date: 2022-10-18 11:00:57
tags:
- windows
---

最近通过`UUPDUMP`构建了`Windows 11 22H2`的安装包，估计打包的时候因为网络原因导致一些依赖损坏，在升级后无法打开`Windows`安全中心

<!--more-->

~~一般来说，你应该遇不到我这种情况，请自行谷歌其它方案~~

~~由于出现问题的时候没有截图，以下命令输出全凭记忆...~~

## 具体症状

1. 在任务栏可以看到`Windows`安全中心
2. 任务栏打开或者通过设置打开均提示“无法打开应用”，然后跳转到`Windows Store`（但是并没有这个应用）

## 解决方法

首先打开一个有管理员权限的`powershell`，输入以下命令查看安全中心状态：

```powershell
Get-AppxPackage Microsoft.SecHealthUI -AllUsers
```

在输出的最后一行，应该有一个`Status: DependencyIssue`，这说明`Microsoft.SecHealthUI`的依赖存在问题

我们可以用同样的方式查看依赖（`Microsoft.VCLibs.140`和`Microsoft.UI.Xaml.2.4`）的状态，发现其结果是`Status: Modified, NeedsRemediation`，这说明我们的依赖存在问题。最简单的解决方式就是重装！

这个地方，考虑到系统依赖损坏这种小概率事件，我们不妨做一个稍微全面一点的检查：

```powershell
# 检查并修复 Windows 完整性，我这里并没有检查出问题...
sfc /scannow
DISM /Online /Cleanup-image /Restorehealth
# 检查其它的 AppX 状态，我这里发现所有版本的 Microsoft.UI.Xaml 出现了问题
Get-AppxPackage |? Status -NE "Ok" | select PackageFamilyName
```

这个时候，我们通过一个第三方的网站：[store](store.rg-adguard.net) 搜索并下载`AppX`安装包

在搜索栏选中`PackageFamilyName`，并将上面命令输出的包名依次输入进去（有可能没有结果，过一段时间重试即可）

下载对应于你架构的`AppX`文件，比如说我是`ARM64`的，那么我需要下载有`ARM`和`ARM64`字眼的两个安装包

最后通过`Add-AppXPackage`安装：

```powershell
Add-AppxPackage xxx.AppX
```



