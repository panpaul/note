---
title: 在树莓派上点亮0.96寸OLED显示屏
date: 2022-02-17 16:54:59
tags:
- Raspberry Pi
---

刚刚开学有一些空闲的时间，加上手头上刚好有一个吃灰派和一个`SSD1315`显示屏，于是研究了一下

<!--more-->

先放一个成品图：

<img src="show.webp" alt="show" style="zoom:40%;" />

这块屏幕是淘宝上买的`SSD1315 0.96 OLED`屏，只提供了`I2C`接口，店家宣称兼容`SSD1306`（？）

以此为关键词在百度上可以搜索到许多直接使用`I2C`驱动的样例。但是，我最近在更新`eeprom`的时候发现`boot`目录下的`overlay`中提供了一个`ssd1306`的设备驱动，于是我想通过驱动的形式加载这块显示屏，绕过手动通过`I2C`发送初始化指令的过程

这一个驱动将提供一个`framebuffer`设备，可以通过向`/dev/fbX`写入二进制的图像数据来控制显示内容，也可以将设备终端映射到这块设备上

首先开启相关内核模块，修改`/boot/config.txt`：

```ini
# 加载 SSD1306 模块, inverted 即反转字节顺序, 与其它工具生成的图像保持兼容
dtoverlay=ssd1306,inverted
# 可选：加快 I2C 时钟
dtparam=i2c_baudrate=400000
```

保存后重启可以发现`/dev`目录下多了一个`fb1`设备（`fb0`是我外接的显示器）

<img src="fb1.webp" alt="fb1" style="zoom:85%;" />

我们可以使用`fbset`指令查看这个设备的详细信息：

```bash
➜  ~ fbset -i -fb /dev/fb1

mode "128x64"
    geometry 128 64 128 64 1
    timings 0 0 0 0 0 0 0
    rgba 1/0,1/0,1/0,0/0
endmode

Frame buffer device information:
    Name        : Solomon SSD1307
    Address     : 0x4900f000
    Size        : 1024
    Type        : PACKED PIXELS
    Visual      : MONO10
    XPanStep    : 0
    YPanStep    : 0
    YWrapStep   : 0
    LineLength  : 16
    Accelerator : No
```

可以发现这里加载的是`SSD1307`的驱动(`SSD1315` -> `SSD1306` -> `SSD1307` :cry:)无论如何，能够互相兼容即可

首先尝试在屏幕中间输出一个`Hello World`，这里使用`ImageMagick`提供的`convert`工具将字符转换为图像：

```bash
convert -size 128x64 -depth 1 xc:white -fill black -font "Source-Code-Pro" -pointsize 14 -annotate +0+32 "Hello World" mono:- > /dev/fb1
```

(这里就不放截图了)

这个工具并不是特别的好用：首先是字体不便调整，其次不方便排版。所以不妨手写一个吧！

首先生成字库：

相关的工具有很多，我找到了一个在线工具：[LCD/OLED字模提取软件,ASCII字符8*16点阵字库](https://www.23bei.com/tool-226.html)。需要注意"取模方式"参数：**横向8点右高位**（在配置驱动的时候使用了`inverted`参数）

这个工具生成了`8*16`的点阵`ASCII`字符画，每个字符有`16`个元素对应`16`行，每行一个`8`位`0/1`数据表示点阵

其次编写操作`/dev/fb1`的代码：

```c++
extern uint8_t fontData[];     // 字库数据
extern std::string statInfo(); // 获取要显示的内容

static volatile bool keepRunning = true;

void sig_handler(int sig)
{
    if (sig == SIGINT) // 遇到 Ctrl + C 退出程序
        keepRunning = false;
}

int main(int argc, char** argv)
{
    signal(SIGINT, sig_handler);

    // 打开并或者设备信息
    auto fd = open("/dev/fb1", O_RDWR);

    struct fb_var_screeninfo screenInfo{};
    ioctl(fd, FBIOGET_VSCREENINFO, &screenInfo);

    auto width = screenInfo.xres;
    auto widthChar = width / 8; // 横向宽度 8 bit 一个字符，刚好对应一个char
    auto height = screenInfo.yres;

    std::cout << "Bits/Pixel = " << screenInfo.bits_per_pixel << std::endl;
    std::cout << "Width      = " << width << std::endl;
    std::cout << "Height     = " << height << std::endl;

    auto fontChar = [=](char c, unsigned line) // 获取字库中的信息
    {
        if (c < ' ' || c > '~' || line >= 16) return static_cast<uint8_t>(0); // 字库只生成了ASCII可见字符，对于不可见字符用空白替换
        else return fontData[(c - ' ') * 16 + line]; // 一个字符有 16 行
    };

    // 将 framebuffer 通过 mmap 映射到用户空间，类型自然是 uint8_t 数组
    auto data = reinterpret_cast<uint8_t*>(mmap(nullptr, width * height, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0));
    while (keepRunning)
    {
        auto outputString = statInfo();
        std::cout << "string to print: " << outputString << std::endl;

        auto idx = 0;               // 记录当前输出到了第一个字符
        auto finish = [=](int idx)  // 判断字符串是否输出完毕
        { return idx >= outputString.length(); };

        for (auto row = 0; row < height; row += 16)           // 遍历行（字符），至多有 64 / 16 = 4 行字符
            for (auto col = 0; col < widthChar; col++, idx++) // 遍历列，每行至多显示 128 / 8 = 16 个字符
                for (auto i = 0; i < 16; i++)                 // 遍历字符的行
                    // 如果字符串打印完了就用空白填充
                    data[(row + i) * widthChar + col] = fontChar(finish(idx) ? ' ' : outputString[idx], i);

        std::this_thread::sleep_for(std::chrono::seconds(1)); // 一秒一刷新
    }

    // 清理资源
    munmap(data, width * height);
    close(fd);
    return 0;
}
```

至于要显示的具体内容，我主要获取了三个参数：时间、`CPU`占用、内存占用。我通过`popen`来获取执行命令的结果来拼接参数：

```c++
void runCmd(const std::string& command, std::ostringstream& outputStream)
{ // 执行命令并将输出写入到流中
    auto fd = popen(command.c_str(), "r");
    if (fd == nullptr) return;

    char buffer[128];
    while (fgets(buffer, sizeof(buffer), fd))
    {
        auto inputLine = buffer;
        outputStream << inputLine;
    }

    pclose(fd);
}

std::string statInfo()
{
    std::ostringstream info;
    info << "< Rasp Monitor >"; // 标题行

    // 获取 IP 地址
    std::string cmdGetDateTime;
    cmdGetDateTime = R"lit(date '+ %m-%d %H:%M:%S ' | awk '{printf(" %s %s ", $1, $2)}')lit";
    runCmd(cmdGetDateTime, info);

    // 获取 CPU 占用率
    std::string cmdGetCPU;
    cmdGetCPU =
        R"lit(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{printf("CPU: %10.2f%%", 100-$1)}')lit";
    runCmd(cmdGetCPU, info);

    // 获取内存占用量
    std::string cmdGetMem;
    cmdGetMem =
        R"lit(awk '/MemAvailable/{free=$2} /MemTotal/{total=$2} END {printf("MEM: %10.2f%%", 100-(free*100)/total)}' /proc/meminfo)lit";
    runCmd(cmdGetMem, info);

    return info.str();
}

```

编译后用`nohup`丢到后台执行即可

最后，这里这个绘制图像的过程个人感觉过于简陋，如果有空的话可以研究一下专为`Arduino`设计的字符模块：[u8g2](https://github.com/olikraus/u8g2)，其自带多种排版输出功能（图标/文字）

== 完 ==
