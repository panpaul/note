---
title: 计算机系统基础-主存储器组织
date: 2020-05-18 10:51:05
mathjax: true
tags: 
- memory
- csapp
---

计算机系统基础-主存储器组织

<!--more-->

- ### 基本术语 

|                        术语                        |                         解释                         |
| :------------------------------------------------: | :--------------------------------------------------: |
|      记忆单元（存储基元/存储元/位元）（Cell）      |     具有两种稳态的能够表示进制数码0和1的物理器件     |
|        存储单元/编址单位（Addressing Unit）        | 具有相同地址的位构成一个存储单元，也称为一个编址单位 |
|          存储体/存储矩阵/存储阵列（Bank）          |             所有存储单元构成一个存储阵列             |
|            编址方式（Addressing Mode）             |                  字节编址、按字编址                  |
| 存储器地址寄存器（Memory Address Register - MAR）  |             用于存放主存单元地址的寄存器             |
| 存储器数据寄存器（Memory Data Register-MDR 或MBR） |           用于存放主存单元中的数据的寄存器           |

- ### 存储器分类 

1. 按工作性质/存取方式分类

   - 随机存取存储器（Random Access Memory）RAM

     每个单元读写时间一样，且与各单元所在位置无关

   - 顺序存取存储器（Sequential Access Memory）SAM

     数据按顺序读出或写入

   - 直接存取存储器（Direct Access Memory）DAM

     直接定位到读写数据块，读写时按顺序进行

   - 相联存储器（Associate Memory）AM（Content Addressed Memory）CAM

     按内容检索读写

2. 按存储介质分类

   - 半导体/光存储器/磁表面存储器

3. 按信息的可更改性分类

   - 读写存储器（R/W）
   - 只读存储器（RO）

4. 按断电后信息的可保存性

   - 非易失性存储器/易失性存储器

5. 按功能/容量/速度/所在位置分类

   - 寄存器（Register）
   - 高速缓存（Cache）
   - 内存储器（Main Memory）
   - 外存储器（Auxiliary Storage）

- ### 主存的结构

<img src="/images/memory-intro-1.webp" alt="memory_intro_1">

$n$位地址线对应有$2^n$个存储单元

- ### 主存的性能指标

存取时间$T_A$：从CPU送出内存单元的地址码开始，到主存读出数据并送到CPU（或是CPU把数据写入主存）所需的时间，分**读取时间**和**写入时间**

存储周期$T_{MC}$：连续两次访问存储器所需的最小时间间隔（等于存取时间+上下一次存取开始前要求的附加时间）

- ### 内存储器的引用及分类

<img src="/images/memory-intro-2.webp" alt="memory_intro_2">

1. SRAM： 六管静态MOS管电路（看作带式中的RS触发器），只要供电数据一直保存

2. DRAM：动态单管记忆电路
   - 优点：电路元件少，功耗小，集成度高，用于构建主存储器
   - 缺点：速度慢，破坏性读出（要求读后再生），需定时刷新
   - 刷新：数据以电荷的形式保存在电容中，只能维持几十个毫秒，需要定期刷新。刷新时按行进行

- ### 半导体RAM的组织

存储体（Memory Bank）：由记忆单元（Cell）构成的存储阵列

<img src="/images/memory-intro-3.webp" alt="memory_intro_3">

- ### 内存条

<img src="/images/memory-intro-4.webp" alt="memory_intro_4">

(SPARCstation 20's内存条)

交错编址：

<img src="/images/memory-intro-5.webp" alt="memory_intro_5">