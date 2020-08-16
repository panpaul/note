---
title: 记一次matlab升级错误
date: 2020-03-19 13:11:10
updated: 2020-08-10 15:30:00
tags:
- matlab
- network
mathjax: false
---

最近(~~很久以前~~)`matlab`发布了`update5`补丁包，但是在升级时出现了异常情况，错误信息可谓是言简意赅：

<!--more-->

> 出现了异常情况。: 这并不常见。

这是什么错误？

所以马上想到找日志文件，其文件路径应该为`%USERPROFILE%\AppData\Local\Temp\mathworks_YOURNAME.log`

在日志文件里有相对详细的错误信息，比如说我遇到的错误是：

>  出现了异常情况。: 这并不常见。
>  要解决此问题，请与技术支持联系。
>  	at com.mathworks.update_installer.ExceptionHandlerImpl.createUpdateInstallerException(Unknown Source)
>  	at com.mathworks.update_installer.ExceptionHandlerImpl.processException(Unknown Source)
>  	at com.mathworks.update_installer.UpdateInstallerService.updateInstallation(Unknown Source)
>  	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
>  	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
>  	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
>  	at java.lang.reflect.Method.invoke(Method.java:498)
>  	at com.mathworks.installservicehandler.JsonPassThroughResponseWrapper.getData(JsonPassThroughResponseWrapper.java:24)
>  	at com.mathworks.installservicehandler.JsonPassThroughResponseWrapper.getData(JsonPassThroughResponseWrapper.java:10)
>  	at com.mathworks.laisserver.impl.helper.RequestHandler.handleRequest(RequestHandler.java:44)
>  	at com.mathworks.laisserver.impl.JsonServlet.doPost(JsonServlet.java:27)
>  	at javax.servlet.http.HttpServlet.service(HttpServlet.java:755)
>  	at javax.servlet.http.HttpServlet.service(HttpServlet.java:848)
>  	at org.eclipse.jetty.servlet.ServletHolder.handle(ServletHolder.java:669)
>  	at org.eclipse.jetty.servlet.ServletHandler.doHandle(ServletHandler.java:457)
>  	at org.eclipse.jetty.server.handler.ScopedHandler.handle(ScopedHandler.java:137)
>  	at org.eclipse.jetty.security.SecurityHandler.handle(SecurityHandler.java:557)
>  	at org.eclipse.jetty.server.session.SessionHandler.doHandle(SessionHandler.java:231)
>  	at org.eclipse.jetty.server.handler.ContextHandler.doHandle(ContextHandler.java:1075)
>  	at org.eclipse.jetty.servlet.ServletHandler.doScope(ServletHandler.java:384)
>  	at org.eclipse.jetty.server.session.SessionHandler.doScope(SessionHandler.java:193)
>  	at org.eclipse.jetty.server.handler.ContextHandler.doScope(ContextHandler.java:1009)
>  	at org.eclipse.jetty.server.handler.ScopedHandler.handle(ScopedHandler.java:135)
>  	at org.eclipse.jetty.server.handler.ContextHandlerCollection.handle(ContextHandlerCollection.java:255)
>  	at org.eclipse.jetty.server.handler.HandlerWrapper.handle(HandlerWrapper.java:116)
>  	at org.eclipse.jetty.server.Server.handle(Server.java:364)
>  	at org.eclipse.jetty.server.AbstractHttpConnection.handleRequest(AbstractHttpConnection.java:488)
>  	at org.eclipse.jetty.server.AbstractHttpConnection.content(AbstractHttpConnection.java:943)
>  	at org.eclipse.jetty.server.AbstractHttpConnection$RequestHandler.content(AbstractHttpConnection.java:1004)
>  	at org.eclipse.jetty.http.HttpParser.parseNext(HttpParser.java:861)
>  	at org.eclipse.jetty.http.HttpParser.parseAvailable(HttpParser.java:240)
>  	at org.eclipse.jetty.server.AsyncHttpConnection.handle(AsyncHttpConnection.java:82)
>  	at org.eclipse.jetty.io.nio.SelectChannelEndPoint.handle(SelectChannelEndPoint.java:628)
>  	at org.eclipse.jetty.io.nio.SelectChannelEndPoint$1.run(SelectChannelEndPoint.java:52)
>  	at org.eclipse.jetty.util.thread.QueuedThreadPool.runJob(QueuedThreadPool.java:608)
>  	at org.eclipse.jetty.util.thread.QueuedThreadPool$3.run(QueuedThreadPool.java:543)
>  	at java.lang.Thread.run(Thread.java:748)
>  Caused by: java.io.EOFException: Truncated ZIP entry: bin/win64/builtins/sl_services_mi/mwlibmwsl_services_mi_builtinimpl.dll
>  	at org.apache.commons.compress.archivers.zip.ZipArchiveInputStream.drainCurrentEntryData(ZipArchiveInputStream.java:619)
>  	at org.apache.commons.compress.archivers.zip.ZipArchiveInputStream.closeEntry(ZipArchiveInputStream.java:583)
>  	at org.apache.commons.compress.archivers.zip.ZipArchiveInputStream.getNextZipEntry(ZipArchiveInputStream.java:193)
>  	at com.mathworks.install_impl.archive.zip.commonscompress.ZipArchiveInputStreamExtractor.extract(Unknown Source)
>  	at com.mathworks.install_impl.archive.DecodeArchiveInputStreamExtractor.extract(Unknown Source)
>  	at com.mathworks.install_impl.input.ArchiveComponentSource.extract(Unknown Source)
>  	at com.mathworks.install_impl.InstallableComponentImpl.install(Unknown Source)
>  	at com.mathworks.install_impl.ComponentInstallerImpl.installComponent(Unknown Source)
>  	at com.mathworks.install_impl.ComponentInstallerImpl.extractComponents(Unknown Source)
>  	at com.mathworks.install_impl.ComponentInstallerImpl.installComponents(Unknown Source)
>  	at com.mathworks.install_impl.ComponentInstallerImpl.detectLockedFilesAndInstallComponent(Unknown Source)
>  	at com.mathworks.install_impl.ComponentInstallerImpl.updateComponents(Unknown Source)
>  	at com.mathworks.install_impl.ProductInstallerImpl.updateProducts(Unknown Source)
>  	at com.mathworks.install_impl.InstallerImpl.update(Unknown Source)
>  	at com.mathworks.install_task.UpdateTask.execute(UpdateTask.java:46)
>  	at com.mathworks.install_task.AbstractDefaultInstallTask.call(AbstractDefaultInstallTask.java:24)
>  	... 35 more

这其中有一句`Caused by: java.io.EOFException: Truncated ZIP entry `我们大致可以猜出是下载的升级文件损坏导致升级失败。

而我比较幸运，至少`matlab`主程序还可以打开。不过`SimScape`好像损坏的比较彻底，连卸载也会报错。

所以死马当活马医，打开`matlab`主程序，**科学上网**后重新安装更新，最后解决了问题。（~~省得我删目录重装~~）

**UPDATE 2020/08/10**

 最近尝试更新到`Update 6`，于是~~喜闻乐见的~~又出现了**“不常见”**的异常现象。这次直接无法启动`Matlab`主程序。

不过在安装目录下找到了更新工具，直接运行更新程序成功修复了问题。

更新工具路径应该为`C:\Program Files\MATLAB\R2019b\bin\win64\update_installer.exe`

