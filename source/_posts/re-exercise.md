---
title: RE练习
date: 2021-04-30 10:42:35
tags:
- ctf
---

最近群里各个方向的师傅都在布置练习，刚好遇到`RE`方向的，用课余时间解决了一下。

<!--more-->

题目：[link](re练习.zip)

# RE1

`RE1`直接拖进`IDA`看`F5`

程序先生成了一个字符表：`A-Z a-z 0-9`

![image-20210429233022204.png](image-20210429233022204.png)

然后通过一个`for`循环对输入的数据进行处理，这里可以重写一下这个循环：

```c
for (k = 0; k < v7; k += 3)
{
    v9 = Buffer[k];
    v10 = Buffer[k + 1];
    v12 = Buffer[k + 2];
    v11 = k / 3u;
    byte_C033E8[4 * v11] |= v9 >> 2;
    byte_C033E8[4 * v11 + 1] |= (v10 >> 4) | (16 * (v9 & 3));
    byte_C033E8[4 * v11 + 2] |= (v12 >> 6) | (4 * (v10 & 0xF));
    byte_C033E8[4 * v11 + 3] = v12 & 0x3F;
}
```

处理完后，根据字母表做一次变换：

![image-20210429233316839](image-20210429233316839.png)

最后按位比对数据，其中`byte_C0215C`位常量：`T3dheXNfQl9hd2FyZV9vZl9DYXMzXzY0`

这题难度在于推到前面的变换，但是，`ASCII`字符不多，可以爆破:)

爆破脚本：

```c
#include <stdio.h>
#include <stdint.h>

int convert(int x)
{
    if (x >= 'A' && x <= 'Z') // A-Z
        return x - 'A';
    else if (x >= 'a' && x <= 'z')
        return x - 'a' + 26;
    else // 0-9
        return x - '0' + 26 * 2;
}

int main()
{
    char test[] = "T3dheXNfQl9hd2FyZV9vZl9DYXMzXzY0";
    uint8_t cmp[50] = {0};

    for (int i = 0; i < 33; i++)
        test[i] = convert(test[i]); // 对应于IDA逆向代码中的43 44行，先按字母表还原
    for (int i = 0; i < 33; i++)
        printf("%d ", test[i]);
    printf("\n");

    for (int i = 0; i < 24;)
    {
        for (uint8_t a = 1; a <= 127; a++)
            for (uint8_t b = 1; b <= 127; b++)
                for (uint8_t c = 1; c <= 127; c++) // 直接爆破
                {
                    if (test[i / 3 * 4] != (a >> 2)) // 这里对应于生成时的逻辑
                        continue;
                    if (test[i / 3 * 4 + 1] != ((b >> 4) | (16 * (a & 3))))
                        continue;
                    if (test[i / 3 * 4 + 2] != ((c >> 6) | (4 * (b & 0xF))))
                        continue;
                    if (test[i / 3 * 4 + 3] != (c & 0x3f))
                        continue;

                    cmp[i] = a;
                    cmp[i + 1] = b;
                    cmp[i + 2] = c;
                    goto out;
                }
    out:
        i += 3;
    }

    printf("%s\n", cmp);
    for (int i = 0; i < 24; i++)
        printf("%d ", cmp[i]);

    printf("\n");
}
```

最后结果：

![image-20210429233746969](image-20210429233746969.png)

![image-20210429233730793](image-20210429233730793.png)

# RE2

看文件`logo`怀疑是`pyinstaller`打包的程序，所以使用[PyInstaller Extractor](https://github.com/extremecoders-re/pyinstxtractor)解包

![image-20210429214327795](image-20210429214327795.png)

然后在目录下发现可疑文件`py.pyc`

尝试使用[decompile3](https://github.com/rocky/python-decompile3)反编译，但是发现了报错

![image-20210429214746928](image-20210429214746928.png)

经百度，发现在`pyinstaller`打包时常见的混淆措施是修改`pyc`文件文件头

![image-20210429214950665](image-20210429214950665.png)

经过比对`py.pyc`和一个不太可能被混淆的库函数文件`struct.pyc`发现二者文件头魔数不一样，所以，直接修改`py.pyc`的文件头。成功反编译出`py.pyc`的源代码：

```python
# decompyle3 version 3.3.2
# Python bytecode 3.8 (3413)
# Decompiled from: Python 3.8.8 (default, Apr 13 2021, 15:08:03) [MSC v.1916 64 bit (AMD64)]
# Embedded file name: py.py
import sys

# 校验长度为12位且内容为0123456789abcdef
def func0(password):
    s = '0123456789abcdef'
    if len(password) != 16:
        print('wrong!')
        sys.exit(0)
    for i in range(16):
        if password[i] not in s:
            print('wrong!')
            sys.exit(0)

# 将数据4位一组按十六进制数进行解析
def func1(password):
    data = []
    for i in range(0, len(password), 4):
        data.append(int(password[i:i + 4], 16))
    else:
        return data

# 魔改的TEA
def func2(value):
    v0, v1 = value[0], value[1]
    k0, k1, k2, k3 = (4660, 22136, 37035, 52719) # cache key
    delta = 2654435769
    su = 0
    # 4294967295 == 2^32 - 1 下面限制为32位数运算
    for i in range(16):
        su = su + delta & 4294967295 # 注意python运算符优先级 这里相当于(su + delta) & 4294967295
        v0 += (v1 << 4) + k0 ^ (v1 >> 5) + k1 ^ v1 + su
        v0 &= 4294967295
        v1 += (v0 << 4) + k2 ^ (v0 >> 5) + k3 ^ v0 + su
        v1 &= 4294967295
    else:
        value[0] = v0
        value[1] = v1

# 简单比较
def func3(data):
    check = [2878344157,
     3987636344,
     363414259,
     2008918208]
    for i in range(len(data)):
        if check[i] != data[i]:
            print('wrong!')
            sys.exit(0)


def func4(key):
    s = [0] * 256
    t = [0] * 256
    j = 0
    for i in range(256):
        s[i] = i
        t[i] = ord(key[(i % len(key))])
    else:
        for i in range(256):
            j = (j + s[i] + t[i]) % 256
            s[i], s[j] = s[j], s[i]
        else:
            return s

def func5(data, key):
    s = func4(key)
    i = j = 0
    for n in range(len(data)):
        i = (i + 1) % 256
        j = (j + s[i]) % 256
        s[i], s[j] = s[j], s[i]
        pos = (s[i] + s[j]) % 256
        data[n] = ord(data[n]) ^ s[pos]


def func6(flag):
    if len(flag) != 39:
        print('wrong!')
        sys.exit(0)
    check = [165, 121, 217, 113, 173, 235, 216, 84, 239, 221, 68, 221, 163, 87, 255, 90, 145, 129,
     254, 60, 193, 217, 150, 9, 79, 147, 223, 182, 39, 5, 225, 48, 220, 125, 15, 94,
     249, 238, 126]
    for i in range(39):
        if check[i] != flag[i]:
            print('wrong!')
            sys.exit(0)


if __name__ == '__main__':
    print('Do you know tea?')
    password = input('Plz input the password:')
    func0(password)
    data = func1(password)
    for i in range(0, len(data), 2):
        value = [
         data[i], data[(i + 1)]]
        func2(value)
        data[i], data[i + 1] = value[0], value[1]
    else:
        func3(data)
        print('Do you know rc4?')
        flag = list(input('Plz input the flag:'))
        func5(flag, password)
        func6(flag)
        print('You got it!')
# okay decompiling py.pyc

```

接着开始分析代码，输入的`密码`首先进行合法性验证(`func0`)，这里要求长度`16`位且内容在`0123456789abcdef`中

校验后将数据传入`func1`，`func1`的作用是将每`4`位作为一个十六进制数进行解析，将数据放入`data`数组中

然后按照每两个十六进制数为一组，传入`func2`进行处理，这个`func2`函数，根据提示怀疑是`TEA`算法，不过进行了魔改，那么，按照原来`TEA`解密的思路，依葫芦画瓢写一个解密函数：

```python
def defunc2(value):
    v0, v1 = value[0], value[1]
    k0, k1, k2, k3 = (4660, 22136, 37035, 52719)
    delta = 2654435769
    su = 3816266640
    for i in range(16):
        v1 -= (v0 << 4) + k2 ^ (v0 >> 5) + k3 ^ v0 + su
        v1 &= 4294967295
        v0 -= (v1 << 4) + k0 ^ (v1 >> 5) + k1 ^ v1 + su
        v0 &= 4294967295
        su = su - delta & 4294967295
    else:
        value[0] = v0
        value[1] = v1
```

第一个`for`循环将传入的值使用魔改的`TEA`函数加密了，接着看`else`部分

`func3`就是一个简单比对，所以直接写解密脚本：

```python
# 不怎么会python, 代码写得丑...
check1 = [2878344157, 3987636344]
check2 = [363414259, 2008918208]
defunc2(check1)
defunc2(check2)
key = check1 + check2
list(map(hex, key))
# ['0x1a2b', '0x3c4d', '0x5e6f', '0x7890']
```

所以第一部分的密码是：`1a2b3c4d5e6f7890`

然后提示输入了`flag`并将结果切开成数组传入`func5`

而在`func5`中，先把前面的密码(`1a2b3c4d5e6f7890`)传入到了`func4`

先不管`func4`逻辑是什么，直接跑一遍得到了结果：

```python
[136, 87, 148, 51, 65, 6, 203, 55, 212, 27, 94, 61, 198, 93, 131, 104, 38, 18, 208, 9, 17, 199, 77, 107, 15, 20, 62, 8, 36, 3, 115, 151, 232, 106, 37, 59, 144, 190, 124, 119, 100, 242, 82, 227, 243, 10, 139, 30, 169, 91, 152, 95, 33, 48, 189, 39, 116, 206, 45, 74, 128, 109, 178, 29, 213, 141, 120, 113, 209, 156, 60, 230, 210, 114, 214, 56, 145, 76, 166, 81, 78, 4, 223, 244, 160, 88, 226, 80, 31, 229, 177, 254, 92, 84, 153, 44, 159, 121, 235, 224, 172, 68, 155, 167, 118, 75, 202, 127, 137, 22, 252, 14, 211, 40, 67, 83, 162, 72, 215, 234, 123, 163, 46, 179, 111, 187, 24, 11, 191, 170, 218, 255, 220, 248, 112, 23, 52, 238, 204, 239, 122, 132, 197, 146, 35, 34, 231, 103, 53, 250, 182, 247, 196, 221, 79, 140, 105, 7, 13, 183, 168, 5, 70, 71, 0, 225, 184, 195, 161, 26, 237, 245, 240, 73, 149, 217, 165, 117, 58, 50, 43, 251, 188, 90, 157, 236, 12, 142, 97, 108, 133, 200, 228, 19, 164, 175, 110, 57, 16, 216, 143, 181, 201, 25, 2, 64, 207, 138, 125, 28, 176, 147, 173, 246, 1, 41, 253, 193, 180, 192, 205, 194, 135, 171, 69, 222, 130, 249, 47, 86, 99, 32, 150, 63, 85, 101, 158, 54, 185, 233, 219, 42, 66, 241, 96, 126, 98, 134, 129, 21, 49, 174, 186, 154, 89, 102]
```

在`func5`中，按照一定的逻辑将`func4`的结果进行了变换然后和输入进行异或，所以改造一下获取异或的数：

```python
def defunc5(key):
	data = []
	s = func4(key)
	i = j = 0
	for n in range(39): # 看func6
		i = (i + 1) % 256
		j = (j + s[i]) % 256
		s[i], s[j] = s[j], s[i]
		pos = (s[i] + s[j]) % 256
		data.append(s[pos])
	return data
```

得到结果

```python
[195, 21, 184, 22, 214, 162, 135, 51, 154, 238, 55, 232, 252, 46, 207, 47, 206, 234, 216, 83, 150, 134, 226, 108, 46, 204, 159, 216, 67, 90, 147, 83, 232, 34, 97, 110, 142, 207, 3]
```

而在`func6`中给出了异或后的结果，根据异或的可逆性，可以直接解密：

```python
check = [165, 121, 217, 113, 173, 235, 216, 84, 239, 221, 68, 221, 163, 87, 255, 90, 145, 129,
    254, 60, 193, 217, 150, 9, 79, 147, 223, 182, 39, 5, 225, 48, 220, 125, 15, 94, 249, 238, 126]
ori = [195, 21, 184, 22, 214, 162, 135, 51, 154, 238, 55, 232, 252, 46, 207, 47, 206, 234, 216,
	83, 150, 134, 226, 108, 46, 204, 159, 216, 67, 90, 147, 83, 232, 34, 97, 110, 142, 207, 3]
data = []
for i in range(len(check)):
	data.append(chr(check[i] ^ ori[i]))

''.join(data)
# 'flag{I_gu3s5_y0u_k&oW_tea_@nd_rc4_n0w!}'
```

![image-20210429224052094](image-20210429224052094.png)

（但是，题目中好像并没有要求理解`rc4`的内容....）

# RE3

写在前面：`RE3`这道题让我开拓了眼界，`Win32`竟然有一套类似于`try-catch`的机制....而且滥用中断机制可以做好多事情....

首先拖入`IDA`

上来就是一个最大公约数...

![image-20210429224326095](image-20210429224326095.png)

（这里`v3`，`v4`的值做了修改）

这个求公约数的东西在原来的程序里保证下面的`if`条件恒为真，经过**分析**后续工作流程发现我们并不希望这里的代码被执行，所以直接用`keypatch`将`v3`和`v4`改了，使这个`if`无法进入(其实也可以大段`nop`)

然后下面添加了两个异常处理函数：

![image-20210429224550267](image-20210429224550267.png)

加上下面那句话：

> OMG a widow is somewhere! find it out!

可以判断这两个异常处理函数里面可能有真正的逻辑

先看第一个处理函数`RE3_DivZeroHandler`（我这里重命名了）

![dbg2](dbg2.png)

里面有一句十分~~挑衅~~的反调试提示，直接将`jz`改成`jmp`绕过

![dbg2.1](dbg2.1.png)

然后看一下汇编（其实这个`F5`的结果不便于分析）

![image-20210429225051067](image-20210429225051067.png)

大致的逻辑就是将`RE3_StaticChar`中的数据按顺序分别从`0`到`45H`异或一遍，这里采用动态调试的手段可以提取出异或完成的数据：

```c
uint8_t RE3_StaticChar[] = {
    0x61, 0x5F, 0x70, 0x58, 0x78, 0x6D, 0x55, 0x75, 0x6A, 0x52,
    0x72, 0x67, 0x4F, 0x6F, 0x6E, 0x4C, 0x6C, 0x6B, 0x49, 0x69,
    0x68, 0x46, 0x66, 0x65, 0x43, 0x63, 0x62, 0x39, 0x5A, 0x59,
    0x36, 0x57, 0x56, 0x33, 0x54, 0x53, 0x30, 0x51, 0x50, 0x7A,
    0x4E, 0x4D, 0x77, 0x4B, 0x4A, 0x74, 0x48, 0x47, 0x71, 0x45,
    0x44, 0x64, 0x42, 0x41, 0x2F, 0x38, 0x37, 0x79, 0x35, 0x34,
    0x76, 0x32, 0x31, 0x73, 0x00};
```

而这个函数是如何进入的呢？

![image-20210429225304182](image-20210429225304182.png)

在这里我们发现了一个故意的除以`0`的操作，这里发生了异常，然后被捕捉到了...

在上面的处理函数里，通过触发`45H`次异常完成了`for`循环操作，然后最后一次

![image-20210429225452115](image-20210429225452115.png)

通过修改`edx`使得这里不会再发生除以零的异常。

在完成所有的除以`0`的异常后，跟来了一个`int 3`断点中断，这里会跳转到`RE3_BPHandler`处

在解决这个函数时，要结合汇编代码和`F5`逆向出的`C`代码，逆向的效果感觉不太好，省略了许多信息

![image-20210429230951455](image-20210429230951455.png)

程序先在一个常量字符串中找当前输入的字符的下标，其中`RE3_StaticChar`在`RE3_DivZeroHandler`中已经处理过了：

> a_pXxmUujRrgOonLlkIihFfeCcb9ZY6WV3TS0QPzNMwKJtHGqEDdBA/87y54v21s

![image-20210429231202407](image-20210429231202407.png)

扫描一遍发现这个字母表包含了大小写字母、数字、`/`和`_`，这里限定了输入的范围

![image-20210429231332393](image-20210429231332393.png)

在找到当前字符对应的下标后，跳转到`loc_BA1100`继续

这里分析比较烦的是：要记住这个中断会被多次触发，形成了一个大的循环，在这里`RE3_CNT`和`RE3_ArrayIdx`都是通过在一次函数调用时更新一次

这个`loc_BA1100`的意思就是把找到的下标(`uint8_t`)四个一组放到`RE3_ArrayBase`中(`uint32_t`)

在完成`4`次取数后进入`RE3_CMP2`的生成逻辑中

![image-20210429231731895](image-20210429231731895.png)

这里重写一遍，逻辑如下：

```c
// transform 为一个map, 保存了下标的映射关系
// p q m n 分别为4个下标, 对应RE3_ArrayBase, BYTE1(RE3_ArrayBase), BYTE2(RE3_ArrayBase), HIBYTE(RE3_ArrayBase)
// k为RE3_CNT
RE3_CMP2[k / 4 * 3] = ((transform[q] >> 4) | (4 * transform[p]));
RE3_CMP2[k / 4 * 3 + 1] = ((16 * transform[q]) | (transform[m] >> 2));
RE3_CMP2[k / 4 * 3 + 2] = (transform[n] | (transform[m] << 6));
```

这里我们可以继续分析：前面找下标时已经发现下标`<64`，且为`8`位数，所以可以表示为`00xx xxxx`的形式

```
CMP2[k / 4 * 3]
>> 4 0000 00xx q
<< 2 xxxx xx00 p
p = [0] >> 2

RE3_CMP2[k / 4 * 3 + 1]
<< 4 xxxx 0000 q
>> 2 0000 xxxx m
q = ([0] & 3) << 4 | ([1] >> 4)
m: ??xxxx?? = [1] & 0xf

RE3_CMP2[k / 4 * 3 + 2]
|| 0 00xx xxxx n
<< 6 xx00 0000 m
n = [2] & 0x3f
m = (([1] & 0xf) << 2) | (([2] &0xc0) >> 6)
```

在限制条件下我们可以根据`CMP2`的数据推出输入：

```c
input[k] = RE3_CMP1[k / 4 * 3] >> 2;                                                             // p
input[k + 1] = ((RE3_CMP1[k / 4 * 3] & 3) << 4) | (RE3_CMP1[k / 4 * 3 + 1] >> 4);                // q
input[k + 2] = ((RE3_CMP1[k / 4 * 3 + 1] & 0xf) << 2) | ((RE3_CMP1[k / 4 * 3 + 2] & 0xc0) >> 6); // m
input[k + 3] = RE3_CMP1[k / 4 * 3 + 2] & 0x3f;                                                   // n
```

在处理函数的尾部，一样的套路，如果完成了循环，那么就修改`EIP`执行下一条代码，反之继续触发中断

![image-20210429232607277](image-20210429232607277.png)

最后回到主函数，发现程序比对了`CMP1`和`CMP2`

![image-20210429232731274](image-20210429232731274.png)

通过动态调试可以拿到`RE3_CMP1`的数据：

```c
uint8_t RE3_CMP1[] = {
    0x7D, 0x3C, 0xE4, 0xAB, 0xF0, 0x64, 0xA0, 0x17, 0xD3, 0x39,
    0xA9, 0x2A, 0xFC, 0x18, 0x7D, 0x00};
```

最后，直接根据上述思路写解密代码：

```c
#include <stdio.h>
#include <stdint.h>
#include <map>

uint8_t RE3_StaticChar[] = {
    0x61, 0x5F, 0x70, 0x58, 0x78, 0x6D, 0x55, 0x75, 0x6A, 0x52,
    0x72, 0x67, 0x4F, 0x6F, 0x6E, 0x4C, 0x6C, 0x6B, 0x49, 0x69,
    0x68, 0x46, 0x66, 0x65, 0x43, 0x63, 0x62, 0x39, 0x5A, 0x59,
    0x36, 0x57, 0x56, 0x33, 0x54, 0x53, 0x30, 0x51, 0x50, 0x7A,
    0x4E, 0x4D, 0x77, 0x4B, 0x4A, 0x74, 0x48, 0x47, 0x71, 0x45,
    0x44, 0x64, 0x42, 0x41, 0x2F, 0x38, 0x37, 0x79, 0x35, 0x34,
    0x76, 0x32, 0x31, 0x73, 0x00};

uint8_t RE3_CMP1[] = {
    0x7D, 0x3C, 0xE4, 0xAB, 0xF0, 0x64, 0xA0, 0x17, 0xD3, 0x39,
    0xA9, 0x2A, 0xFC, 0x18, 0x7D, 0x00};

std::map<uint8_t, uint8_t> m1;

int main()
{
    printf("%s\n", RE3_StaticChar);
    for (int i = 0; i < 64; i++)
        m1[i] = RE3_StaticChar[i];

    uint8_t input[50] = {0};

    for (int k = 0; k < 20; k += 4)
    {
        input[k] = RE3_CMP1[k / 4 * 3] >> 2; // p
        input[k + 1] = ((RE3_CMP1[k / 4 * 3] & 3) << 4) | (RE3_CMP1[k / 4 * 3 + 1] >> 4); // q
        input[k + 2] = ((RE3_CMP1[k / 4 * 3 + 1] & 0xf) << 2) | ((RE3_CMP1[k / 4 * 3 + 2] & 0xc0) >> 6); // m
        input[k + 3] = RE3_CMP1[k / 4 * 3 + 2] & 0x3f; // n
    }
    for (int i = 0; i < 20; i++)
        printf("%c", m1[input[i]]);
    printf("\n");
    for (int i = 0; i < 20; i++)
        printf("(%d,%c) ", input[i], m1[input[i]]);
    printf("\n");
    return 0;
}
```

![image-20210429232852959](image-20210429232852959.png)

![image-20210429232918001](image-20210429232918001.png)

