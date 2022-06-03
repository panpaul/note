---
title: 模拟退火算法
date: 2020-01-04 20:58:11
updated: 2020-03-31 20:12:15
tags: algorithm
mathjax: true
---

在认知计算导引~~水课~~课程中介绍了启发式搜索，其中模拟退火算法就是一种启发式搜索算法。

<!--more-->

- 模拟退火算法最早由N. Metropolis 等人提出, 后来S. Kirkpatrick 等成功地将退火思想引入到组合优化领域。这种算法模拟了物理中固体退火的原理（加温时固体内部粒子随温升变为无序状，内能增大；冷却时粒子渐趋有序，粒子达到平衡态，内能减为最小。）

- 其中模拟退火和物理退火的比较如下表：


| 模拟退火           | 物理退火   |
| ------------------ | ---------- |
| 解                 | 粒子状态   |
| 最优解             | 能量最低态 |
| 设定初温           | 溶解过程   |
| Metropolis采样过程 | 等温过程   |
| 控制参数T下降      | 冷却       |
| 目标函数           | 能量       |

- 在某一特定温度下经过充分转换之后，固体达到热平衡。此时固体处于状态i的概率满足玻尔兹曼分布：

  $$P_T(x=i)=\frac{e^{-\frac{E(i)}{KT}}}{\sum_{j\in S}e^{-\frac{E(j)}{KT}}}$$

  其中x表示固体当前状态的随机变量，S表示状态空间集合。

  在高温下，对上式求极限得：

  $$\lim\limits_{x \to \infty} \frac{e^{-\frac{E(i)}{KT}}}{\sum_{j\in S}e^{-\frac{E(j)}{KT}}}=\frac{1}{\left|S\right|}$$

  即在高温下所有状态具有相同得概率。

- 当温度降至很低时，固体会以很大概率进入最小能量状态：

$$
\begin{equation}

\lim\limits_{x\to0}\frac{e^{-\frac{E(i)}{KT}}}{\sum_{j\in S}e^{-\frac{E(j)}{KT}}} \\

=\lim\limits_{x\to0}\frac{e^{-\frac{E(i)-E_{min}}{KT}}}{\sum_{j\in S}e^{-\frac{E(j)-E_{min}}{KT}}} \\

=\lim\limits_{x\to0}\frac{e^{-\frac{E(i)-E_{min}}{KT}}}{\sum_{j\in S_{min}}e^{-\frac{E(j)-E_{min}}{KT}}+\sum_{j\not\in S_{min}}e^{-\frac{E(j)-E_{min}}{KT}}} \\

=\lim\limits_{x\to0}\frac{e^{-\frac{E(i)-E_{min}}{KT}}}{\sum_{j\in S_{min}}e^{-\frac{E(j)-E_{min}}{KT}}} \\

=\begin{cases}
\dfrac{1}{\left|S_{min}\right|},& i\in S_{min} \\
0,& \text{otherwise}
\end{cases}

\end{equation} 
$$

  其中， $E_{min}=\min\limits_{j\in S}E(j)$ 且 $S_{min}=\{i|E(i)=E_{min}\}$

- Metropolis准则：以概率接受新状态

  假设固体在状态$i$时的能量为$E(i)$, 那么固体在温度$T$时, 从状态$i$进入状态$j$遵循如下规律：
  
  - 如果$E(j)\le E(i)$，接受该状态转换；
  
  - 如果$E(j)\ge E(i)$，则状态转换以如下概率被接受：
  
    $$ P=e^{\dfrac{E(i)-E(j)}{KT}} $$
  
    其中$K$是物理学中得玻尔兹曼常数，$T$是固体温度。

- 综上，模拟退火算法的算法图解如下：

  <img src="/images/sa.png" width="50%" alt="sa_algo">
