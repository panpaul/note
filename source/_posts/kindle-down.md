---
title: 快速下载Kindle已购资源
date: 2022-06-04 10:36:04
tags:
- kindle
- js
---

最近`Amazon`宣布了`Kindle`即将推出中国市场，所以想着把`Kindle`商店里面买的/嫖的书下载回来

<!--more-->

我选择使用`下载到电脑`的模式，因为目前这种方式可以获取`azw3`文件（至少可以阅读），而推送到`Kindle`上的书是`KFX`格式，受`DRM`加密

而`Amazon`不提供批量下载的功能，于是考虑使用`js`辅助下载：

首先登录自己的资源页面：[管理我的内容和设备](https://www.amazon.cn/hz/mycd/myx#/home/content/booksAll/dateDsc/)，并且下滑页面，加载出所有的信息

然后设置浏览器自动下载文件

接着打开控制台，输入以下程序，就可以等待浏览器下载

```javascript
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function down_all() {
	for (let i = 0; i < 你的书籍总数; i++) {
		document.querySelector(`#contentTabList_${i}_myx > div > div > div > div > div.myx-fixed-left-grid-col.myx-col-left > div > div.myx-column.myx-span7.myx-span-last > div > a > span > button`).click();
		await sleep(500); // 可以根据情况自行调整延时
		document.querySelector("#contentAction_download_myx > div > div > div > div > div > div > span").click();
		await sleep(500); // 可以根据情况自行调整延时
		document.querySelector("#dialogButton_ok_myx\\  > span > button").click();
		await sleep(8000); // 可以根据情况自行调整延时
	}
}

down_all()
```



