---
title: 在STM8上使用GPIO模拟UART
date: 2020-09-29 19:48:38
mathjax: true
tags:
- STM8
- UART
- GPIO
---

STM8是意法半导体公司生产的8位的单片机，这款单片机价格便宜又不失强大，但是其自带的通信用`UART`串口只有一组，在某些场景写不够，所以有软件模拟的需求。

<!--more-->

# 时钟设置

无论是什么通信协议（~~好像绝对了一点~~）都离不开时钟的支持，在这里，`UART`协议也是严格的依赖时钟信号。

STM8的时钟配置十分多样化，这里为了简单，采用了内置高速时钟源并且配置主时钟周期为`2MHz`，参考代码如下：

```c
void clk_init()
{
    CLK_ICKR_HSIEN = 1; // High-speed internal RC on
    while (CLK_ICKR_HSIRDY == 0)
        ; // wait unitl HSI clock ready

    CLK_SWR = 0xE1;        // HSI selected as master clock source
    CLK_CKDIVR_CPUDIV = 0; // CPU prescaling 0
    CLK_CKDIVR_HSIDIV = 3; // HSI prescaling 8 (16/8)

    // Now fMaster set to 2MHz and fCpu = fMaster
}
```

# 模拟GPIO串口的配置

这里没有什么好说的，我才用了`PC6`和`PC7`作为`UART`协议的`TX`和`RX`，参考代码如下：

```c
void gpio_init()
{
    // PC6<->RX PC7<->TX

    /* Output Push-pull Fast  */
    PC_DDR_DDR6 = 1;
    PC_CR1_C16 = 1;
    PC_CR2_C26 = 1;

    /* Input Pull-up No interrupt */
    PC_DDR_DDR7 = 0;
    PC_CR1_C17 = 1;
    PC_CR2_C27 = 0;
}
```

# 模拟UART

## UART协议

具体的内容可以自行查找，这里简单说一下协议的定义：

`UART`协议分为起始位、数据位、校验位、停止位、空闲位。

- 起始位：是一个逻辑`0`信号，表示传输的开始

- 数据位：可以是长度为`4`、`5`、`6`、`7`、`8`位长的二进制数据

- 校验位：校验位的形式可以有多种：奇校验、偶校验、没有校验等
- 停止位：是数据传输结束的标识，可以是1位、1.5位、2位长的高电平
- 空闲位：逻辑`1`信号，表示没有数据在进行传输

## 软件模拟UART协议

这里模拟`UART`协议的方式有两种，一种是通过延时来实现周期，一种是通过定时器来实现。我才用了定时器的方式来实现数据位的发送

## 定时器的初始化

我采用了`TIM2`定时器，主要要进行的配置是计算触发的周期。前面时钟周期已经调整为`2MHz`了，我模拟的`UART`波特率为`9600`，所以周期为$\frac{2M}{9600}\approx 280=\mathrm{0x00D0h}$.

参考代码如下：

```c
void TIM2_init()
{
    /*
     * Timer Config
     * fMaster = CK_PSC = 2MHz
     * BitRate = 9600Hz
     * ARR = CK_PSC / BitRate = 625/3 = 208 = 0x00 0xD0
     */

    /* no prescaling */
    TIM2_PSCR_PSC = 0x00;
    /* conut freq */
    TIM2_ARRH = 0x00;
    TIM2_ARRL = 0xD0;
    /* enable interrupt */
    TIM2_IER_UIE = 1;
}
```

需要注意的是在`main`函数中，我们需要用`asm("sim")`和`asm("rim")`来调整`main`函数的中断优先级

## 时钟触发函数

这里我才用了状态机的思想来编写时钟触发函数

首先定义几个状态：开始、数据、校验、结束、空闲五个状态

```c
/* Sending Status */
enum STATUS
{
    START, // start bit
    DATA,  // data bits
    CHECK, // parity bit
    STOP,  // stop bit
    IDLE   // idle bits
};
```

然后在时钟触发中更新状态实现数据的发送。

我用一下代码实现了一个简单的循环发送`0x00`到`0xff`功能的程序：

```c
// u8 <-> uint8_t
u8 SU_VAL = 0x00;              // data to send
u8 SU_CNT = 0;                 // which bit to send
u8 SU_PARITY = 0;              // Parity check
enum STATUS SU_STATUS = START; // current sending status

#pragma vector = TIM2_OVR_UIF_vector
__interrupt void TIM2_Handler(void)
{
    switch (SU_STATUS)
    {
    case START: /* start bit */
    {
        PC_ODR_ODR6 = 0;
        SU_STATUS = DATA;
    }
    break;

    case DATA: /* data bits */
    {
        u8 tmp = ((SU_VAL >> SU_CNT) & 1); // get the LSB1
        PC_ODR_ODR6 = tmp;
        SU_PARITY += tmp;
        if (SU_CNT >= 7)
        { // next data
            SU_CNT = 0;
            SU_STATUS = CHECK;
        }
        else
        { // next bit
            SU_CNT++;
            SU_STATUS = DATA;
        }
    }
    break;

    case CHECK: /* parity bit */
    {
        // using odd check
        if (SU_PARITY & 1)
            PC_ODR_ODR6 = 0;
        else
            PC_ODR_ODR6 = 1;
        SU_PARITY = 0;
        SU_STATUS = STOP;
    }
    break;

    case STOP: /* stop bit */
    {
        PC_ODR_ODR6 = 1;
        if (SU_VAL == 0xff)
        { // 0x00-0xff done wait for a cycle
            SU_STATUS = IDLE;
        }
        else
        { // next number
            SU_STATUS = START;
        }
        SU_VAL++;
    }
    break;

    case IDLE: /* idle bit(s) */
    {
        PC_ODR_ODR6 = 1;
        if (SU_IDLE == 8)
        {
            SU_IDLE = 0;
            SU_STATUS = START;
        }
        else
        {
            SU_IDLE++;
            SU_STATUS = IDLE;
        }
    }
    break;

    default: /* it must be wrong */
        break;
    }

    /* update timer */
    TIM2_SR1_UIF = 0;
}
```

这个程序有几个细节：

- 首先是中断函数的定义：首先要设定中断向量`#pragma vector =`然后是函数前面要加`__interrupt`，这些会告知编译器你写的函数对应哪个中断
- 然后是数据的发送：最低有效位先发送出去
- 最后是处理完一次发送后要记得清零寄存器：`TIM2_SR1_UIF = 0`

## 最后

最后附上一张效果图：

<img src="/images/stm8_softuart_1.webp" width="50%" alt="soft_uart">