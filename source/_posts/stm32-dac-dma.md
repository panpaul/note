---
title: 解决STM32 DAC DMA功能错误
date: 2021-10-15 09:52:25
tags:
- STM32
- DAC
- DMA
- CubeMX
---

之前做了一个使用`STM32`的`DAC`功能播放音频的项目，其中与官方例程不同的是，我采用了`DMA`功能搬运数据。

<!-- more -->

## CubeMX配置

这一部分没什么好说的，使用`CubeMX`勾选相应的选项

首先是`DAC`功能，在`DMA`功能选项卡下绑定`DMA`通道，在`DMA`配置里面数据宽度选择`Byte`

![image-20211103095907633](image-20211103095907633.png)

然后配置`TIM6`定时器，定时器频率根据系统时钟和音频采样率进行计算：

![image-20211103100032732](image-20211103100032732.png)

## 播放音乐

这里通过`HAL`库开启`DMA`的搬运

```c
HAL_DAC_Start_DMA(
	&hdac,
	DAC_CHANNEL_1,
	(uint32_t*)audio_buffer,
	audio_buf[audio_flip].len,
	DAC_ALIGN_8B_R
);
```

**然而你会发现这个函数会返回错误**

这个错误其实是`CubeMX`的**bug**

`CubeMX`生成的初始化代码的顺序有误：其默认的顺序是先初始化`DAC`后初始化`DMA`功能，导致`DAC`初始化的时候`DMA`没有准备好

这里在`CubeMX -> Project Manager -> Advanced Settings`里面调整顺序：

![image-20211103100955316](image-20211103100955316.png)

把`MX_DAC_Init`移动到`MX_DMA_Init`下方后重新生成代码发现程序能够正常工作了！

