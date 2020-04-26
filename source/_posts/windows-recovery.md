---
title: 重建Windows Recovery分区
date: 2020-04-26 15:24:02
tags:
- windows
- recovery
---

最近想把原来装在机械硬盘的Linux系统移动到固态硬盘中。原来把Windows装在了固态硬盘，现在如果要把Linux和Windows在一个硬盘上共存会破坏Recovery分区，于是研究了一下如何手动重建Recovery分区。

<!--more-->

先看一下原来的分区：

<img src="/images/recovery-1.webp" alt="disk partitions">

我们要重建的是最后680M的那个恢复分区。

先使用`Diskgenius`删除那个分区，然后压缩原来的C盘，然后紧邻C盘的分区划分出一个大小约为`1G`的`NTFS`分区作为恢复分区。

接着打开管理员模式下的命令提示符，执行以下命令：

```bash
REM 新建文件夹，T为刚刚划分的恢复分区
mkdir T:\Recovery\WindowsRE
REM 拷贝winre镜像，W为系统分区
xcopy /h W:\Windows\System32\Recovery\Winre.wim T:\Recovery\WindowsRE
```

然后我们要注册刚刚创建的恢复镜像

```shell
REM 注册我们创建的恢复镜像
C:\Windows\System32\Reagentc /setreimage /path T:\Recovery\WindowsRE
```

然而，实际上，这条命令执行会出错，因为我们原来有的恢复镜像的配置没有清除，导致注册镜像时会调用原来的配置（原来的分区已经被我们删了）。

编辑文件：`C:\Windows\System32\Recovery\ReAgent.xml`

用以下内容覆盖：

```xml
<?xml version='1.0' encoding='utf-8'?>

<WindowsRE version="2.0">
  <WinreBCD id=""/>
  <WinreLocation path="" id="0" offset="0"/>
  <ImageLocation path="" id="0" offset="0"/>
  <PBRImageLocation path="" id="0" offset="0"  index="0"/>
  <PBRCustomImageLocation path="" id="0" offset="0" index="0"/>
  <InstallState state="0"/>
  <OsInstallAvailable state="0"/>
  <CustomImageAvailable state="0"/>
  <WinREStaged state="0"/>
  <OemTool state="0"/>
  <ScheduledOperation state="4"/>
</WindowsRE>
```

然后重新执行命令：

```shell
C:\Windows\System32\Reagentc /setreimage /path T:\Recovery\WindowsRE
```

接着设置恢复分区的属性：

```shell
REM 打开diskpart
diskpart
REM 选中固态硬盘
select disk 0
REM 选中创建的恢复分区
select partition 5
REM 卸载分区
remove
REM 设置恢复分区的属性并且隐藏该卷
set id=de94bba4-06d1-4d40-a16a-bfd50179d6ac
gpt attributes=0x8000000000000001
REM 退出
exit
```

然后我们看一下执行的效果：

```shell
C:\Windows\System32\Reagentc /info
```

输出结果：

<img src="/images/recovery-3.webp" alt="reagentc info">

参考：[微软官方文档](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/deploy-windows-re)