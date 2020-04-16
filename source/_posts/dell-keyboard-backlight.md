---
title: (不完美)解决Dell笔记本键盘灯无法打开问题
date: 2020-04-16 18:16:45
tags:
- dell
- keyboard
- backlight
---

最近给笔记本重装了`Windows`系统，然而发现`Fn+F10`组合键无法开启键盘灯。

<!--more-->

具体情况是在`Alienware Command Center`中可以看见`Fn+F10`的确触发了键盘灯开关，而实际上灯没有亮。

在`Dell`官网上搜索了一大圈，发现这样的问题同样存在，而且官方的解决方案不是没用，就是过时了。

不过，想起来以前双系统在`Linux`下曾经开启过飞行模式，重启后进入`Windows`发现`Wifi`网卡被禁用的状态同步到了`Windows`下。所以猜测，可以通过在`Linux`下开启键盘灯解决在`Windows`下无法开启键盘灯的问题。(`Windows`提供的诊断手段少，而`Linux`下设备都被映射到了目录下，方便调试诊断)

于是乎，根据`Arch Wiki`中[Keyboard Backlight](https://wiki.archlinux.org/index.php/Keyboard_backlight)的提示，发现在`/sys/class/leds/`目录下存在`dell::kbd_backlight`。稍微修改一下wiki的指令，执行：

```
echo 1 | sudo tee /sys/class/leds/dell::kbd_backlight/brightness
```

发现键盘灯成功被点亮了！

重启切换到`Windows`下，发现`Fn+F10`复活了。

已知的问题：

进入`Alienware Command Center`设置灯的样式，当选中这两个效果：`morph` 和`pulse`时无法点亮键盘。