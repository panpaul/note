---
title: Emby逆向记录
date: 2020-07-21 11:02:37
tags:
- debugging
- hack
---

Emby 是一款~~开源~~的流媒体中心软件，用户只需要简单部署服务端，其它的客户端就能轻松访问服务端的所有媒体。

<!--more-->

**注1：本文所述内容仅限用于学习和研究目的，请支持正版。**

**注2：经评论区反馈，本文所述方法已经失效**

**注3：推荐开源的解决方案——`jellyfin`，这个版本基于`emby`闭源前的工作，由社区维护的开源版本**

首先，关于`Emby`的破解方式，网上普遍流传的方法是通过劫持`mb3admin`来实现破解。在客户端，官方允许使用自签名证书，所以比较容易实现破解；但是在服务端，由于`Emby`使用的是`dotnet`运行时，注入我们自签名的证书相对困难，所以我考虑使用暴力破解的方式处理服务端。

- ### 环境准备

  Emby是使用`C#`编写的跨平台应用，所以我们使用`dnSpy`来进行逆向破解。

- ### 分析目标

  Emby的安装目录下有许多`dll`文件，我们先尝试筛选出目标文件。

  <img src="/images/emby_1.webp" alt="emby_directory">
  
  根据网上流传的传统破解方式，我们将所有文件拖入`dnSpy`后直接搜索`mb3admin`快速定位目标。
  
  <img src="/images/emby_2.webp" alt="emby_dnSpy_search">
  
  可以看到，涉及验证授权的模块主要集中在`Emby.Server.Implementations.Security`和`Emby.Server.Implementations.Updates`中，我们接下来直接研究这两个类即可。
  
- ### 修改代码

  我们先分析`Emby.Server.Implementations.Security`

  定位到目标后发现代码没有反混淆措施，所以我们直接右键-编辑类

  <img src="/images/emby_3.webp" alt="emby_dnSpy_edit">

  一路阅读代码，首先发现`RegisterAppStoreSale`方法，根据名字即内容猜测这个应该是向`emby store`注册，实现付费插件打折的功能？这里直接替换所有内容：

  <img src="/images/emby_4.webp" alt="emby_dnSpy_edit">

  然后发现重要的函数：`IsFeatureAllowed`，这里根据`if`内`IsRegistered`可以猜测注册后应该返回`True`，所以直接更改代码为`return true;`

  <img src="/images/emby_5.webp" alt="emby_dnSpy_edit">

  接着发现两个相关的函数：` GetRegistrationStatus`和` GetRegistrationStatusInternal`，这里应该是用于向其它组件返回注册信息的，一样修改相应代码：

  <img src="/images/emby_6.webp" alt="emby_dnSpy_edit">

  再者，是`UpdateRegistrationStatus`，顾名思义应该是更新注册信息，这里有与服务器交互的部分，直接注释替换掉：

  <img src="/images/emby_7.webp" alt="emby_dnSpy_edit">

  最后修改一些反编译时产生的错误，编译即可。

  接下来分析`Emby.Server.Implementations.Updates`

  通过阅读代码发现不用特意修改代码，直接略过即可。

- ### 一些杂项

  然后破解插件，方法同理。至此，我们的破解已经完成，直接替换修改过的文件就好了。

  <img src="/images/emby_8.webp" alt="emby_success">

- ### 总结与思考

  这里我们暴力修改代码是一种方案，但是仅限于服务端破解，对于客户端，一般常用自建服务器伪装`mb3admin`实现。所以，在破解服务端时我们不妨可以复用自建的服务器，换一种破解思路，将代码里的验证服务器地址修改为自建服务器的地址。

  **最后的最后，本文所述内容仅限用于学习和研究目的，请支持正版。**

