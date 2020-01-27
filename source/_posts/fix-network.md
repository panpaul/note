---
title: fix binding port error on Windows
date: 2020-01-03 22:14:36
tags:
- windows
- hyper-v
- network
---

Having installed Hyper-V on my machine, I found that I couldn't start up Tomcat.

It warns me that port 1099 is in use.

And here is my debugging note.

<!--more-->

1. First of all, check whether there are some programs occupying the port.

   ```shell
   netstat -ano | find "1099"
   ```

   Unfortunately, I found nothing.

2. Secondly, check the dynamic port range

   ```shell
   netsh int ipv4 show dynamicport tcp
   ```

   which might give an output like this:

   ```
   协议 tcp 动态端口范围
   ---------------------------------
   启动端口        : 1024
   端口数          : 13977
   ```

   It seems that installing Hyper-V will change the value and you could change this back to the default value by executing the command below

   ```shell
   netsh int ipv4 set dynamicportrange tcp start=49152 num=16384
   ```

   However, it seems that there are no effects.

3. Third, check whether the port is reserved by Hyper-V

   ```shell
   netsh interface ipv4 show excludedportrange protocol=tcp
   ```

   which might give an output like this:

   ```
   协议 tcp 端口排除范围
   
   开始端口    结束端口
   ----------    --------
         1066        1165
         1366        1465
         1666        1765
         5357        5357
         5700        5700
         8155        8254
         8884        8884
        12437       12536
        14493       14592
        50000       50059     *
   
   * - 管理的端口排除。
   ```

   And we can see that port 1099 is in the excluded list and we can only change tomcat's port or disable Hyper-V to solve this problem.
