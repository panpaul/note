---
title: 在Arch Linux上配置MIPS交叉编译工具链
date: 2021-06-06 15:01:52
tags:
- loongson
---

最近参加了龙芯杯，其中测试程序需要自己编译

<!-- more -->

本文已经失效，目前最新版本(12)已经修复了相关问题

我是用的是`Arch Linux`，其中在`AUR`中已经有了`cross-mips-elf-gcc`（默认大端法）和`cross-mipsel-linux-gnu-gcc`（默认小端法）工具链，但是在最新的环境下，这个软件会出现编译失败的情况

错误在于`Arch`最新的工具链添加了编译选项标识，将`format-security`问题看作`warning`处理，目前已经有人报告了[问题](https://bugs.archlinux.org/task/70701)，但是看起来官方不认为这是问题

所以我们可以通过手动修改`PKGBUILD`添加编译指令：

```bash
# 编译前修改PKGBUILD
yay --editmenu -S cross-mips-elf-gcc
# cross-mipsel-linux-gnu-gcc同理
```

然后在`./configure`前面插入两行：

```bash
export CFLAGS="${CFLAGS} -Wno-error=format-security -Wformat-security"
export CXXFLAGS="${CXXFLAGS} -Wno-error=format-security -Wformat-security"
```

接着往`configure`下面的参数中新加入一条：`--enable-build-format-warnings`

保存后即可正常编译`MIPS`工具链
