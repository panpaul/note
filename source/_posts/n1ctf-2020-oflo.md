---
title: n1ctf 2020 oflo writeup
date: 2021-04-23 20:22:14
tags:
- ctf
---

本来去年就应该写的东西，拖到了现在...

<!--more-->

[题目链接](https://github.com/Nu1LCTF/n1ctf-2020/raw/main/RE/oflo/Attachments/8e29204565c44a402d280791f54659b1.zip)

使用`IDA`加载后发现`main`函数无法解析，但可以找到其基地址`0x400B54`，遂直接阅读汇编代码。

程序显示按常规操作进行调用过程初始化，然后读取了一个段寄存器，偏移量`0x28`

这个固定偏移量的段寄存器有什么用？在`Linux`下，操作系统并不使用`FS`段寄存器。

经过搜索后发现：

[assembly - How are the fs/gs registers used in Linux AMD64? - Stack Overflow](https://stackoverflow.com/questions/6611346/how-are-the-fs-gs-registers-used-in-linux-amd64)

[c - Why does this memory address %fs:0x28 have a random value? - Stack Overflow](https://stackoverflow.com/questions/10325713/why-does-this-memory-address-fs0x28-fs0x28-have-a-random-value)

[linux - What sets fs:0x28 (stack canary)? - Unix & Linux Stack Exchange](https://unix.stackexchange.com/questions/453749/what-sets-fs0x28-stack-canary)

`fs:0x28`被`glibc`用于存放金丝雀值

接着继续读汇编，发现指令`rep stosq`，这一条指令常见于`memset`，其以`RCX`为重复次数，`RAX`为源内容，`RDX`为目标串，写入数据，相当于`memset(RDX, RAX, RCX)`

然后看见存在一条跳转指令![flower](flower.png)

```asm
jmp     short near ptr loc_400BB1+1
```

怀疑是进行了混淆，在`0x400BB1`处按`U`取消分析，然后在`0x400BB2`处按`C`重新分析代码

![after](after.png)

然后可以把`0x400BB1`处的指令用`nop`替代掉

下面的指令很有意思`xchg rax, rax`交换了`RAX`和`RAX`寄存器的内容，相当于什么都没有做，可以当成`nop`对待（另外，好像有一本书就叫做`xchg rax, rax`）

接着一个`call`到`0x400BBF`处执行，这个`0x400BBF`用~~很复杂~~的手段干了很简单一件事：跳转到`0x400BBD`执行，所以`0x400BBC`处的是花指令了

按照同样的方法处理以下，将没用的部分`NOP`注释掉，(其实可以直接将`0x400BB7`和`0x400BBF`到`0x400BD0`一起注释掉)

![image-20210423180401249](image-20210423180401249.png)

接着看`0x400BD1`：

![image-20210423180616334](image-20210423180616334.png)

这里调用了函数`sub_4008B9`，如果返回为`-1`则退出

进入`sub_4008B9`研究，根据`x64`调用规则，`RDI`即`[RBP-210h]`为传入的第一个参数

![image-20210423180837963](image-20210423180837963.png)

我们遇到了一个可以`F5`看代码的函数啦！

![image-20210423181052717](image-20210423181052717.png)

这个函数是一个`fork and exec`的模式，但是在孩子进程中执行了`ptrace`怀疑是反调试（实际上也是这样）

关于这个`ptrace`，查阅`man`文档后得知：

> A process can initiate a trace by calling fork(2) and having the
> resulting child do a PTRACE_TRACEME, followed (typically) by an
> execve(2).  Alternatively, one process may commence tracing
> another process using PTRACE_ATTACH or PTRACE_SEIZE.
>
> While being traced, the tracee will stop each time a signal is
> delivered, even if the signal is being ignored.  (An exception is
> SIGKILL, which has its usual effect.)  The tracer will be
> notified at its next call to waitpid(2) (or one of the related
> "wait" system calls); that call will return a status value
> containing information that indicates the cause of the stop in
> the tracee.  While the tracee is stopped, the tracer can use
> various ptrace requests to inspect and modify the tracee.  The
> tracer then causes the tracee to continue, optionally ignoring
> the delivered signal (or even delivering a different signal
> instead).

`TRACEME`参数：

> PTRACE_TRACEME
> Indicate that this process is to be traced by its parent.
> A process probably shouldn't make this request if its
> parent isn't expecting to trace it.  (pid, addr, and data
> are ignored.)
>
> The PTRACE_TRACEME request is used only by the tracee; the
> remaining requests are used only by the tracer.  In the
> following requests, pid specifies the thread ID of the
> tracee to be acted on.  For requests other than
> PTRACE_ATTACH, PTRACE_SEIZE, PTRACE_INTERRUPT, and
> PTRACE_KILL, the tracee must be stopped.

这个相当于给父进程`trace`做准备

子进程没什么好说的，准备好`ptrace`环境然后执行`cat /proc/version`

接着看父进程

![image-20210423181909168](image-20210423181909168.png)

这里进入`while`循环后先指令了系统调用，查阅`man`手册获得以下信息：

> The wait() system call suspends execution of the calling thread
> until one of its children terminates.  The call wait(&wstatus) is
> equivalent to:
> waitpid(-1, &wstatus, 0);
>
> The waitpid() system call suspends execution of the calling
> thread until a child specified by pid argument has changed state.
> By default, waitpid() waits only for terminated children, but
> this behavior is modifiable via the options argument, as
> described below.
>
> -1     meaning wait for any child process

接着查阅`Linux`[源代码](https://elixir.bootlin.com/linux/v5.4.72/source/tools/include/nolibc/nolibc.h#L272)找到了`0x7f`的定义：

```c
#define WIFEXITED(status) (((status) & 0x7f) == 0)
```

这个`if`有点意思，在`wait4`执行时已经确保了子进程会退出，并且在动态调试的时候，程序执行到`wait4`时应该会直接退出(挂载了调试器)，如何才能触发退出条件？

暂时先不管，继续看代码：

循环内使用`ptrace`获取了用户寄存器的值并存入了传入的数组中，结构体的定义在`sys/user.h`中

![peekuser](peekuser.png)

![image-20210423182935080](image-20210423182935080.png)

注意到里面调用了一个函数`sub_4007D1`，跟进分析一下：

![image-20210423183613895](image-20210423183613895.png)

这个比较难分析，不清楚`RSI`，`RDX`对应的意思，所以考虑动态调试一下

回到主函数，继续分析：

![image-20210423183810372](image-20210423183810372.png)

实际执行程序时运行到了`read`处要求输入，所以`0x400BE3`处应该能正常进行跳转，所以直接当程序运行到输入时附加调试器上去运行，看一下`[rbp-210h]`处被写入了什么数据

![image-20210423184057594](image-20210423184057594.png)

发现程序将`cat /proc/version`的数据拷贝到栈上了...

至于`read`的结果，被写入到`RSI`(指向的地方)上了。(输入了`n1ctf{aaaaa}`)

![image-20210423184137953](image-20210423184137953.png)

我们通过动态调试继续跟踪程序：

![image-20210423184930312](image-20210423184930312.png)

这里执行了`mprotect`系统调用，其在`man`中的解释如下：

> mprotect, pkey_mprotect - set protection on a region of memory
>
> int mprotect(void *addr, size_t len, int prot);

第一个是地址，第二个是长度，第三个是控制选项

这里地址和长度都直接看出来了，但是控制选项比较烦，查阅`Linux`[代码](https://elixir.bootlin.com/linux/v5.4.72/source/include/uapi/asm-generic/mman-common.h#L10)得知：

```c
#define PROT_READ	0x1		/* page can be read */
#define PROT_WRITE	0x2		/* page can be written */
#define PROT_EXEC	0x4		/* page can be executed */
#define PROT_SEM	0x8		/* page may be used for atomic ops */
#define PROT_NONE	0x0		/* page can not be accessed */
#define PROT_GROWSDOWN	0x01000000	/* mprotect flag: extend change to start of growsdown vma */
#define PROT_GROWSUP	0x02000000	/* mprotect flag: extend change to end of growsup vma */
```

这里`prot`为`7`即`(111)b`即`PROT_READ | PROT_WRITE | PROT_EXEC`

也就是给`0x400000`到`0x400010`区间所在的页赋予了读、写、执行的权限。

完成上述操作后，程序一个`jmp`跳转到了一个`cmp`处，怀疑这里是一个循环结构

![image-20210423190057023](image-20210423190057023.png)

大致断定这里有一个`for(int i=0; i<=9; i++)`的循环

接着看循环体在做什么

首先有一个不认识的汇编指令`CDQE`，查询文档得知：

> The `CDQE` instruction sign-extends a DWORD (32-bit value) in the `EAX` register to a QWORD (64-bit value) in the `RAX` register.

这条指令用于对`EAX`寄存器中数据进行符号扩展

![image-20210423192321366](image-20210423192321366.png)

然后这里进行了一系列奇奇怪怪的运算，不知道在做什么(~~计算机系统基础还不够扎实~~)，经过暴力枚举测试，怀疑是在进行模`5`运算

测试代码：

```c
#include <stdio.h>
#include <stdint.h>

int main()
{
    uint64_t EAX, ECX, EDX;
    for (int i = 0; i <= 20; i++)
    {
        ECX = i;

        EDX = 0x66666667;
        EAX = i;

        EDX = ((EAX * EDX) & (0xFFFFFFFF00000000)) >> 32;
        EAX = (EAX * EDX) & (0xFFFFFFFF);

        EDX /= 2;
        EAX = i;

        EAX >>= 0x1F;
        EDX -= EAX;
        EAX = EDX;
        EAX *= 4;
        EAX += EDX;
        ECX -= EAX;
        EDX = ECX;

        EAX = EDX;
        printf("i: %d EAX:%d ECX:%d EDX:%d\n", i, EAX, ECX, EDX);
    }
    return 0;
}
```

对应的输出：

```
EAX:0 ECX:0 EDX:0
EAX:1 ECX:1 EDX:1
EAX:2 ECX:2 EDX:2
EAX:3 ECX:3 EDX:3
EAX:4 ECX:4 EDX:4
EAX:0 ECX:0 EDX:0
EAX:1 ECX:1 EDX:1
EAX:2 ECX:2 EDX:2
EAX:3 ECX:3 EDX:3
EAX:4 ECX:4 EDX:4
EAX:0 ECX:0 EDX:0
EAX:1 ECX:1 EDX:1
EAX:2 ECX:2 EDX:2
EAX:3 ECX:3 EDX:3
EAX:4 ECX:4 EDX:4
EAX:0 ECX:0 EDX:0
EAX:1 ECX:1 EDX:1
EAX:2 ECX:2 EDX:2
EAX:3 ECX:3 EDX:3
EAX:4 ECX:4 EDX:4
EAX:0 ECX:0 EDX:0
```

实际上直接反汇编`x%5`也是这个结果(不知道`IDA`的`F5`能不能正常识别...)

![image-20210423192435391](image-20210423192435391.png)

那么看到这里，这个`for`循环的内容大致研究清楚了：

![image-20210423193803510](image-20210423193803510.png)

就是把`0x400A69`处前`10`个`byte`和输入的`flag`进行异或然后存储进去，伪代码大致如下：

```c
char* base = 0x400A69;
char* input = "n1ctf{xxxxx}";
for(int i=0; i<=9; i++)
    base[i] ^= input[i%5];
```

这里与上面的`mprotect`联系起来了，这里修改了代码段的内容，如果没修改权限会抛出页错误。

完成处理后，又是熟悉的花指令：

![image-20210423194141345](image-20210423194141345.png)

同样的方法处理一下，发现跳转到`0x400CCF`处

![image-20210423194239541](image-20210423194239541.png)

继续分析，发现`0x400D04`处又有一处花指令

![image-20210423194707219](image-20210423194707219.png)

处理一下：

![image-20210423194823465](image-20210423194823465.png)

发现，如果`sub_400A69`函数处理后返回`true`那么输出`Cong`表示成功，反之直接退出，那么继续分析`sub_400A69`函数：

现在直到上面为什么要有一层循环写入`0x400A96`处的数据了，那里是为了还原这个函数的头部。所以`n1ctf`处理后恰好就是`push rbp`等过程调用约定的内容...(~~歪大误中~~)

这个函数就是一个简单的异或判断：

![image-20210423200914307](image-20210423200914307.png)

循环时从`0`到`13`，而`/proc/version`前`14`个刚好是常量：`Linux version `

解密代码：

```c
#include <stdio.h>
#include <stdint.h>

int main()
{
    int CONST[] = {0x35, 0x2d, 0x11, 0x1a, 0x49, 0x7d, 0x11, 0x14, 0x2b, 0x3b, 0x3e, 0x3d, 0x3c, 0x5f};
    char *STR = "Linux version ";
    for (int i = 0; i <= 0xD; i++)
        printf("%c", CONST[i] ^ (STR[i] + 2));
    printf("\n");
}
```

输出：`{Fam3_is_NULL}`

拼接上开头的`n1ctf`最后`flag`就是`n1ctf{Fam3_is_NULL}`

![image-20210423201533915](image-20210423201533915.png)
