---
title: 使用vscode调试RISC-V程序
date: 2020-09-19 21:11:15
tags:
- VSCode
- RISC-V
- qemu
- debugging
---

我们班`计算机组成与设计`课程选用了今年四月份发行的`RISC-V`版本教材，为了方便今后的学习，我配置了`RISC-V`运行环境，以此记录。

<!--more-->

环境：Windows 10 + WSL2

### 工具链编译

这里按照官方教程走没有任何问题

```bash
# 首先获取代码，代码体积比较大，注意科学上网
git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
# 获取编译时所需的依赖，以Ubuntu为例，其它的参考Readme
sudo apt-get install autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev
# 配置并编译toolchain，需要注意的是当前用户需要有对/opt/riscv目录的读写权限，或者也可以换成其它目录
./configure --prefix=/opt/riscv
make
```

这里我选用了手动编译，因为`Ubuntu`的软件源只自带了`Linux`的工具链，为了方便调试等操作，我需要手动编译`newlib`版本的工具。

在编译安装完成后，将`/opt/riscv/bin`加入环境变量`PATH`中

### 运行时环境准备

官方提供的运行时工具有`spike`和`proxy kernel`，但是不知道为什么，我没能启动调试器连接调试，暂时放弃该方法。

我选用了`qemu`来运行编译的程序。在`Ubuntu`下安装`qemu`

```bash
sudo apt install qemu-user
```

然后编写一个测试程序并试验一下：

```bash
➜  ~ cat hello.c
#include<stdio.h>
int main() {
    printf("Hello World\n");
    return 0;
}
➜  ~ riscv64-unknown-elf-gcc hello.c -o hello
➜  ~ qemu-riscv64 hello
Hello World
➜  ~
```

### VSCode配置

我这里`VSCode`的配置并不完美，暂时没找出解决方案（~~自己写插件好一些~~）

首先是`tasks.json`，我们需要编写两个任务，一是编译我们的代码，另一个是启动`qemu`

参考如下：

```json
{
	"version": "2.0.0",
	"tasks": [
		{ // 编译当前代码
			"type": "shell",
			"label": "C/C++(RISCV): Build active file",
			"command": "/opt/riscv/bin/riscv64-unknown-elf-g++", // 编译器的位置
			"args": [
				"-Wall", // 开启所有警告
				"-g", // 生成调试信息
				"${file}",
				"-o",
				"${workspaceFolder}/debug/${fileBasenameNoExtension}" // 我选择将可执行文件放在debug目录下
			],
			"options": {
				"cwd": "${workspaceFolder}"
			},
			"problemMatcher": [
				"$gcc"
			]
		},
		{ // 启动qemu供调试器连接
			"type": "shell",
			"label": "Run Qemu Server(RISCV)",
			"dependsOn": "C/C++(RISCV): Build active file",
			"command": "qemu-riscv64",
			"args": [
				"-g",
				"65500", // gdb端口，自己定义
				"${workspaceFolder}/debug/${fileBasenameNoExtension}"
			],
			"isBackground": true // 好像没有用
		},
		{ // 有时候qemu有可能没法退出，故编写一个任务用于强行结束qemu进程
			"type": "shell",
			"label": "Kill Qemu Server(RISCV)",
			"command": "ps -C qemu-riscv64 --no-headers | cut -d \\  -f 1 | xargs kill -9",
			"isBackground": true // 好像没有用
		}
	]
}
```

然后是`launch.json`，参考如下：

```json
{
    "version": "0.2.0",
    "configurations": [
        { // 由于在启动qemu时会造成阻塞，无法进入调试，所以剔除了preLaunchTask的选项，在执行调试前需要手动运行qemu的任务，程序的输入输出会在qemu任务中进行
            "name": "C/C++(RISCV) - Debug Active File",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/debug/${fileBasenameNoExtension}",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [],
            "externalConsole": false,
            "MIMode": "gdb",
            "setupCommands": [
                {
                    "description": "为 gdb 启用整齐打印",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ],
            "miDebuggerPath": "/opt/riscv/bin/riscv64-unknown-elf-gdb", // RISC-V工具链中的gdb
            "miDebuggerServerAddress": "localhost:65500" // 这里需要与task.json中定义的端口一致
        }
    ]
}
```

在配置完成后，以调试某数据结构作业为例测试一下：

首先是运行任务，启动`qemu`：

<img src="/images/riscv_vscode_1.webp" alt="first step">

然后按照常规操作启动调试：

<img src="/images/riscv_vscode_2.webp" alt="debugging">

其中在上图中，首先确定`1`处选用的是`RISC-V`配置，然后在`2`处确定选择的是`Run Qemu ...`，与被调试程序的交互在这里（`3`处）完成。

