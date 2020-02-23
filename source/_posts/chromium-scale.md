---
title: Linux版Chromium调整DPI缩放
date: 2020-02-23 15:48:21
tags: 
- chromium
- linux
---

不得不说Linux系统在DPI缩放方面实在是不如Windows或MacOS优化的好。

我用的是KDE桌面环境，如果设置全局DPI缩放为非整数倍时，许多Qt程序的字体渲染出现问题，比如说Yakuake总是会出现条纹。所以只能调整每个应用单独的配置来实现缩放。

<!--more-->

对于Chromium（Chrome同理）而言，可以通过增加启动命令的方式来调整。

具体做法是：新建文件`~/.config/chromium-flags.conf`，并写入如下内容：

```
--force-device-scale-factor=1.2
```

1.2可以调整为具体的缩放比例。

然后重启Chromium即可。