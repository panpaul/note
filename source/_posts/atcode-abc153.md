---
title: AtCoder abc153 解题报告
date: 2020-01-27 15:41:21
tags:
- algorithm
- atcoder
mathjax: true
---

在ICPC/CCPC群里面看见有大佬说要打*AtCoder Contest*，于是我这个萌新去凑了一下热闹。

总体来说比赛不算太难，但最后的F题对我很不友好。

比赛地址: [AtCoder Beginner Contest 153](https://atcoder.jp/contests/abc153)

<!--more-->

- **A - Serval vs Monster**

  题意：有一个怪物血量为 $H$ ，每攻击一次血量减少 $A$ ，问最少需要几次攻击？
  
  这题属于送分题，直接按题意码代码。
  
  ```c++
  nclude <cstdio>
  using namespace std;
  int main()
  {
      int h, a, ans;
      scanf("%d%d", &h, &a);
      ans = h / a;
      if (ans * a < h)
          ans++;
      printf("%d", ans);
      return 0;
  }
  ```

- **B - Common Raccoon vs Monster**

  题意：有一个怪物血量为 $H$ ；你有 $N$ 种攻击方式，第 $i$ 种攻击方式使怪物血量减少 $ A_i $ ，且每种攻击方式只能使用一次。现让你判断能否杀死怪物。

  对于本题而言，只用对所有攻击方式的伤害求和，若低于怪物血量则无法杀死怪物、反之可以。

  ```c++
  #include <cstdio>
  using namespace std;
  int main()
  {
      int h, n, a, sum = 0;
      scanf("%d%d", &h, &n);
      for (int i = 0; i < n; i++)
      {
          scanf("%d", &a);
          sum += a;
      }
      if (sum < h)
      {
          printf("No");
      }
      else
      {
          printf("Yes");
      }
      return 0;
  }
  ```

- **C - Fennec vs Monster**

  题意：有 $N$ 只怪物，第 $i$ 只怪物的血量为 $H_i$。现在你有两种攻击方式：第一种方式使你选定的一只怪物血量减少1；第二种攻击方式直接杀死你选定的那一只怪物，但最多只能使用 $K$ 次。问第一种方式最少用多少次？

  对于这道题，可以用贪心。将血量多的用第二种方式杀死，血量少的用第一种方式。

  ```c++
  #include <cstdio>
  #include <algorithm>
  using namespace std;
  int main()
  {
      int n, k, h[200001];
      long long count = 0;
      scanf("%d%d", &n, &k);
      for (int i = 0; i < n; i++)
          scanf("%d", &h[i]);
      sort(h, h + n);
      for (int i = n - 1 - k; i >= 0; i--)
      {
          count += h[i];
      }
      printf("%lld", count);
      return 0;
  }
  ```

- **D - Caracal vs Monster**

  题意：有一个怪物，血量为 $H$ 。每当你攻击怪物时有两种可能：若怪物血量等于1，那么就杀死怪物；若怪物血量大于1，不妨设为 $x$ ，那么原来的怪物会消失并产生两个新的怪物，血量为 $\lfloor\frac{x}{2}\rfloor$ 。问最少要几次攻击？

  我们可以列出递推公式：
  $$
  f(H)=
  \begin{cases}
  2f(\lfloor\frac{H}{2}\rfloor)+1& H>1\\
  1& H=1
  \end{cases}
  $$

  ```c++
  #include <cstdio>
  #include <algorithm>
  using namespace std;
  int main()
  {
      long long h, count = 0, inc = 1;
      scanf("%lld", &h);
      while (true)
      {
          if (h <= 1)
          {
              count += inc;
              break;
          }
          count += inc;
          h /= 2;
          inc *= 2;
      }
      printf("%lld", count);
  
      return 0;
  }
  ```

- **E - Crested Ibis vs Monster**

  题意：怪物血量为 $H$ 。你有 $N$ 条咒语，对于第 $i$ 条咒语，它可以对怪物产生 $A_i$ 点伤害，同时消耗 $B_i$ 点魔力值。问最少消耗多少模拟值？

  本题类似于背包问题。

  我们采用动态规划的思想，不妨设 $f[i]$ 表示咒语产生 $i$ 点伤害时消耗的最少模拟值，动态转移方程如下：
  $$
  f[j] = min(f[j], f[max(0, j - a[i])] + b[i])
  $$
  $a[i]$、$b[i]$分别表示第 $i$ 条咒语所能产生的伤害和魔力值消耗量。

  该方程的初始条件是：
  $$
  f(i)=
  \begin{cases}
  0& i=0\\
  \infty& i>0
  \end{cases}
  $$
  

  ```c++
  #include <cstdio>
  #include <cstring>
  using namespace std;
  #define max(x, y) (((x) > (y)) ? (x) : (y))
  #define min(x, y) (((x) < (y)) ? (x) : (y))
  int main()
  {
      long long h, n, a[1001], b[1001], f[10001];
      memset(f, 127, sizeof(f));
      f[0] = 0;
      scanf("%lld%lld", &h, &n);
      for (int i = 0; i < n; i++)
      {
          scanf("%lld%lld", &a[i], &b[i]);
      }
      for (int i = 0; i < n; i++)
      {
          for (int j = 0; j <= h; j++)
          {
              f[j] = min(f[j], f[max(0, j - a[i])] + b[i]);
          }
      }
      printf("%lld", f[h]);
      return 0;
  }
  ```

- **F - Silver Fox vs Monster**

  题意：有 $N$ 只怪物站在一条线上，对于第 $i$ 只怪物，给定两个参数 $X_i$ 和 $H_i$ 分别表示怪物的坐标和血量。在每次攻击时你可以选定一个坐标 $X$ 对坐标区间在 $[X-D,X+D]$ 的怪物产生 $A$ 点伤害。问最少需要攻击几次？

  ~~对于这题，我没有想到解决方法，故看了一下题解。~~

  按照题解的意思，我们先对坐标排序，然后选定攻击坐标，使攻击左区间恰好为最边上的怪物所在位置。然后逐步向右移动区间直至达到最右边。

  详细过程见注释：

  ```c++
  #include <cstdio>
  #include <algorithm>
  using namespace std;
  struct point
  {
      long long x, h;
  } p[200001];
  bool cmp(point const &p1, point const &p2)
  {
      return p1.x < p2.x;
  }
  int main()
  {
      // 读入数据
      long long N, D, A;
      scanf("%lld%lld%lld", &N, &D, &A);
      D <<= 1; // 先将半个宽度乘2使之成为左右区间宽度
      for (int i = 1; i <= N; i++)
      {
          scanf("%lld%lld", &p[i].x, &p[i].h);
      }
  
      sort(p + 1, p + N + 1, cmp); // 按坐标升序
  
      long long tmp = 0;            // 炸弹伤害
      long long hurt[200001] = {0}; // 记录每个点的伤害
      long long ans = 0;            // 记录答案
      for (int i = 1; i <= N; i++)  // 循环处理每个Monster
      {
          p[i].h -= tmp;  // 先减去上几次投弹的伤害
          if (p[i].h > 0) // 第i个还没死，考虑继续炸
          {
              long long n = (p[i].h + A - 1) / A; // 至少还需要炸的次数
              long long h = n * A;                // 本次投弹伤害
              tmp += h;                           // 更新伤害
              ans += n;                           // 更新答案
  
              long long l = i, r = N + 1; // 二分查找，寻找轰炸点使得i恰好在爆炸范围的左端
              while (l < r - 1)
              {
                  long long mid = (l + r) >> 1;
                  if (p[mid].x - D <= p[i].x) // 更新后能否炸到i
                      l = mid;
                  else
                      r = mid;
              }
              hurt[l] += h; // 最终在l处投弹，记录该处伤害
          }
          tmp -= hurt[i]; // 处理完第i个，轰炸区间向右移动，不再计算i点投弹所产生的伤害
      }
  
      printf("%lld", ans); // 输出答案
      return 0;
  }
  ```

  

