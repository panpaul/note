---
title: 全国大学生信息安全能力竞赛（华中区域赛）部分题目题解
date: 2022-06-25 23:17:44
tags:
- ctf
---

感谢各位师傅的大力支持！~~（最后截止时排名一开始写的`rk1`后来又跳成`rk16`~~

<!-- more -->

## MISC

### PNGCracker3

先`binwalk`，发现`png`文件尾有一段zip压缩包，里面有 `misc.png`

```
86963         0x153B3         Zip archive data, encrypted at least v2.0 to extract, compressed size: 37982, uncompressed size: 40931, name: misc.png
```

同时`png` 文件的 `CRC32` 校验码是错的，通过脚本解出正确的高度：

```python
import os
import binascii
import struct

misc = open("ctf.png", "rb").read()
for i in range(1024):
    data = misc[12:20] + struct.pack('>i', i) + misc[24:29]
    crc32 = binascii.crc32(data) & 0xffffffff
    if crc32 == 0x46A4FDC1:
        print (hex(i))
```

被隐藏的内容就是`misc.png`的密码，flag就在`misc.png`的`LSB`中。

```shell
$ zsteg misc.png
b1,rgb,lsb,xy       .. text: "flag{3bfdf2004fb06399b58998e597781fca}"
```

### ZIPCracker2

解压附件得到一张图片`piazzolla.jpg`和一个`zip`压缩文件，`zip`压缩文件中是一个`flag.txt`文件以及一个与`piazzolla.jpg`相同的图片，因此考虑明文攻击

将`piazzolla.jpg`用`WinRAR`工具压缩为一个`zip`压缩文件，再使用`ARCHPR`工具对附件中的zip压缩文件进行明文攻击
![](upload_e76bf6e5a4c1095a80b33a3e2a2a1e03.png)

成功得到压缩文件密码`crQ2#!`
![](upload_a4fc2a05f16e8bdc5cb13ee6229e5377.png)

将zip压缩文件解压缩后得到`flag.txt`文件，从而得到`flag`，为`flag{310fbb0e6f812d2588689257afa6437d}`
![](upload_40b42113518c062fc604761c2596e2ec.png)

### xpxp1

用二进制编辑器打开，发现疑似是内存文件，找到了一段`python`脚本，是对一个`zip`压缩包进行异或处理。可以从内存中找`zip`的文件头。

```python
f = open('./flag.zip', 'rb').read()
new = open('./fffflllaag.dat', 'ab')

letter = ''
secret = int(letter,16)
print(secret)
for i in f:
    n = int(i) ^ secret
    new.write(int(n).to_bytes(1, 'big'))
```

根据文件头尾找到一个压缩包，解压后得到dat，根据代码是zip压缩包异或后的文件。

爆破异或值，使用`0xa`异或能得到`flag.zip`

`zip`有密码，文件搜索`password`，搜到一段文本，

```
According to Homer's epic, the hero Achilles is the precious son of the mortal Polus and the beautiful fairy Thetis.
It is said that her mother Tethys carried him upside down into the Styx river when he was just born, so that he could be invulnerable. 
Unfortunately, due to the rapid flow of the Ming River, his mother didn't dare to let go of his heel.
The heel held by his mother was accidentally exposed outside the water, so the heel was the most vulnerable place, leaving the only "dead hole" in his body, so he buried the disaster. 
When he grew up, Achilles fought bravely. When he went to attack the city of Troy (the story of Trojan horse slaughtering the city), the brave Achilles singled out the Trojan general Hector, killed him and dragged his body to demonstrate. 
But later, after conquering Troy, Achilles was attacked by an arrow by Hector's brother-in-law Paris and hit his ankle - the hero fell to the ground and died at the moment of shaking.
ankle, ankle, I love ankle.The password is ??k1eAn???
```

根据内容，猜测密码是两个相同单词`Ank1eAnk1e`

解压后得到文本

```
The answer to egg1 is : You are the only weakness in my body
This is also the answer to flag
```

使用工具`volatility`截出`egg1`的文本部分，`egg1`中提示

```
Remember to convert the answer to a 32-bit lowercase MD5 value.
```

用`md5`加密，`md5("You are the only weakness in my body")`即为`flag`

`flag{47155018947fbed1987313fe2d02e0bb}`

### 数据流中的秘密3

`Wireshark`打开后`TCP`追踪流发现是`ADB`协议

可以发现执行的操作有：

1. 发送了一个`ctf.rar`文件
2. 发送了`scrcpy`的`daemon`文件
3. 手机传回了视频

第一步：正确的取出`ctf.rar`文件，这里参考[Github Gist](https://gist.github.com/hfutxqd/a5b2969c485dabd512e543768a35a046)

可以发现每次传送的上限为`64KB`，故需要在发送的数据中查找`DATA + Size`并删除这些协议相关的数据（否则`RAR`校验失败）

第二步：是`Scrcpy`，一个手机投屏软件，使用`H.264`协议传输

手机传的视频流直接用`MPV`打开，发现是一个切开的二维码，将视频截图：

![](upload_9ae266129d2a3e218b5a3022110f95ca.png)

然后用画图拼接回去并扫描，得到了`695c630e-523c-4098-8ff8-0bac8f8b22d7`，也就是`rar`的密码

![](upload_db11e3d2ba790c90349d60e1b36272dc.png)

扫描二维码得到第一步`rar`的密码，其中有一个`.git`文件和一张图片。

`.git`目录下的`config`文件提供了一些线索：一个文本隐写的网站和密码

```
......
[remote "origin"]
	url = https://github.com/KuroLabs/stegcloak.git
	fetch = +refs/heads/*:refs/remotes/origin/*
[branch "master"]
	remote = origin
	merge = refs/heads/master
[password backup]
	password = just4fun

```

对另一个图像使用`strings`得到了一串`BASE32`编码的文本：

```
KRUGKIDXNBSWK3BA4KAI3YUARXRIBDHCQGROFANE4KA2HYUARXRIDIXCQGROFAEN4KAI3YUARTRIDIPCQCG6FAEM4KAI3YUBUHRIBDHCQGROFANC4KAIZYUBULRIBDPCQGROFAEM4KAI3YUBULRIDIPCQCG6FAEM4KA2FYUARXRIDJHCQCG6FANB4KA2HYUARTRIDJHCQGROFAEN4KAI3YUARXRIDIXCQGROFANE4KA2JYUARXRIDJHCQGROFAEM4KA2JYUBUTRIDIPCQCG6FANB4KAI3YUBUTRIDIXCQGSOFAND4KA2DYUARXRIDJHCQCGOFAEN4KA2FYUBUHRIDIXCQCGOFANC4KAIZYUBULRIDIPCQGROFAEN4KAI3YUBUHRIBDPCQCG6FANB4KAIZYUARXRIDIXCQCG6FANB4KAI3YUARTRIDIXCQGROFANE4KAIZYUBUHRIDIXCQGROFANC4KA2HYUARTRIDIXCQCGOFANB4KAI3YUBUTRIDIPCQCGOFANB4KAIZYUBULRIDIPCQCG6FANC4KAI3YUARXRIDIXCQGROFANC4KA2FYUBUTRIDIPCQCG6FANC4KA2DYUBUPRIDJHCQCG6FAND4KAIZYUBULRIBDPCQCGOFAEN4KA2FYUARXRIBDHCQGROFANC4KAI3YUARTRIDIXCQCG6FAEM4KAI3YUARXRIDIXCQGQ6FAEN4KA2HYUBUTRIDIXCQGR6FANC4KA2FYUBUTRIDIPCQCGOFANC4KA2DYUBULRIBDPCQGROFANDOR2XE3TTFQQG433UNBUW4ZZANFZSAZLWMVZCA3TFO4XA====
```

解码后通过上述网站解密得到了`flag`：

![](upload_5d5140222c6ae003d17cb8bbe6c0256d.png)

## RE

### BlueBird

将资源中的`libmy_flutter_plugin_ffi.so`逆向后发现两个函数：`verify`和`proc01`，故猜测最终`flag`需要经过这两个函数校验

抽出核心逻辑并重写代码：

```cpp
size_t proc01(char *a1) {
    size_t n;    // rax
    __int64 len; // rcx
    size_t i;    // rdx
    __int64 v4;  // rsi

    n = strlen(a1);
    len = strlen(a1);
    if ((unsigned int)n <= 0xFuLL) {
        for (i = 0LL; i != len; ++i) {
            n = (unsigned int)(a1[i] >> 4);
            a1[i] = n + (n ^ (a1[i] << 4)) - (n & ~(a1[i] << 4));
        }
        return n;
    }
    n &= 0xFu;
    return n;
}

unsigned char d[33] = {0x86, 0x96, 0x12, 0xC1, 0x03, 0x73, 0x05, 0x96, 0x20, 0x21, 0xC2,
                       0x33, 0xF2, 0x82, 0x06, 0xF7, 0xC7, 0x80, 0xC6, 0x43, 0x52, 0xA0,
                       0x82, 0x03, 0xC2, 0x83, 0xB3, 0x43, 0xA1, 0x50, 0x43, 0xE0, 0x00};

bool verify(char *input, int flag_len) {
    long long cnt; // rsi
    char c_and;    // cl
    char cur;      // cl
    char cur1;     // dl
    char c_or;     // al
    char c_not;    // cl

    proc01(input);
    // flag_len = 32; // strlen(input);

    for (int cnt = 0; cnt < flag_len; cnt++) {
        cur = input[cnt];
        cur1 = input[(cnt + 1) % flag_len];

        c_or = cur | cur1;
        c_not = ~cur;
        if ((cnt & 1) != 0) {
            c_or -= cur1;
            c_and = cur1 & c_not;
        } else {
            c_and = c_not - (c_not | cur1);
        }
        input[cnt] = c_or + c_and;
    }

    return memcmp(input, d, flag_len) == 0;
}
```

可以发现，对于`proc01`中`a1[i] = n + (n ^ (a1[i] << 4)) - (n & ~(a1[i] << 4));`操作实质上为交换`a[i]`的高`4`位和低`4`位

对于`verify`中的操作，是一个循环异或操作，可以用如下代码还原：

```cpp
for (int i = 31; i >= 0; --i) {
    int cur = d[i];
    int nxt = d[(i + 1) % 32];
    d[i] = nxt ^ cur;
}
```

最后逆向出的输入数据是`X0YxdTc3ZXJfUzR2M19UaDNfVzByMWRf`，`base64`解码后发现是`_F1u77er_S4v3_Th3_W0r1d_`，去掉首尾`_`字符后计算`md5`得到`flag{03cd6eb78a6c70f16bfbfd3508f7065f}`

### Crackme2_apk1

将`APK`拖入`JEB`直接可以看到代码，稍微重写一下，发现输入的`encrypt`只与通过复杂计算的`cypherBytes`有关，故直接将加密后数据传入即可获得`flag`

```cpp
#include <bits/stdc++.h>
using namespace std;

string encode(unsigned char encrypt[32], string keys) {
  unsigned char keyBytes[0x100];
  unsigned char cypherBytes[0x100];
  for (int i = 0; i < 0x100; ++i) {
    keyBytes[i] = keys[i % keys.length()];
    cypherBytes[i] = (unsigned char)i;
  }

  int jump = 0;
  for (int i = 0; i < 0x100; ++i) {
    jump = (cypherBytes[i] + jump + keyBytes[i]) & 0xFF;
    unsigned char tmp = cypherBytes[i];
    cypherBytes[i] = cypherBytes[jump];
    cypherBytes[jump] = tmp;
  }

  int i = 0;
  int v3_2 = 0;
  string Result;
  int x;
  for (x = 0; x < 32; ++x) {
    i = (i + 1) & 0xFF;
    unsigned char tmp = cypherBytes[i];
    v3_2 = (v3_2 + tmp + 0x88) & 0xFF;
    unsigned char t = (cypherBytes[v3_2] + tmp) & 0xFF;

    cypherBytes[i] = cypherBytes[v3_2];
    cypherBytes[v3_2] = tmp;

    printf("0x%x ", cypherBytes[t]);

    Result += (encrypt[x] ^ cypherBytes[t]);
  }

  printf("\n");

  return Result;
}

int main() {
    unsigned char v4[] = {0xcd,0x52,0x74,0x7a,0x1e,0x08,0x08,0xe0,0x57,0x3b,0x18,0x99,0xaf,0x3d,0x1d,0x94,0x15,0x25,0x67,0x5b,0x64,0x53,0x1f,0x3b,0xdc,0xa2,0x46,0x36,0xd3,0xfd,0xbe,0x33};
    cout << encode(v4, "happygame") << endl;

    return 0;
}

```

![](upload_74691db7f951a79535bd81d85b649128.png)

最终`flag`为`flag{2fd3d38b20b7bae1f6ed0d70a7df345e}`

### meikyu

按照题面提示，拆出地图跑 `DFS`，接着逆向出需要用 `wasd` 表示路径，把路径 `md5`，`flag{3f48672b213770d9de5c3d50369840a3}`

```python
mp = map_
n, m = len(mp), len(mp[0])
vis = set()
def dfs(x, y, s):
    if x < 0 or x >= n:
        return
    if y < 0 or y >= n:
        return
    if mp[x][y] =='#':
        return
    if (x, y) in vis:
        return
    vis.add((x, y))
    if mp[x][y] == 'E':
        print(s)
    dfs(x - 1, y, s + 'w')
    dfs(x + 1, y, s + 's')
    dfs(x, y - 1, s + 'a')
    dfs(x, y + 1, s + 'd')

dfs(1, 0, '')
```

## Crypto

### LCG

根据 `seed`, `s1`, `s2` 以及 `n`, `b` 解出 `a` 和 `c`:

`a=2004076900`, `c=1600581567`

枚举 `c1` 的低 `16` 位，检查算出来的 `c2`，然后反求出 `flag`

求出了两个可能的 `flag`，各尝试一次，最终提交 `flag{e113de5949ac63d7f21d1aae14f0e8b1}`

```python
from Crypto.Util.number import *
from Crypto.Hash import MD5

b = 3831416627
n = 2273386207
seed = 2403188683
s1 = 260742417
s2 = 447908860
c1 = 17275
c2 = 28951

a = ((s1 - b * seed) - (s2 - b * s1)) * inverse(seed * seed - s1 * s1, n) % n
c = (s1 - a * seed * seed - b * seed) % n

for x in range(1 << 16):
    d1 = c1 << 16 | x
    d2 = (d1 * a + c) % n
    if d2 >> 16 == c2:
        flag = (d1 - c) * inverse(a, n) % n
        if flag < 1 << 31:
            flag += n
        print('flag{' + MD5.new(str(flag).encode()).hexdigest() + '}')
```

### NumberGames

发现模数之间不互质，`gcd` 直接求出因子，倒算出明文后转成字符串，提取 `flag` 拼接，最终 `flag{fb72574404901f5a37f88431b42b4872}`

```python
from Crypto.Util.number import *
from Crypto.Hash import MD5
from binascii import unhexlify

n1 = 12671827609071157026977398418260127577729239910356059636353714138256023623770344437013038456629652805253619484243190436122472172086809006270535958920503788271745182898308583012315393657937467583278528574109842696210193482837553369816110424840884683667932711439417044144625891738594098963618068866281205254024287936360981926173192169919836661589685119695804443529730259703940744061684219737502099455504322939948562185702662485642366411258841082322583213825076942399375712892608077960687636100621655314604756871227708407963698548718981737143081639214928707030543449473132959887760171345393471397998907576088643495456531
e1 = 65537
c1 = 5268497051283009363591890965286255308367378505062739645805302950184343652292967525985407935922935972883557494557593439711003227737116083417992112594428400382187113609935251268634230537282408994938066541612999550555591607744019286392765549844400176442415480559773688439693874264657925123598756193286897112566420847480601040372338338442932524410598834393630019038536173336696498743879160879377504894526001205060753543289059104874467150194596404490638065573974570258671195173327475871936431769234701590572816592485898568463143587137721883610069616008902637316459660001435171054741347142470208082183171637233299493273737
n2 = 18090800828995898324812976370950614944724424095669490324214928162454640462382724191043785592350299626782376411935499259428970532102686361824967300649916495702138825182857737210486173137998811993244590794690070307872074705348982970060304389842338043432383690934814892283936018142382990267868341375956549210694354065317328612440672169232803362481090661368782599819926970968509827001203936933692777821117679448168400620234261164018167404541446201828349880887526076468982840569645753428057937172715073817332736878737709704495317549386111938639861221307607948775421897063976457107356574428602380790814162110473018856344871
e2 = 4097
c2 = 2326267610355516153575986453727161366266816656017644910981028690283132055217271939475840618294311986463011398892570340626131158223217558335139831985973737748812636360601010312490160903427322848411507157238373313053959092326875136396134997877757316339153327290508806645882428114647041522287934007579220769189583249469879165078254248922442084985860374461188259818592181294686890335242981199427715392978546977718475462727987012437677290341463732660152302257234030751774759466703002189003437204934438026047163828083902584763527752033035438078609950665211243112982373167722458975172667665849715372158378299319548194854914
n3 = 14016899139767071357961567514373780608355222973882916699129907806456201886114368147540489514960479836424236595826190295819765979835270500889626994048655508134450908075698567925938340322498944878806273261377551132596295484579752118097281084614987064680928168918147910522922020462762688924459558896249968804885885853885632349539590507675397376494346489972596290270168847103345561743327300964196811506510943971437325302822974593782292850499524055338033832053610217461760698628614971171144300450574522839157187874548994036357212297166759231255765155759405207408315314182166142015547345744054533749334516820850300569790673
e3 = 1048577
c3 = 1507157402302225700443994264641838312753363380677759942918832857396550216927941389943122383728949792984913155517202501504817319345830153748955731880333992875210194306712098593166605310784068299411946792264365247471197716329666415403718297430110977954951479772565341847358286252098930408452594561104228639615640815799731581302607522977457874347224189202268831547055389518214072278766864028489294466057175201908756749666131546163372443691718757198229262989973810951064160488114367967684657242385568733678188829354802025582496625272334309487028498614869964712744826603931510547381997149345221530469380732265014466170524

p1 = GCD(n1, n2)
q1 = n1 // p1
p2 = GCD(n1, n2)
q2 = n2 // p2
p3 = GCD(n2, n3)
q3 = n3 // p3
flag1 = pow(c1, inverse(e1, (p1 - 1) * (q1 - 1)), n1)
flag2 = pow(c2, inverse(e2, (p2 - 1) * (q2 - 1)), n2)
flag3 = pow(c3, inverse(e3, (p3 - 1) * (q3 - 1)), n3)
flag1 = unhexlify(hex(flag1)[2:]).decode().rpartition(':')[-1]
flag2 = unhexlify(hex(flag2)[2:]).decode().rpartition(':')[-1]
flag3 = unhexlify(hex(flag3)[2:]).decode().rpartition(':')[-1]
print(''.join((flag1, flag2, flag3)))
```

## Web

### FakeUpload1

进入题目后是一个文件上传页面，上传正常`jpg`文件后，可以发现图片文件被上传到了`pics`目录下
![](upload_d424696b47d17381a42f434654708411.png)

点击`pics/1.jpg`链接后跳转到`/reader.php?filename=1.php`页面，此时猜测可以使用`GET`参数`filename`的值读取任意文件

同时发现服务器上存在`flag.php`文件，因此使用`/reader.php?filename=flag.php`读取`flag.php`文件内容

在`BurpSuite`上构造该`GET`请求，成功读取到`flag.php`文件内容，得到`flag`，为`flag{ff96523b1124e8645bf4ff223b537f23}`
![](upload_0456b85980dcb27c913485d138e2fdfa.png)

### Identity23

访问网站根目录`/`，在响应头中得到如下字段：`identity: Y0urIdentityAgain`
![](upload_caf6c34b6be310d984539aaba784a994.png)

在请求头中加上该字段，再访问网站根目录，发现网页被重定向到`/A0ther_hldden_PaGe.php`
![](upload_1cd6d4cf451dab9e9d8aa6cb53ab36ba.png)

访问`/A0ther_hldden_PaGe.php`，这是一个文件上传页面
![](upload_fd5bf6c245dcd1606775f5ce1fe9ebc3.png)

尝试上传文件，发现文件后缀名不能出现`php`，文件内容不能出现`?`，并且需要存在字段`Content-Type: image/jpeg`

同时从服务器响应头中的字段`Server: Apache/2.4.7 (Ubuntu)`中可以得知服务器用的是`apache`，因此尝试上传`.htaccess`文件，上传的文件内容是`AddType application/x-httpd-php .png`，表示允许php解析器将该`.htaccess`文件同目录下的`.png`文件当作`.php`文件进行解析
![](upload_08a47fdb4a0784cfaf922ac3f37581ec.png)

经过前面尝试与分析，当文件内容出现`?`时文件无法上传，因此不能在上传的文件内容中写入`<?php`或者`<?`，但是`php`字符未被过滤，因此考虑使用`<script language="php"></script>`代替`<?php ?>`

一开始上传的文件内容是`<script language="php">eval($_GET[a]);</script>`，然而尝试使用该文件`getshell`时发现`system`函数被禁用了，同时因为在服务器中发现存在`flag.php`，所以选择使用`file_get_contents`函数直接读取`flag.php`文件内容，而不需要`getshell`

最后上传任意以`.png`为后缀的文件，文件内容是`<script language="php">print_r(file_get_contents('../flag.php'));</script>`
![](upload_dd74f7e9bbe7e5688efa6a59f9019142.png)

再访问`/pics/10.png`，查看页面源代码，得到`flag`，为`flag{ff0c0aa941aee710cb80679375216614}`
![](upload_7655f3e774b12399f2bb856982aba465.png)
