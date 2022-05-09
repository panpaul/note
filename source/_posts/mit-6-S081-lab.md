---
title: MIT6.S081操作系统实验解答
date: 2021-02-04 16:34:14
tags:
- 6.S081
- Operating System
- RISC-V
---

最近在自学MIT的操作系统课程，本文记录一下我的课后lab解答。

<!--more-->

> 2022前来考古 :)
>
> 由于最近在复习操作系统，遂重新基于`2021 Fall`版实验重做了一遍，顺便补全原来`Lab Lazy`之后的内容
>
> 为了区分相关内容，我将`2021 Fall`不一样的实验标记出来了

## Lab Utilities

第一个lab旨在让我了解一下`xv6`系统的框架和调用系统调用的方式。

### Boot xv6

首先是获取并运行`xv6`系统，这里没什么好说的，依葫芦画瓢，把指令敲进去就好了

```shell
git clone git://g.csail.mit.edu/xv6-labs-2020
cd xv6-labs-2020
git checkout util

make qemu
```

### sleep

这里要求写一个`sleep`程序，其中第一个参数是休眠的时间

考虑到是第一个编程实验，题目中给出了许多`hints`，按照要求一步步做即可。我们的程序只需要处理一下输入然后调用系统调用`sleep`即可

```c
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    if (argc <= 1)
    {
        fprintf(2, "usage: sleep time\n");
        exit(1);
    }

    int tick = atoi(argv[1]);
    sleep(tick);

    exit(0);
}
```

### pingpong

这题引入了一个概念——管道，具体在`xv6`系统中如何使用可以参考[`xv6` book](https://pdos.csail.mit.edu/6.828/2020/xv6/book-riscv-rev1.pdf)中1.3节`Pipes`

```c
#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    int p[2];
    pipe(p);

    if (fork() == 0)
    { // child
        char buf[2];
        read(p[0], buf, 1);
        close(p[0]);

        printf("%d: received ping\n", getpid());

        write(p[1], buf, 1);
        close(p[1]);
    }
    else
    { // parent
        char buf[2] = "p"; // 'p' '\0'

        write(p[1], buf, 1);
        close(p[1]);
        wait(0);

        read(p[0], buf, 1);
        close(p[0]);
        printf("%d: received pong\n", getpid());
    }

    exit(0);
}
```

其中可能需要注意的细节就是`read`函数的阻塞情况：

> a read on a pipe waits for either data to be written or for all file descriptors
> referring to the write end to be closed

以上述代码为例，当`read(p[0], buf, 1)`被调用时，如果，如果`p[0]`尚未被`close`，则这里的`read`会阻塞直到父进程中`write`完成写入

### primes

这题要求我们使用`pipe`实现素数筛

```c
#include "kernel/types.h"
#include "user/user.h"

void prime(int p[2])
{
    int num, next;
    close(p[1]); // 及时释放
    if (!read(p[0], &num, 4)) // 读取输入的数
    {
        close(p[0]);
        exit(1);
    }

    printf("prime %d\n", num);

    int np[2];
    pipe(np);
    if (fork() == 0)
    {
        // child
        prime(np);
    }
    else
    {
        // parent
        close(np[0]);
        while (read(p[0], &next, 4))
            if (next % num)
                write(np[1], &next, 4);
        close(np[1]);
        wait(0);
    }

    close(p[0]);
}

int main(int argc, char *argv[])
{
    int p[2];
    pipe(p);
    if (fork() == 0)
    {
        // child
        prime(p);
    }
    else
    {
        //parent
        close(p[0]);
        for (int i = 2; i <= 35; i++)
            write(p[1], &i, 4);
        close(p[1]);
        wait(0);
    }
    exit(0);
}
```

在我的实现中，每一次调用`prime()`相当于是一层筛子。`prime`在工作时首先把第一个数输出，然后遍历符合需要的数并把数字传送到下一层筛子中。这里每一层筛子的数采用`pipe`传递，所以使用一个`fork`，父进程筛选符合的数，子进程开启下一层筛子。

有一点细节需要注意的是，在传递`int`时，`read/write`的长度是`4`

### find

这个程序旨在让我们了解一下`xv6`的文件系统机制

如果时间充裕可以直接阅读`kernel`中的代码和`xv6 book`了解文件系统的使用，偷懒的画直接“抄”`user/ls.c`即可

```c
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

#define NULL 0

int mycmp(char *src, char *str)
{ // 文件名比较——比较src中最后一个'/'后面的内容是否和str相等
    int n = strlen(src), m = strlen(str);
    if (n < m)
        return -1;
    char *pos = src;
    while (*src && n >= m) // 寻找最后一个'/'
    {
        if (*src == '/')
            pos = ++src, n--;
        src++;
        n--;
    }
    return strcmp(pos, str);
}

void find(char *path, char *filename)
{ // 一个递归查找
    int fd;
    struct stat st;
    struct dirent de;
    char buf[512], *p;

    if ((fd = open(path, 0)) < 0)
    {
        fprintf(2, "find: cannot open %s\n", path);
        return;
    }

    if (fstat(fd, &st) < 0)
    {
        fprintf(2, "ls: cannot stat %s\n", path);
        close(fd);
        return;
    }

    switch (st.type)
    {
    case T_FILE:
        if (filename == NULL)
            printf("%s\n", path);
        else if (mycmp(path, filename) == 0)
            printf("%s\n", path);
        break;

    case T_DIR:
        if (strlen(path) + 1 + DIRSIZ + 1 > sizeof buf)
        {
            printf("ls: path too long\n");
            break;
        }
        strcpy(buf, path);

        /* 根据情况向buf后添加'/'防止出现'abc//efg'的情况 */
        p = buf + strlen(buf) - 1;
        if (*p != '/')
            *++p = '/';
        p++;

        while (read(fd, &de, sizeof(de)) == sizeof(de))
        {
            if (de.inum == 0)
                continue;

            memmove(p, de.name, DIRSIZ); // 把文件(夹)名复制到buf后

            if (strcmp(de.name, ".") == 0 || strcmp(de.name, "..") == 0) // 防止无限递归
                continue;

            p[DIRSIZ] = 0; // 防止超长

            find(buf, filename);
        }
    }
    close(fd);
}

int main(int argc, char *argv[])
{
    if (argc <= 1)
        find(".", NULL);
    else if (argc == 2)
        find(argv[1], NULL);
    else if (argc == 3)
        find(argv[1], argv[2]);
    else
        fprintf(2, "Usage: find path filename\n"), exit(1);

    exit(0);
}
```

### xargs

这个程序涉及字符串处理和对例程[`forkexec`](https://pdos.csail.mit.edu/6.828/2020/lec/l-overview/forkexec.c)的理解

```c
#include "kernel/types.h"
#include "kernel/param.h"
#include "user/user.h"

#define NULL 0

char *readline()
{ // 读取一行(\n分界) 对read的简单包装
    char buf[512], c;
    int pos = -1;
    while (read(0, &c, sizeof(char)) == sizeof(char))
    {
        if (c == '\n')
            break;
        else
            buf[++pos] = c;
    }

    if (pos == -1)
        return NULL;

    char *p = malloc((pos + 1) * sizeof(char));
    memmove(p, buf, pos + 1);
    return p;
}

int main(int argc, char *argv[])
{
    if (argc <= 1)
    {
        fprintf(2, "Usage: xargs command args... \n");
        exit(1);
    }

    char *arg[MAXARG];
    arg[0] = argv[1];
    for (int i = 2; i < argc; i++) // 准备被调用程序的参数
        arg[i - 1] = argv[i];

    char *r;
    while ((r = readline()) != NULL)
    {
        arg[argc - 1] = r;
        if (fork() == 0)
        { // child
            exec(argv[1], arg);
            fprintf(2, "exec failed!\n");
            exit(1);
        }
        else
            wait(0); // 处理完一行前阻塞
    }
    exit(0);
}
```

## Lab System Calls

这一个lab要求给`xv6`系统添加两个系统调用：`trace`和`sysinfo`。帮助我们了解`xv6`内核系统调用的实现方式

### System call tracing

这题要求我们实现一个名为`trace`的系统调用，到调用后将记录这个进程以及`fork`后进程的所有系统调用

按照`hints`一步一步走，首先在定义`trace`系统调用

按照`xv6 book`4.3节所述，在调用系统调用时，对应的系统调用号放在`a7`寄存器，然后按照`RISC-V`调用约定使用`ecall`进入内核特权，在这里`xv6`使用`user/usys.pl`生成对应的汇编代码，我们在这里加入`trace`的生成：

```perl
# --snip--
sub entry {
    my $name = shift;
    print ".global $name\n";
    print "${name}:\n";
    print " li a7, SYS_${name}\n";
    print " ecall\n";
    print " ret\n";
}
# --snip--
entry("trace"); # 添加trace
```

这里`SYS_trace`的定义体现在`kernel/syscall.h`中，在`kernel/syscall.h`中添加系统调用编号`#define SYS_trace 22`

然后是补充`C`语言的函数定义，在`user/user.h`中加入一行`int trace(int mask);`函数声明

接着在`kernel/sysproc.c`中编写这个系统调用的内容：

```c
uint64 sys_trace(void)
{
  int mask;
  if (argint(0, &mask) < 0)
    return -1;

  myproc()->trace_mask = mask;
  return 0;
}
```

这里`trace_mask`是我自己添加的一个属性，用来记录要`trace`的系统调用号

现在问题来了，如何按需打印系统调用的过程？我们不妨关注一下`kernel/syscall.c`中的实现：

首先把`sys_trace`添加进系统调用中：

```c
extern uint64 sys_trace(void);

static uint64 (*syscalls[])(void) = {
    // ...
    [SYS_trace] sys_trace,
}
```

然后修改`syscall`的调用处理函数

```c
static char *syscall_names[] = {
    [SYS_fork] "fork",
    [SYS_exit] "exit",
    [SYS_wait] "wait",
    [SYS_pipe] "pipe",
    [SYS_read] "read",
    [SYS_kill] "kill",
    [SYS_exec] "exec",
    [SYS_fstat] "fstat",
    [SYS_chdir] "chdir",
    [SYS_dup] "dup",
    [SYS_getpid] "getpid",
    [SYS_sbrk] "sbrk",
    [SYS_sleep] "sleep",
    [SYS_uptime] "uptime",
    [SYS_open] "open",
    [SYS_write] "write",
    [SYS_mknod] "mknod",
    [SYS_unlink] "unlink",
    [SYS_link] "link",
    [SYS_mkdir] "mkdir",
    [SYS_close] "close",
    [SYS_trace] "trace",
    [SYS_sysinfo] "sysinfo",
}; // 系统调用号与名字的关系

void syscall(void)
{
  int num;
  struct proc *p = myproc();

  num = p->trapframe->a7;
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
  {
    p->trapframe->a0 = syscalls[num]();
    // 添加以下两行
    if (p->trace_mask & (1 << num)) // 判断是否是要打印的调用
      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);
  }
  else
  {
    printf("%d %s: unknown sys call %d\n", p->pid, p->name, num);
    p->trapframe->a0 = -1;
  }
}
```

接着，为了能够在`fork`时传递`trace_mask`标记，修改`kernel/proc.c`

```c
int
fork(void)
{
// --snip--
  acquire(&np->lock);
  np->state = RUNNABLE;
  np->trace_mask = p->trace_mask;
  release(&np->lock);

  return pid;
}
```

最后一点细节，在`kernel/proc.c`中`freeproc`函数中添加一行：`p->trace_mask = 0;`

### Sysinfo

这题要求获取并返回系统内的状态：剩余内存和`UNUSED`进程数量

先按照上一题的模式构建一个系统调用的原型

然后根据提示在`kernel/kalloc.c`中添加一个辅助函数`get_free_mem`

```c
uint64 get_free_mem(void)
{
  struct run *r;
  uint64 pages = 0; // 记录空闲页数

  acquire(&kmem.lock);
  r = kmem.freelist;
  while (r)
  {
    pages++;
    r = r->next;
  }
  release(&kmem.lock);

  return (pages << 12); // Book P29
  // better one: return (pages << PGSHIFT);
}
```

整个流程可以参考`kalloc.c`中的`kalloc`函数：上锁 -> 获取空闲链表(`kmem.freelist`) -> 解锁

我们可以获取到空闲的页数，但是页大小是多少？这里在`xv6 book`中3.1节中阐述了`xv6`页表的设计：

`VA`总共有`39`位，其中高`27`位对应于`PTE`用于查找`PPN`，剩下的`12`位表示页内偏移，也就是一个页的大小

接着关注`UNUSED`的进程，在`kernel/proc.c`中添加辅助函数`get_unused_proc`

```c
uint64
get_proc_num(void)
{
  struct proc *p;
  uint64 cnt = 0;

  for (p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if (p->state != UNUSED)
      cnt++;
    release(&p->lock);
  }

  return cnt;
}
```

最后添加实际的系统调用函数

```c
#include "sysinfo.h"
uint64 sys_sysinfo(void)
{
  uint64 addr;
  if (argaddr(0, &addr) < 0)
    return -1;

  struct proc *p = myproc();
  struct sysinfo info;

  info.freemem = get_free_mem();
  info.nproc = get_proc_num();

  if (copyout(p->pagetable, addr, (char *)&info, sizeof(info)) < 0) // 把内核空间的info拷贝到对应程序的虚拟地址空间上
    return -1;
  return 0;
}
```

## Lab Page Tables

### [2021 Fall] Speed up system calls

这里要求我们引入一个可以和内核共享的区域来提升用户空间和内核的信息交互

按照提示，我们在进程创建时映射一个新的页`USYSCALL`并且将该页内容填充为`struct usyscall`

首先修改`proc.h`，在进程结构中添加`usyscall`

```c
struct proc {
  // --snip--
  struct usyscall *usyscall;   // user syscall table
};
```

然后在进程创建的时候填充这个字段

```c
static struct proc*
allocproc(void)
{
  // --snip--
  // Allocate usyscall struct
  if((p->usyscall = (struct usyscall *)kalloc()) == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }
  p->usyscall->pid = p->pid;
  // 在proc_pagetable之前分配，我们将在proc_pagetable中使用到p->usyscall的地址

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  // --snip--
}
```

接着修改`proc_pagetable`：

```c
pagetable_t
proc_pagetable(struct proc *p)
{
  // --snip--
  // map the USYSCALL page to speed up syscall.
  if (mappages(pagetable, USYSCALL, PGSIZE,
               (uint64)(p->usyscall), PTE_R | PTE_U) < 0){
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return 0;
}
```

最后，有始有终，销毁进程的时候清理分配的空间：

```c
static void
freeproc(struct proc *p)
{
  // --snip--
  if(p->usyscall)
    kfree((void *)p->usyscall);
  // --snip--
}

void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  // --snip--
  uvmunmap(pagetable, USYSCALL, 1, 0);
  uvmfree(pagetable, sz);
}
```



### Print a page table

第二题是打印`pagetable`的信息，这里按照提示参考`freewalk`的代码。

```c
// 写的比较丑......
// 这里嵌套了三成for打印三级页表的内容
void vmprint(pagetable_t pagetable)
{
	printf("page table %p\n", pagetable);
	for (int i = 0; i < 512; i++) // 2^9 = 512 PTEs
	{
		pte_t pte = pagetable[i];
		if (pte & PTE_V) // 页表有效
		{
			uint64 pa = PTE2PA(pte);
			printf("..%d: pte %p pa %p\n", i, pte, pa);
			for (int j = 0; j < 512; j++)
			{
				pte_t pte2 = ((pagetable_t)pa)[j];
				if (pte2 & PTE_V) // 页表有效
				{
					uint64 pa2 = PTE2PA(pte2);
					printf(".. ..%d: pte %p pa %p\n", j, pte2, pa2);
					for (int k = 0; k < 512; k++)
					{
						pte_t pte3 = ((pagetable_t)pa2)[k];
						if (pte3 & PTE_V) // 页表有效
						{
							uint64 pa3 = PTE2PA(pte3);
							printf(".. .. ..%d: pte %p pa %p\n", k, pte3, pa3);
						}
					}
				}
			}
		}
	}
}

```

### [2021 Fall] Detecting which pages have been accessed

这个难度感觉比原来的大大降低了

首先查询`RISC-V`手册可知`PTE_A`标记为第`6`位（从`0`开始），于是可以定义`#define PTE_A (1L << 6)`，然后就是编写系统调用：获取用户传入的参数、遍历范围内的所有页并获取`PTE`（这里由于使用了`walk`获取对应的`PTE`，而`walk`会自动对齐到页，所以可以不用手动对齐）、然后判断是否存在`PTE_A`标志、最后将结果拷贝回用户空间

```c
int
sys_pgaccess(void)
{
  uint64 buf;
  int sz;
  uint64 abits;

  if(argaddr(0, &buf) < 0)
    return -1;
  if(argint(1, &sz) < 0)
    return -1;
  if(argaddr(2, &abits) < 0)
    return -1;

  struct proc *p = myproc();

  uint64 bits = 0;
  for(uint64 va = buf, cnt = 0; va < buf + sz * PGSIZE; va += PGSIZE, ++cnt)
  {
    // walk will round up to page boundary
    pte_t *pte = walk(p->pagetable, va, 0);
    // printf("pte %x -> %x\n", va, *pte);
    if (*pte & PTE_A)
    {
      bits |= 1 << cnt;
      *pte &= ~PTE_A;
    }
  }

  copyout(p->pagetable, abits, (char *)&bits, sizeof(bits));

  return 0;
}
```



### A kernel page table per process

顾名思义，这题要求我们给每个进程添加一个内核页表

在`kernel/proc.h`中添加以下内容：

```c
struct proc{
    // -- snip --
    pagetable_t kpagetable;
};
```

然后修改`kernel/vm.c`中的内容，这里把原来`kvminit`中的内容抽取出来放到新函数`kvmmake`中，这样方便`allocproc`复用代码

```c
/* 
 * 原来的kvmmap直接修改了kernel_pagetable，这里写一个新的kvmmap允许指定要映射VA-PA关系的页表
 */
void kvmmap2(pagetable_t pt, uint64 va, uint64 pa, uint64 sz, int perm)
{
    if(mappages(pt, va, sz, pa, perm) != 0)
        panic("kvmmap2");
}

/*
 * 创建一个页表并映射KERNBASE及更低地址的内容(外设)
 */
pagetable_t kvmmake(){
    pagetable_t pt = (pagetable_t) kalloc();
    memset(pt, 0, PGSIZE);

    // uart registers
    kvmmap2(pt, UART0, UART0, PGSIZE, PTE_R | PTE_W);

    // virtio mmio disk interface
    kvmmap2(pt, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);

    // CLINT
    kvmmap2(pt, CLINT, CLINT, 0x10000, PTE_R | PTE_W);

    // PLIC
    kvmmap2(pt, PLIC, PLIC, 0x400000, PTE_R | PTE_W);

    // map kernel text executable and read-only.
    kvmmap2(pt, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);

    // map kernel data and the physical RAM we'll make use of.
    kvmmap2(pt, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);

    // map the trampoline for trap entry/exit to
    // the highest virtual address in the kernel.
    kvmmap2(pt, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);

    return pt;
}

/*
 * create a direct-map page table for the kernel.
 */
void
kvminit()
{
  kernel_pagetable = kvmmake();
}
```

然后修改`kernel/proc.c`中`allocproc`的内容，在分配新进程空间时创建内核页表副本

```c
// 首先按照提示抽取procinit中的内容,将分配栈相关内容移动到allocproc中(初始化到进程所拥有的内核页表副本)
void
procinit(void)
{
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
  for(p = proc; p < &proc[NPROC]; p++) {
      initlock(&p->lock, "proc");
  }
  kvminithart();
}

// 然后将原来分配栈的代码移动到allocproc中
static struct proc*
allocproc(void)
{
// -- snip --
found:
// -- snip --

  // 创建该进程的内核页表
  p->kpagetable = kvmmake();
  if(p->kpagetable == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }
  // 然后在该进程内核页表中为该进程分配内核栈
  char *pa = kalloc();
  if(pa == 0)
    panic("allocproc: alloc kstack");
  uint64 va = KSTACK((int) (p - proc));
  kvmmap2(p->kpagetable, va, (uint64)pa, PGSIZE, PTE_R | PTE_W); // 栈在内核页表副本中映射
  p->kstack = va;
    
// -- snip --

  return p;
}
```

接着修改`kernel/proc.c`中`scheduler`内容，在切换运行进程时切换到内核页表副本：

```c
void
scheduler(void)
{
// -- snip --
        // 切换到进程的内核页表副本
        w_satp(MAKE_SATP(p->kpagetable));
        sfence_vma();

        swtch(&c->context, &p->context);

        // 切换回全局的内核页表
        kvminithart();
// -- snip --
#if !defined (LAB_FS)
    if(found == 0) {
      intr_on();
      kvminithart(); // 按照第五点提示,没有进程运行时要切换回全局内核页表。但是感觉这里实现有一些问题,没有必要每次执行切换操作...
      asm volatile("wfi");
// -- snip --
}
```

最后剩下来的是释放`kpagetable`，我们参考`proc_freepagetable`的实现，首先是`unmap`然后`freewalk`相应的`pagetable`。在`proc_freepagetable`中`unmap`的实现逻辑比较复杂，而对于内核页表副本而言，映射的关系是已知的，所以我们可以直接硬编码。

先修改`kernel/vm.c`

```c
// 仿照uvmunmap写一个kvmunmap,唯一的区别是不用回收物理内存
void kvmunmap(pagetable_t pagetable, uint64 va, uint64 size){
    uint64 a;
    pte_t *pte;

    if((va % PGSIZE) != 0)
        panic("kvmunmap: not aligned");

    for(a = va; a < va + size; a += PGSIZE){
        if((pte = walk(pagetable, a, 0)) == 0)
            panic("kvmunmap: walk");
        if((*pte & PTE_V) == 0)
            panic("kvmunmap: not mapped");
        if(PTE_FLAGS(*pte) == PTE_V)
            panic("kvmunmap: not a leaf");

        // 不需要销毁物理内存
        //uint64 pa = PTE2PA(*pte);
        //kfree((void*)pa);
        
        *pte = 0;
    }
}
```

然后修改`kernel/proc.c`

```c
extern char etext[]; // 引用extext

// 销毁内核页表副本
void proc_freekpagetable(pagetable_t pt, uint64 kstack)
{
    // 怎么分配的怎么销毁
    kvmunmap(pt, UART0, PGSIZE);
    kvmunmap(pt, VIRTIO0, PGSIZE);
    kvmunmap(pt, CLINT, 0x10000);
    kvmunmap(pt, PLIC, 0x400000);
    kvmunmap(pt, KERNBASE, (uint64)etext-KERNBASE);
    kvmunmap(pt, (uint64)etext, PHYSTOP-(uint64)etext);
    kvmunmap(pt, TRAMPOLINE, PGSIZE);
    freewalk(pt);
}

// 最后在freeproc中添加销毁kpagetable的代码
static void
freeproc(struct proc *p)
{
// --snip--
  if(p->kstack){ // 内核栈空间需要手动回收 仿照uvmunmap编写即可
    pte_t *pte = walk(p->kpagetable, p->kstack, 0);
    if(pte == 0)
      panic("kstackunmap: walk");
    uint64 pa = PTE2PA(*pte);
    kfree((void*)pa);
    *pte = 0;
    p->kstack = 0;
  }
  if(p->kpagetable) // 回收页表
    proc_freekpagetable(p->kpagetable, p->kstack);
  p->kpagetable = 0;
// --snip--
}
```

最后一处细节，（跑`make qemu`时`sh`都没看见就`panic`了...），按照报错内容`panic: kvmpa`找到`kernel/vm.c`中`kvmpa`函数，发现这里`PTE`是来自于全局内核页表，而该函数依赖于每个进程自己的内核栈，所以这里肯定会出错。全局搜索`kernel_pagetable`发现只有这里引用了，所以修改这一处即可。

```c
#include "spinlock.h"
#include "proc.h"
// --snip--
uint64
kvmpa(uint64 va)
{
// --snip--
  pte = walk(myproc()->kpagetable, va, 0);
// --snip--
}
```

后来看了`lab`的讲解，实际上`KERNBASE`以下的内容可以不用重新分配页表，共享内核的那一份即可。

### Simplify `copyin/copyinstr`

这一题将程序的页表直接映射到内核页表中，这样在进行系统调用的时候不需要进行额外的地址转换。由于程序的虚拟地址从`0`开始，所以在内核的页表中，程序映射的范围只能是`0-0xC000000`也就是要求程序的虚拟地址小于原内核页表中第一页的地址。

首先我们先写一个辅助函数把程序的页表复制到内核页表中:

```c
void uvm2kvm(pagetable_t u, pagetable_t k, uint64 from, uint64 to)
{
  // u: 程序的页表 k: 内核的页表 from: 开始复制的地址 to: 结束复制的地址
  // 要做的事与uvmcopy类似,但是并不需要复制实际的内容,只需要有相同的到PA的映射即可(即复制指针)
  if (from > PLIC) // Don't forget about the above-mentioned PLIC limit.
    panic("uvm2kvm: out of range");
  from = PGROUNDDOWN(from); // 对齐页面
  for (uint64 i = from; i < to; i += PGSIZE)
  {
    pte_t *pte_u = walk(u, i, 0); // 在进程页表中找到PTE
    pte_t *pte_k = walk(k, i, 1); // 在内核页表分配相应的内容
    if (pte_k == 0)
      panic("uvm2kvm: allocate for kernel page table failed");
    *pte_k = *pte_u;  // 把进程页表中的内容在内核页表中做一份拷贝
    *pte_k &= ~PTE_U; // A page with PTE_U set cannot be accessed in kernel mode.
  }
}
```

然后按照提示，在对应的地方插入页表拷贝的操作。

先是`userinit`

```c
void
userinit(void)
{
// --snip--
  uvminit(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // 复制到内核页表中
  uvm2kvm(p->pagetable, p->kpagetable, 0, p->sz);
// --snip--
}
```

然后是`sbrk`系统调用对应的`growproc`

```c
int
growproc(int n)
{
// --snip--
  if(n > 0){
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
      return -1;
    }
    // 将新分配的页表同步到内核页表中
    uvm2kvm(p->pagetable, p->kpagetable, sz - n, sz);
// --snip--
```

然后是`fork`操作

```c
  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // 对孩子进程的页表进行操作
  uvm2kvm(np->pagetable, np->kpagetable, 0, np->sz);
```

最后是在`kernel/exec.c`中在`return argc;`前面插入拷贝页表的代码：`uvm2kvm(p->pagetable, p->kpagetable, 0, p->sz);`

完成上述修改后就可以把`copyin`和`copyinstr`修改为调用`copyin_new`和`copyinstr_new`了。

但是在上一题中我给自己留了一个坑，在释放页表的时候只释放了一开始分配的，而在本题条件下会导致内存泄漏。于是仿照`freewalker`写一个不释放物理内存的销毁函数然后在`proc_freekpagetable`中调用。

```c
void kfreewalk(pagetable_t pagetable,int depth)
{
  if(depth > 3)
    return;
  // there are 2^9 = 512 PTEs in a page table.
  for (int i = 0; i < 512; i++)
  {
    pte_t pte = pagetable[i];
    if (pte & PTE_V)
    {
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
      kfreewalk((pagetable_t)child, depth + 1);
      pagetable[i] = 0;
    }
  }
  kfree((void *)pagetable);
}
```



## Lab Traps

### Backtrace

这题要求我们实现一个`backtrace`功能，总体思路是从栈上递归获取返回地址并打印出来，其中栈大小控制在一个页内，所以可以确定遍历的范围：

```c
void backtrace()
{
  printf("backtrace:\n");

  uint64 fp = r_fp();
  uint64 bottom = PGROUNDUP(fp); // 获取栈底地址

  while (fp < bottom)
  {
    uint64 *p = (uint64 *)(fp - 8);
    uint64 *next = (uint64 *)(fp - 16);

    printf("%p\n", *p);

    fp = *next;
  }
}
```

### Alarm

这题要求我们实现`alarm`功能，其中约定触发后的函数通过`sigreturn`返回，这样便于我们还原状态。

首先是按照老方法添加两个系统调用：`sigalarm`和`sigreturn`

然后修改`proc.h`，添加我们需要的一些变量：

```c
int alarm_en;                 // 使能标志位
int alarm_interval;           // 周期
uint64 alarm_handler;         // 回调地址
int alarm_counter;            // 计数器
struct trapframe *alarm_save; // 保存寄存器
```

我这里偷懒，直接使用`trapframe`结构体来保存寄存器内容

接着修改`proc.c`，在`allocproc`和`freeproc`中添加代码初始化、销毁上述变量：

```c
static struct proc*
allocproc(void)
{
  // --snip--
found:
  p->pid = allocpid();

  p->alarm_en = 0;
  p->alarm_handler = 0;
  p->alarm_interval = 0;
  p->alarm_counter = 0;
  if ((p->alarm_save = (struct trapframe *)kalloc()) == 0) // 分配内存!
  {
    release(&p->lock);
    return 0;
  }
  // --snip--
}

static void
freeproc(struct proc *p)
{
  // 仿照trapframe的销毁步骤销毁alarm_save
  if (p->alarm_save)
    kfree((void *)p->alarm_save);
  p->alarm_save = 0;

  p->alarm_en = 0;
  p->alarm_interval = 0;
  p->alarm_counter = 0;
  p->alarm_handler = 0;
}
```

然后根据提示，在每个`CPU`周期到来时会触发`usertrap`函数，所以我们在这里面添加`alarm`相关的处理内容：

```c
// give up the CPU if this is a timer interrupt.
if (which_dev == 2)
{
  if (p->alarm_interval > 0 && p->alarm_en)
  {
    p->alarm_counter++;
    if (p->alarm_counter == p->alarm_interval)
    {
      p->alarm_en = 0;      // 停止alarm
      p->alarm_counter = 0; // 计数器清空
      memmove(p->alarm_save,
              p->trapframe,
              sizeof(struct trapframe));    // 备份寄存器
      p->trapframe->epc = p->alarm_handler; // 修改PC,跳转到handler执行
    }
  }
  yield();
}
```

最后给系统调用添加相关内容：

对于`sys_sigalarm`只用获取传递的参数然后开启`alarm`即可：

```c
uint64 sys_sigalarm()
{
  int interval;
  uint64 handler;
  if (argint(0, &interval) < 0)
    return -1;
  if (argaddr(1, &handler) < 0)
    return -1;

  myproc()->alarm_interval = interval;
  myproc()->alarm_handler = handler;
  myproc()->alarm_en = 1;

  return 0;
}
```

而对于`sys_sigreturn`，要在这里还原寄存器：

```c
uint64 sys_sigreturn()
{
  memmove(myproc()->trapframe,
          myproc()->alarm_save,
          sizeof(struct trapframe)); // 还原寄存器
  myproc()->alarm_en = 1;            // alarm使能
  return 0;
}
```

## Lab Lazy

这一个实验是要给`xv6`系统的`sbrk`添加延迟分配内存的功能。

首先修改`sys_sbrk`：

```c
uint64
sys_sbrk(void)
{
  int addr;
  int n;

  if (argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  if (n < 0) // n < 0 时回收内存
    uvmdealloc(myproc()->pagetable, addr, addr + n);
  myproc()->sz += n; // 如果n > 0就只记录一下
  return addr;
}
```

然后，由于修改后的`sbrk`并未真正分配内存，在程序运行时如果访问了这部分的内存会产生`page fault`，我们可以在`usertrap`中去处理这些问题：

这一部分可以参考课程上老师给出的代码，稍加修改（边界条件的判定：`r_scause`、地址范围）

```c
else if (r_scause() == 13 || r_scause() == 15)
{
  // Page Fault
  uint64 va = r_stval();
  //printf("page fault: %p\n", va);
  if (va >= p->sz || va <= PGROUNDDOWN(p->trapframe->sp)) // 确保出现page fault的地址在分配的范围内，在栈空间内
    p->killed = 1;
  else
  {
    char *mem = kalloc();
    if (mem == 0)
      p->killed = 1;
    else
    {
      memset(mem, 0, PGSIZE);
      va = PGROUNDDOWN(va);
      if (mappages(p->pagetable, va, PGSIZE, (uint64)mem, PTE_W | PTE_X | PTE_R | PTE_U) != 0)
      {
        kfree(mem);
        p->killed = 1;
      }
    }
  }
}
```

接着，继续完善程序：根据提示，程序有可能使用尚未分配的地址去调用如`read`、`write`等系统调用。而进入`sys_read`之后，代码在内核空间中执行，如果出现页错误不会到`usertrap`中执行，所以我们需要修改代码使得我们的系统能判断并分配这些尚未分配的内存：

首先分析一下内核的代码：从用户空间传入地址可以通过`argaddr`函数读取，先查找一下`argaddr`的引用：

```
argaddr <- argstr
        <- sys_read
        <- sys_write
        <- sys_fstat
        <- sys_exec
        <- sys_pipe
        <- sys_wait
```

接着我们逐个研究这些函数，追踪传入的地址经过了哪些函数：

```
sys_wait -> copyout
sys_pipe -> copyout
sys_exec -> fetchaddr -> copyin
         -> exec -> loadseg
sys_fstat -> filestat -> copyout
sys_write -> ... -> copyin
sys_read -> ... -> copyout
argstr -> fetchstr -> copyinstr

walk <- walkaddr <- copyin
                 <- copyout
                 <- copyinstr
                 <- loadseg
```

可以发现我们传入的地址最后都传递给了`walkaddr`函数处理。

我们现在就要修改`walk`或`walkaddr`函数，像`usertrap`中处理一样判断是否需要分配内存。

这里我选择了修改`walkaddr`函数：

```c
if (pte == 0 || (*pte & PTE_V) == 0)
{
  // not allocated
  if (va >= myproc()->sz || va <= PGROUNDDOWN(myproc()->trapframe->sp))
    return 0;
  char *mem = kalloc();
  if (mem == 0)
    return 0;
  else
  {
    memset(mem, 0, PGSIZE);
    va = PGROUNDDOWN(va);
    if (mappages(myproc()->pagetable, va, PGSIZE, (uint64)mem, PTE_W | PTE_X | PTE_R | PTE_U) != 0)
    {
      kfree(mem);
      return 0;
    }
    return (uint64)mem;
  }
}
```

最后在`uvmunmap`和`uvmcopy`中剩下几个小问题：

先是`uvmunmap`：我们需要注释掉几个`panic`，因为存在延迟分配，有些地址可能在真正被分配前就被显式的释放了，这里不算异常

```c
if((pte = walk(pagetable, a, 0)) == 0)
  //panic("uvmunmap: walk");
  continue;
if ((*pte & PTE_V) == 0)
{ //panic("uvmunmap: not mapped");
  *pte = 0; // 这个是个坑，下面的continue跳过了最后的*pte=0，这里要手动执行一下
  continue;
}
```

然后是`uvmcopy`：在`fork`时原有的部分内存可能尚未被分配，在复制时不需要抛出异常，跳过即可

```c
if((pte = walk(old, i, 0)) == 0)
  //panic("uvmcopy: pte should exist");
  continue;
if((*pte & PTE_V) == 0)
  //panic("uvmcopy: page not present");
  continue;
```



> 接下来的内容是`2021 Fall`的



## [2021 Fall] Lab Copy-on-Write Fork

原来的实验侧重于延迟分配，而这个是写时复制。在可选项作业中，第一点就是要求同时增加`Lazy Allocation`和`CoW`



首先修改`uvmcopy`，在复制子进程页表的时候，直接映射为父进程的页表，并且不允许写入。当父进程或子进程需要修改对应页面的时候，我们可以通过在异常处理中复制页表。但是，我们需要区分写保护异常是来源于`CoW`还是单纯的访问越界，所以我们使用`RISC-V`提供的`RSW`位（软件定义位）来标识。

```c
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    flags = (PTE_FLAGS(*pte) | PTE_C) & ~PTE_W; // 清除可写标记 增加 CoW 标记
    *pte = PA2PTE(pa) | flags;
    if(mappages(new, i, PGSIZE, pa, flags) != 0)
      goto err;
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
  return -1;
}
```

然后，我们修改异常处理程序，原来只处理系统调用异常和设备、时钟中断，现在我们需要新增缺页异（`13`：`Load Page Fault`）和写保护异常（`15`：`Store/AMO page fault`）

```c
// 检查目标地址是否有 CoW 标记
int
check_cow(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;

  // walk 当 va 大于 MAXVA 时，会产生内核 panic
  // 这里手动处理一下
  if(va >= MAXVA)
    return 0;

  pte = walk(pagetable, va, 0);

  if(pte == 0)
    return 0;
  if((*pte & PTE_V) == 0)
    return 0;
  if((*pte & PTE_C) == 0)
    return 0;

  return 1;
}

// 复制内存并分配新的页表项
uint64
cowalloc(pagetable_t pagetable, uint64 va)
{
  uint64 pa = walkaddr(pagetable, va);
  if(pa == 0)
    return 0;

  char *mem = kalloc();
  if(mem == 0)
    return 0;
  memmove(mem, (void *)pa, PGSIZE);

  pte_t *pte = walk(pagetable, va, 0);
  uint64 flag = (PTE_FLAGS(*pte) | PTE_W) & ~PTE_C;
  *pte = PA2PTE(mem) | flag; // 直接就地修改

  kfree((void *)pa);

  return (uint64)mem;
}

void
usertrap(void)
{
  // --snip--
  syscall();
  } else if(r_scause() == 13 || r_scause() == 15) {
    uint64 addr = r_stval();
    if(!check_cow(p->pagetable, addr) || cowalloc(p->pagetable, addr) == 0)
      p->killed = 1;
  } else if((which_dev = devintr()) != 0){
  // --snip--
}
```

需要注意的是这里`cowalloc`需要判断`walkaddr`获取到`pa`后需要判断`pa`是否为`0`，否则会导致`usertests`中的`stacktest`出错，陷入`kerneltrap`（调试了好久）

其原因在于访问越界访问到了内核部分的页表（`Guard Page`），由于`PTE_U`没有设置，导致`walkaddr`会返回`0`，而对`0`地址进行读取、修改导致了内核缺页

接下来需要一个类似垃圾回收的系统对引用进行计数，在引用不为`0`之前不得释放内存，在引用为`0`时及时释放内存

我们先在`kinit`中初始化一个引用计数表：

```c
struct ptr_ref {
  struct spinlock lock;
  uint64 counter[PHYSTOP >> PGSHIFT]; // 按照物理内存页分配
} ptr_ref;

void
kinit()
{
  initlock(&kmem.lock, "kmem");
  initlock(&ptr_ref.lock, "ptr_ref");
  freerange(end, (void*)PHYSTOP);
  for (int i = 0; i < PHYSTOP >> PGSHIFT; i++)
    ptr_ref.counter[i] = 0;
}
```

然后在`kalloc`申请新内存，在`uvmcopy`共享页的时候增加引用计数，在`kfree`中根据引用情况减少引用计数或者真的释放内存

```c
void *
kalloc(void)
{
  // --snip--
  if(r){
    memset((char *)r, 5, PGSIZE); // fill with junk
    acquire(&ptr_ref.lock);
    ptr_ref.counter[(uint64)r >> PGSHIFT] = 1; // 初始化为 1
    release(&ptr_ref.lock);
  }
  return (void*)r;
}

void
kfree(void *pa)
{
  struct run *r;
  int idx = (uint64)pa >> PGSHIFT;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  acquire(&ptr_ref.lock);
  if(ptr_ref.counter[idx] > 1){ // 还有多个引用的时候不真正的销毁内存
    ptr_ref.counter[idx]--;
    release(&ptr_ref.lock);
    return;
  }
  ptr_ref.counter[idx] = 0;
  release(&ptr_ref.lock); // 所有操作完后释放锁

  // --snip--
}

// 为了方便在其它模块中获取、修改计数器，写两个函数包装一下
void ref_inc(void* pa){
  acquire(&ptr_ref.lock);
  ptr_ref.counter[(uint64)pa >> PGSHIFT]++;
  release(&ptr_ref.lock);
}

uint64 ref_cnt(void* pa){
  return ptr_ref.counter[(uint64)pa >> PGSHIFT];
}


int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
  // --snip--
    if(mappages(new, i, PGSIZE, pa, flags) != 0)
      goto err;
    ref_inc((void*)pa); // 新增引用
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
  return -1;
}

```

最后处理`copyout`，当内核尝试写用户的`CoW`页时，需要手动分配新的页，由于返回值是一个由内核主动修改`CoW`页的过程，其不会交由`usertrap`处理，所以需要我们手动检查并按需分配，而用户程序修改`CoW`页时会交由`usertrap`处理（写到`kerneltrap`中会不会更通用？）

```c
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  // --snip--
    va0 = PGROUNDDOWN(dstva);
    pa0 = walkaddr(pagetable, va0);
    if(check_cow(pagetable, va0))
      pa0 = cowalloc(pagetable, va0);
  // --snip--
}
```



## [2021 Fall] Lab Multithread

### uthread

这一步要求我们实现一个用户态的线程库

首先，与内核中的`trapframe`类似的，我们编写一个结构体`threadframe`用来保存用户线程的上下文：

```c
struct threadframe {
  uint64 ra;
  uint64 sp;
  uint64 tp;
  uint64 s0;
  uint64 s1;
  uint64 s2;
  uint64 s3;
  uint64 s4;
  uint64 s5;
  uint64 s6;
  uint64 s7;
  uint64 s8;
  uint64 s9;
  uint64 s10;
  uint64 s11;
};
```

这里我们需要保存/恢复的是被调用者保存寄存器，因为在我们的轻量级线程中，线程切换用用户线程主动提出，`schedule`或`yield`前调用者已经准备好了栈结构，被调用者只需要保存好被调用者需要保存的寄存器然后切换给下一个进程即可

```asm
	.globl thread_switch
thread_switch:
		/* 保存当前线程上下文 */
        sd ra, 0(a0)
        sd sp, 8(a0)
        sd tp, 16(a0)
        sd s0, 24(a0)
        sd s1, 32(a0)
        sd s2, 40(a0)
        sd s3, 48(a0)
        sd s4, 56(a0)
        sd s5, 64(a0)
        sd s6, 72(a0)
        sd s7, 80(a0)
        sd s8, 88(a0)
        sd s9, 96(a0)
        sd s10, 104(a0)
        sd s11, 112(a0)

		/* 恢复下一个线程上下文 */
        ld ra, 0(a1)
        ld sp, 8(a1)
        ld tp, 16(a1)
        ld s0, 24(a1)
        ld s1, 32(a1)
        ld s2, 40(a1)
        ld s3, 48(a1)
        ld s4, 56(a1)
        ld s5, 64(a1)
        ld s6, 72(a1)
        ld s7, 80(a1)
        ld s8, 88(a1)
        ld s9, 96(a1)
        ld s10, 104(a1)
        ld s11, 112(a1)

        ret    /* return to ra */
```

接下来在`thread`结构体中增加上下文信息：

```c
struct thread {
  char               stack[STACK_SIZE]; /* the thread's stack */
  int                state;             /* FREE, RUNNING, RUNNABLE */
  struct threadframe context;           /* context saved by switch_thread */
};
```

在线程创建的时候，我们需要记录两个重要参数：线程的入口（通过`ra`跳转到目标），线程独有的栈地址`sp`

```c
void 
thread_create(void (*func)())
{
  struct thread *t;

  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
    if (t->state == FREE) break;
  }
  t->state = RUNNABLE;
  /* 设置入口点和栈 */
  t->context.ra = (uint64)func;
  t->context.sp = (uint64)&t->stack[STACK_SIZE-1]; /* stack grows down */
}

```

在线程切换的时候，通过上述`thread_switch`切换上下文：

```c
void 
thread_schedule(void)
{
  // --snip--
  if (current_thread != next_thread) {         /* switch threads?  */
    next_thread->state = RUNNING;
    t = current_thread;
    current_thread = next_thread;
    thread_switch((uint64)&t->context, (uint64)&current_thread->context); // save and restore context
  } else
    next_thread = 0;
}
```

### using threads

这题要求我们解决并发时的临界问题，我们在`get`和`put`中对具体的哈希桶操作的时候加锁：

```c
pthread_mutex_t lock[NBUCKET]; // 每一个桶单独加锁

static 
void put(int key, int value)
{
  int i = key % NBUCKET;
  // 在确定桶位置后对桶进行加锁
  pthread_mutex_lock(&lock[i]);
  // --snip--
  pthread_mutex_unlock(&lock[i]);
}

// get 并不需要加锁，程序在 get 阶段时不会进行任何写入

int
main(int argc, char *argv[]) {
  // --snip--
  // 初始化锁
  for (int i = 0; i < NBUCKET; i++) {
    pthread_mutex_init(&lock[i], NULL);
  }
  // --snip--
}
```

### Barrier

这题要求我们使用`pthread_cond`实现线程同步：

```c
static void 
barrier()
{
  //
  // Block until all threads have called barrier() and
  // then increment bstate.round.
  //
  pthread_mutex_lock(&bstate.barrier_mutex);
  bstate.nthread++;
  if(bstate.nthread < nthread){
    // 继续等待
    pthread_cond_wait(&bstate.barrier_cond, &bstate.barrier_mutex);
  } else {
    // 所有线程已经调用了 barrier()
    bstate.nthread = 0;
    bstate.round++;
    pthread_cond_broadcast(&bstate.barrier_cond);
  }
  pthread_mutex_unlock(&bstate.barrier_mutex);
}
```

## [2021 Fall] Lab Networking

这个`Lab`要求实现`E1000`网卡的发送和接收功能

首先研究一下`xv6`中网卡的工作流程：

1. 系统启动的时候调用`pci_init`扫描网卡驱动：`xv6`扫描了`bus 0`上的设备，如果发现`id`为`0x100e8086`的设备（`E1000`网卡的`Device ID`和`Vendor ID`）就调用`e1000_init`初始化设备
2. 在`e1000_init`中
   1. 关闭中断、重置网卡
   2. 初始化发送队列，将发送队列中每一项设置为已经发送完毕
   3. 初始化接收队列，分配接收`buffer`的内存
   4. 配置网卡的`MAC`地址
   5. 配置多播表（实际上全部为`0`）
   6. 配置并开启网卡接收、发送功能
   7. 启用中断
3. 在用户需要发送数据的时候，最终通过待补全的`e1000_transmit`将已经组装后的网络层数据包交由网卡发送（中间经历了`net_tx_tcp` -> `net_tx_ip` -> `net_tx_eth`一步一步封装成帧）
4. 在接收数据的时候，网卡每接收到一个数据包，将会触发一次中断，然后交由`e1000_intr`清中断，`e1000_recv`处理接收到的数据

在具体的实现上，我们按照`Hints`一步步完成即可：

```c
int
e1000_transmit(struct mbuf *m)
{
  acquire(&e1000_lock);

  uint32 tail = regs[E1000_TDT];

  // 检查队尾对应的数据是否发送完成
  if (!(tx_ring[tail].status & E1000_TXD_STAT_DD))
  {
    // buffer overflow
    release(&e1000_lock);
    return -1;
  }

  // 释放之前的数据
  if (tx_mbufs[tail])
    mbuffree(tx_mbufs[tail]);

  // 配置新的发送包
  tx_ring[tail].addr = (uint64)m->head;
  tx_ring[tail].length = m->len;
  // 一次只能发送一个包 设置 End Of Packet 标识
  // 同时告知硬件 FIFO 中有新数据
  tx_ring[tail].cmd = E1000_TXD_CMD_EOP | E1000_TXD_CMD_RS;

  tx_mbufs[tail] = m; // 保存标记用于释放内存

  // 更新队尾
  regs[E1000_TDT] = (tail + 1) % TX_RING_SIZE;

  release(&e1000_lock);

  return 0;
}

static void
e1000_recv(void)
{
  // 由于这个函数是由网卡中断触发的，在处理完成前不会有下一个中断打断执行，故不需要加锁
  // [HEAD, TAIL] 是被硬件保留的，我们需要从 TAIL + 1 开始读取数据，然后循环到 HEAD (-1)
  uint32 tail = regs[E1000_RDT];
  tail = (tail + 1) % RX_RING_SIZE;

  while (rx_ring[tail].status & E1000_RXD_STAT_DD)
  {
    // 接受并交由上层处理数据包
    rx_mbufs[tail]->len = rx_ring[tail].length;
    net_rx(rx_mbufs[tail]);

    // 创建一个新的 mbuf，和 e1000_init 中的一样
    rx_mbufs[tail] = mbufalloc(0);
    if (!rx_mbufs[tail])
      panic("e1000");
    rx_ring[tail].addr = (uint64)rx_mbufs[tail]->head;

    // 清空状态
    rx_ring[tail].status = 0;

    // 更新队尾
    regs[E1000_RDT] = tail;

    // 处理下一个包
    tail = (tail + 1) % RX_RING_SIZE;
  }
}
```





