---
title: Bomblab 记录
date: 2020-03-31 20:12:15
updated: 2020-04-29 16:30:00
tags:
- debugging
- bomblab
- csapp
- assembly
---

最近计算机系统基础课程要求完成这项作业，故记录一下完成过程。

<!--more-->

- ### bomb.c ###

  首先，出题者给我们提供了bomb的原型，通过`bomb.c`，大致可以了解这个`bomb`的执行流程：从键盘读入一行，然后执行`phase_(x)`然后解除炸弹。总共有`6`？个`phase`等待我们取解开。

  <img src="/images/bomb_3.webp" alt="bomblab_bomb.c">

- ### 环境准备 ###

  这里，我是用了[radare2](https://www.radare.org/) 作为分析工具。(然而第6题太给力，用了`IDA`)

  首先，执行`r2 -A bomb`加载二进制文件并执行分析。

  <img src="/images/bomb_1.webp" alt="bomblab_prepare">

  然后，执行`afl`看一下函数列表，我们发现了几个包含`phase`的函数，也就是我们要重点关注的东西了。同时也注意到列表里包含`sym.secret_phase`，估计这是个`bonus`。

  <img src="/images/bomb_2.webp" alt="bomblab_functions">

- ### Phase_1 ###

  先执行`s sym.phase_1`跳转到`phase_1`，然后执行`pdf`查看反汇编代码。

  <img src="/images/bomb_4.webp" alt="bomblab_phase1">

  `phase_1`的汇编代码比较简洁。

  我们的输入存放在`rdi`中，然后`phase_1`中将`Border relations with Canada have never been better.`这句话放入`esi`中作为参数调用`strings_not_equal`。`strings_not_equal`函数负责判断两个字符串是否相等。接下来是`test`指令判断`eax`的值是否为0，不为0则引爆炸弹。

  所以`phase_1`的答案就是`Border relations with Canada have never been better.`

- ### Phase_2 ###

  一样的跳转到`phase_2`然后查看反汇编代码。

  <img src="/images/bomb_5.webp" alt="bomblab_phase2">

  可以看到，在`phase_2`中程序读入了6个数字，然后判断第一个数字是否为1，不为1则爆照。

  若为1则跳转到`0x00400f30`处，这里`radare2`用`qword [local_4h]`表示`rsp+4`，也就说`local_4h`到`local_18h`刚好是第二个数到第六个数和“第七个数”（用于判断循环结束）（也刚好应证了开头`sub rsp, 0x28`开辟的7个空间）。将一头一尾分别保存到`rbx`，`rbp`后，一个`JMP`直接跳到了`0x00400f17`开始执行循环。

  在循环体中，程序先取出前一个值(`rbx-4`)，然后将这个值乘2，在与当前值比较(`rbx`)。如果相等那么将`rbx+4`也就是循环迭代下一个值，如果刚好到最后一个值了那么就跳出循环。

  所以这个循环就是判断这六个数是否是以1为首项，2为公比的等比数列。

  故`phase_2`的答案是`1 2 4 8 16 32`。

- ### Phase_3 ###

  同样的，跳转到`phase_3`然后查看反汇编代码。

  <img src="/images/bomb_6.webp" alt="bomblab_phase3">

  这里先调用`sscanf`读取读取两个数（`"%d %d"`），然后判断返回值是否大于1。查阅资料后得知`sscanf`的返回值的含义应该是：

  > 如果成功，该函数返回成功匹配和赋值的个数。如果到达文件末尾或发生读错误，则返回 EOF。

  然后我们根据调用的约定可以得出`local_ch`存放第二个数，`local_8h`存放第一个数。

  然后有个`CMP`比较（`0x00400f6a`），可以得出第一个数不能大于7，同时又由接下来的`ja`得出第一个数应该是无符号的，也就第一个数还需大于0。

  然后进入了一个`switch-case`语句。首先是`jmp qword [rax*8 + 0x402470]`，这里可以想到应该是通过`switch-case`的跳转表确定结果。由于前面已经推出第一个数只可能是0到7共8个值，故执行`px/8xg 0x402470`查看那8个`case`的跳转表。

  <img src="/images/bomb_7.webp" alt="bomblab_phase3">

  所以设第一个数为`x`，那么`x`的跳转表如下：

  

  |    地址    |  x   |
  | :--------: | :--: |
  | 0x00400f7c |  0   |
  | 0x00400fb9 |  1   |
  | 0x00400f83 |  2   |
  | 0x00400f8a |  3   |
  | 0x00400f91 |  4   |
  | 0x00400f98 |  5   |
  | 0x00400f9f |  6   |
  | 0x00400fa6 |  7   |

  对于每一个`case`都修改了`eax`的值，然后跳转到`0x00400fbe`与第二个数的值进行比较，如果相等就成功拆弹，否则就失败。故本题答案有多组，设第二个数位`y`，本题答案如下：

  

  |  x   |     y      |
  | :--: | :--------: |
  |  0   | 207(0xcf)  |
  |  1   | 311(0x137) |
  |  2   | 707(0x2c3) |
  |  3   | 256(0x100) |
  |  4   | 389(0x185) |
  |  5   | 206(0xce)  |
  |  6   | 682(0x2aa) |
  |  7   | 327(0x147) |

- ### Phase_4 ###

  同样的，跳转到`phase_4`然后查看反汇编代码。

  `phase_4`和`phase_3`开头很像，同样是读入了两个数（设为`x`和`y`）。

  <img src="/images/bomb_8.webp" alt="bomblab_phase4">

  完成输入后，在`0x0040102e`对`x`进行比较，其中`x<=14`。

  接着将`edx`赋值为14，将`esi`赋值为0，`edi`赋值为x，再进入`fun4`。

  <img src="/images/bomb_9.webp" alt="bomblab_phase4">

  这里是一个递归调用，我们尝试逆向出C语言代码：

  ```C
  int func4(int edx,int esi,int edi) {
      int eax = edx - esi;
      int ecx = eax >> 31; // 符号位
      eax += ecx;
      eax /= 2;
      ecx = eax + esi;
      if(ecx<=edi) {
          if(ecx>=edi) {
              return 0;
          } else {
              esi = eax+1;
              eax = func4(edx,esi,edi);
              return 2*eax+1;
          }
      } else {
          edx = ecx-1;
          eax = func4(edx,esi,edi);
          return 2*eax;
      }
  }
  ```

  这里可以大致看出是一个二分算法，稍微修改一下代码：

  ```C
  int func4(int r, int l, int t)
  {
      int mid = (r + l) >> 1; // ecx,同时假定r>l
      if (mid == t)
      { // 找到目标
          return 0;
      }
      else if (mid < t)
      { // mid < t 中值小于目标x，扩大左边界
          l = ((r - l) >> 1) + 1;
          return func4(r, l, t) * 2 + 1;
      }
      else
      { // mid > t 中值大于目标x，缩小右边界至mid-1
          r = mid - 1;
          return func4(r, l, t) * 2;
      }
  }
  ```

  

  在`phase_4`中执行了`func4(14,0,x)`其返回值要求为0，同时第二个输入也必须为0(??)才能过关。

  关于`func4`不妨写一个程序遍历一遍（x取值在0到14之间），得到的结果如下：

  

  |  x   |       func4        |
  | :--: | :----------------: |
  |  0   |         0          |
  |  1   |         0          |
  |  2   |         4          |
  |  3   |         0          |
  |  4   |         2          |
  |  5   |         2          |
  |  6   | segmentation fault |
  |  7   |         0          |
  |  8   |         1          |
  |  9   |         1          |
  |  10  | segmentation fault |
  |  11  |         1          |
  |  12  | segmentation fault |
  |  13  | segmentation fault |
  |  14  | segmentation fault |

  这里比较有意思的是`segmentation fault`，估计是模拟给出的C语言代码有些问题吧！同时实际测试发现`bomb`没有给出`segmentation fault`而是直接引爆了炸弹。

  所以综上，本题答案为`0 0`或`1 0`或`3 0`或`7 0`。

- ### Phase_5 ###

  同样的，跳转到`phase_5`然后查看反汇编代码。

  <img src="/images/bomb_10.webp" alt="bomblab_phase5">

  ~~其实这段汇编有些内容我还不清楚，但是不影响解题。~~

  > 2020-4-27:
  >
  > 关于`fs:[0x28]`：
  >
  > 这里实际上是通过段寻址方式获取了一个“金丝雀”(canary)值并把这个值送入栈中，这个动作是一种栈溢出保护手段。
  >
  > 先将这个特殊的值压栈，当函数结束后再判断栈中的这个值是否被修改过，以此来验证是否出现栈溢出。
  >
  > 关于`0x28`这个偏移量：
  >
  > 这个`bomb`是64位，并且与`glibc`链接。`fs`寄存器被`glibc`定义为存放`TLS(Thread Local Storage)`信息。
  >
  > 在`Github`上的一份`glibc`的`mirror`中我们可以找到`tls`的定义:[Github](https://github.com/bminor/glibc/blob/e4a399921390509418826e8e8995d2441f29e243/sysdeps/x86_64/nptl/tls.h#L51)
  >
  > 其中`stack_guard`存放的就是这里偏移为`0x28`的金丝雀值。

  这段代码的大意是：

  1. 输入一个字符串，长度为6
  2. 遍历输入的每个字符`c`
  3. 获取`c`的ASCII二进制码的后四位，将这个数作为索引从`maduiersnfotvbylSo_you_think_you_can_stop_the_bomb_with_ctrl_c__do_you`中取出字母拼接一个新的字符串。
  4. 比较拼接出的字符串是否是`flyers`

  这里由于是4位二进制串故我们只用考虑在前16位（`maduiersnfotvbyl`）中找字母就可以了。

  其中`f-9`，`l-15`，`y-14`，`e-5`，`r-6`，`s-7`。这里由于只考虑后4位二进制，所以可以直接`printf`出几个不可见字符或者找可见字符后四位满足要求的。比如：

  ```C
  printf("%c%c%c%c%c%c",9,15,14,5,6,7);
  printf("IONEFG");
  ...
  ```

- ### Phase_6 ###

  同样的，跳转到`phase_6`然后查看反汇编代码。

  <img src="/images/bomb_11.webp" alt="bomblab_phase6">

  这一题汇编代码比较长。一开始就分配了20个4字的栈空间。

  这道题静态分析不好整（~~我太菜了~~），所以使用`IDA`进行动态调试。

  <img src="/images/bomb_11_3.webp" alt="bomblab_phase6">

  首先定位到`phase_6`

  其中左半边的比较好研究，先看左半边。

  <img src="/images/bomb_11_4.webp" alt="bomblab_phase6">

  左半边有两重循环，其中左半边的逻辑大至如下：

  1. 首先读入六个数字
  2. 遍历这六个数字，记当前数字为`a`
  3. 如果`a`比6大则爆炸
  4. 从`a`开始遍历以后的数字，如果存在与`a`相等的则爆炸
  5. 完成第3，4步后迭代`a`

  也就是说这1-5步就是确定这六个数字互不相等且都小于等于6（大于等于1）

  执行完以上步骤之后又是一个循环：

  <img src="/images/bomb_11_5.webp" alt="bomblab_phase6">

  在这个循环内，用7减去输入的每个数字。

  接着，到了最为复杂的部分。

  <img src="/images/bomb_11_6.webp" alt="bomblab_phase6">

  首先是一个神秘常数`node1`（应该是`IDA`自动命名的）。因为一些神神秘秘的原因，我无法直接获取它的值，所以我在动态调试时使用`python`脚本来获取。

  <img src="/images/bomb_11_1.webp" alt="bomblab_phase6">

  <img src="/images/bomb_11_2.webp" alt="bomblab_phase6">

  最后我们拿到了六个数所对应的神秘数值：

  

  | node | 7-x  |  x   |
  | :--: | :--: | :--: |
  | 332  |  1   |  6   |
  | 168  |  2   |  5   |
  | 924  |  3   |  4   |
  | 691  |  4   |  3   |
  | 477  |  5   |  2   |
  | 443  |  6   |  1   |

  接着程序按照我们输入的值将`node`的值对应按顺序存入`RBX`中，最后检查`RBX`中的值是否是递减的。

  <img src="/images/bomb_11_7.webp" alt="bomblab_phase6">

  所以我们手动给这几个数排序，也就是`924>691>477>443>332>168`对应成我们要输入的数就是`4 3 2 1 6 5`

- ### 最后 ###

  其实还有一个`secret_phase`没分析，就等下一次填坑吧！

  总结一下，这6个`phase`从简单到难，的确是很考验基础知识的。
  
  UPDATE：来填坑了

- ### secret_phase ###

  关于这个`secret_phase`如不是题目明确指明，我或许都不会去想有这一关。

  开启`secret_phase`的机关在`phase_defused`中：

  <img src="/images/bomb_s_2.webp" alt="bomblab_secret_phase">

  在这个函数里，先判断是否完成了六次输入，如果完成了就会判断是否触发隐藏关。

  在这里调用了`sscanf`来进行输入，而需要转换的源字符串是什么，这里通过动态调试，得知在执行到这儿后，第四次输入的内容将被传送到这。

  所以触发隐藏关就是在第四次输入后多加一个`DrEvil`。

  下面就来看`secret_phase`：

  <img src="/images/bomb_s_1.webp" alt="bomblab_secret_phase">

  在`secret_phase`中首先读入了一个十进制的数字字符串，然后通过`strtol`函数把它转化为整数。

  如果这个数小于等于1001则可以继续，反之引爆炸弹。

  接着，调用函数`fun7`，传入两个参数，一个是"$"(?)一个是转换后的那个数，如果返回值为2则顺利通关。

  接着分析`fun7`：

  <img src="/images/bomb_s_3.webp" alt="bomblab_secret_phase">

  这里尝试还原成C语言代码：

  ```C
  int fun7(long long *edi, long long esi)
  {
      if (!edi)
      {
          return 0xffffffff;
      }
      if (*edi <= esi)
      {
          if (*edi == esi)
          {
              return 0;
          }
          else
          {
              edi += 16;
              return 2 * fun7(edi, edi) + 1;
          }
      }
      else
      {
          edi += 8;
          return 2 * fun7(edi, esi);
      }
  }
  ```

  稍微整理一下代码：

  ```c
  int fun7(long long *x, long long y)
  {
      if (!x)
          return 0xffffffff; // -1
      if (*x > y)
          return 2 * fun7(x + 1, y);
      if (*x == y)
          return 0;
      if (*x < y)
          return 2 * fun7(x + 2, y) + 1;
  }
  ```

  然后回到最初传入的那个地址，执行`px/8xg 0x6030f0`查看一下存放的值：

  <img src="/images/bomb_s_4.webp" alt="bomblab_secret_phase">

  然后再反向推这个`fun7`，得到结果`2`的步骤应该是`0->2*0+1->2*(2*0+1)`。

  1. 那么第一次输入要先满足`*x>y`，而第一次输入时`*x=36`故`y<36`。
  2. 然后取`x`的下一个数，也就是`0x603110`指向的内容，即`8`。此时要满足`*x<y`，即`y>8`。
  3. 接着取`x`的下两个数，也就是`0x603150`指向的内容，即`22`。此时要满足`*x==y`，即`y=22`。

  所以`secret_phase`的答案是`22`。
  
  UPDATE-2020-4-29:
  
  其实这个隐藏关还有另一个答案`20`
  
  我们不妨认为`x+1`就是左子树，`x+2`就是右子树，`x`对应的就是当前节点的值，可以画出以可二叉树：
  
  <img src="/images/bomb_tree.webp" alt="bomblab_secret_phase">
  
  关于另一个答案`20`，可以这样推出：我们知道，最后找到相等时返回的是`0`，所以在找到`0`的上一层可以嵌套多个`*x>y`(`0*2`还是`0`)。那么按照上面画的二叉树来判断就是在`22`的左子树上也就是`20`(比`22`的多遍历一次)
  
  


