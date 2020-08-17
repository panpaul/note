---
title: 使用Arduino构建运动收集平台
date: 2020-08-16 12:01:43
tags:
- arduino
- bluetooth
- HC-05
- acceleration
- mpu6050
- sensor
---

最近在使用`Arduino`构建加速度收集工具，选用的传感器为`MPU-6050`，使用蓝牙模块`HC-05`将数据发送至手机。

<!--more-->

### 蓝牙模块

我使用的蓝牙模块是`HC-05`，它是主从一体的蓝牙串口模块，当设备完成配对连接后，我们可以直接将蓝牙当作串口用。

在Arduino Uno中，板载了TX、RX接口，如果将蓝牙模块直接连接到该端口上可以直接通过串口输出到蓝牙。但是在我的项目里，串口同时要输出调试信息，为了不干扰蓝牙的输出，我们选用了`10`和`11`号引脚作为模拟串口。

### 运动采集模块

我使用了`MPU6050`作为运动传感器。`MPU6050`是首个为实现低功耗、低成本和高性能需求而设计的运动传感器。其内置了数字信号处理器，并且通过$I^2C$接口进行数据的输入输出。

### 模块接线

`Arduino`、`HC-05`、`MPU6050`的接线如图3.1.1所示：

<img src="/images/abm_board.webp" alt="board">

在这张图里，`Arduino`左上角紫色、蓝色接线对应的端口没有标记引脚类型，其实际上分别为`SCL`和`SDA`接口。考虑到不同型号的`Arduino`以及国产`Arduino`的一些定制，实际上不同板子的`SCL`和`SDA`接口对应的引脚不同，需要查询厂商提供的接口参数表。

### 代码编写

#### 蓝牙模块

我们首先可以根据需求调整蓝牙的参数，这一步通过`AT`模式来完成。

将`EN`端与`Arduino`中的`3.3V`高电平相连，进入`AT`模式，然后调整`bitrate`至`38400`，然后根据`AT`指令集语法来调整或者查询蓝牙设置。

参考代码如下：

```c++
#include <SoftwareSerial.h>
/*
	pin10 : RX 连接 TXD
	pin11 : TX 连接 RXD
*/
SoftwareSerial BT(10, 11);
void BTConfig();

void setup(){
    BT.begin(9600);
}

void loop(){
    BTConfig();
}

void BTConfig()
{
    // 设置蓝牙名称
    BT.println("AT+NAME=ProjectFall");
    
    // 设置蓝牙密码
    BT.println("AT+PSWD=0000");
}
```

在完成设置后，我们开始编写蓝牙通讯的主体代码。这里考虑到蓝牙通信实际上存在较大的丢包问题，我设计了一种十分简陋的通信协议：每一条数据开头结尾采用`<`和`>`界定。

蓝牙输出数据相对简单，直接采用`BT.print()`即可，而读取数据则相对复杂，核心代码如下：

```c++
const byte numChars = 16;
char buffer[numChars]; // 缓存块
bool newBuffer = false;

void BTRead()
{
    /*
        数据格式 "<" + data + ">"
    */
    static bool receving = false;
    static byte idx = 0;
    char ch;

    while (BT.available() && newBuffer == false)
    {
        ch = BT.read();

        if (receving)
        {
            if (ch != '>')
            {
                buffer[idx] = ch;
                idx++;
                if (idx >= numChars)
                {
                    idx = numChars - 1;
                }
            }
            else
            {
                buffer[idx] = '\0';
                receving = false;
                idx = 0;
                newBuffer = true;
            }
        }
        else if (ch == '<')
        {
            receving = true;
        }
    }
}
```

#### 运动传感器

我们在使用之前要先初始化传感器的串口，具体代码可以写在`setup`里面。

```c++
const int MPU = 0x68;

Wire.begin();
Wire.beginTransmission(MPU);
Wire.write(0x6B);
Wire.write(0);
Wire.endTransmission(true);
```

具体的文档如下：

<img src="/images/abm_426.webp" alt="4.2.6">

然后是读取数据：

先上代码：

```c++
void ReadData()
{
    Wire.beginTransmission(MPU);
    Wire.write(0x3B);
    Wire.requestFrom(MPU, 14, true);
    Wire.endTransmission(true);

    // 1条数据2字节 一次读取一个字节
    // 加速度
    ACC_X = (Wire.read() << 8 | Wire.read());
    ACC_Y = (Wire.read() << 8 | Wire.read());
    ACC_Z = (Wire.read() << 8 | Wire.read());
    // 温度
    TMP = (Wire.read() << 8 | Wire.read());
    // 角速度
    GYR_X = (Wire.read() << 8 | Wire.read());
    GYR_Y = (Wire.read() << 8 | Wire.read());
    GYR_Z = (Wire.read() << 8 | Wire.read());
}
```

在文档中从`0x3B`开始是存放传感器获得的数据的寄存器：

<img src="/images/abm_417.webp" alt="4.1.7">

<img src="/images/abm_418.webp" alt="4.1.8">

<img src="/images/abm_419.webp" alt="4.1.9">

更多详细的参数可以参见官方文档

#### 合成

最后我们只需要根据自己的实际功能所需，将各个模块的代码组合起来写入`loop`中即可

### 总结

已知存在的问题：

1. 实际测试蓝牙模块的丢包十分严重，如果考虑传输大文件或音频建议使用`CSR8645`替代
2. 运动数据需要进行校准，且刚开启传感器后读取的前数个数据误差较大

