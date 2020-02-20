---
title: AtCoder abc155 解题报告
date: 2020-02-17 16:44:40
tags:
- algorithm
- atcoder
mathjax: true
---

总体而言，这次比赛题目难度梯度不合理，ABC过于简单，DEF难度提升幅度大。

比赛地址: [AtCoder Beginner Contest 155](https://atcoder.jp/contests/abc155)

<!--more-->

- **A - Poor**

  题意：给定三个数$A$、$B$、$C$，如果其中有两个数相等且不等于剩下一个数，则输出"Yes"，反之输出"No"。

  ```c++
  #include <cstdio>
  #include <iostream>
  
  bool jdg(int a, int b, int c)
  {
      if (a == b && a != c)
          return true;
      else
          return false;
  }
  
  int main()
  {
      std::ios::sync_with_stdio(false);
      std::cin.tie(0);
      std::cout.tie(0);
      int a, b, c;
      std::cin >> a >> b >> c;
      if (jdg(a, b, c))
      {
          std::cout << "Yes";
          return 0;
      }
      if (jdg(b, c, a))
      {
          std::cout << "Yes";
          return 0;
      }
      if (jdg(c, a, b))
      {
          std::cout << "Yes";
          return 0;
      }
      std::cout << "No";
      return 0;
  }
  ```

- **B - Papers, Please**

  题意：给定$N$个数字$A_1$至$A_n$，如果其中所有的偶数都可以被3或5整除，则输出"APPROVED"，反之输出"DENIED"。

  ```c++
  #include <cstdio>
  #include <iostream>
  
  int main()
  {
      std::ios::sync_with_stdio(false);
      std::cin.tie(0);
      std::cout.tie(0);
      int n, a;
      std::cin >> n;
      while (n--)
      {
          std::cin >> a;
          if (a % 2 == 0 && a % 3 != 0 && a % 5 != 0)
          {
  
              std::cout << "DENIED";
              return 0;
          }
      }
      std::cout << "APPROVED";
      return 0;
  }
  ```

- **C - Poll**

  题意：给定$N$个字符串：$S_1$至$S_n$，现在要统计出每个字符串的出现次数，并输出出现次数最多的字符串，如果有多个则按字典序排列。

  思路：我这里偷懒直接用STL的功能，先将数据记录入map而后转化为vector并排序。实际上题目只要求找最大值，可以省去排序的步骤，直接扫一遍map即可（map维护了string的字典序）。

  ```c++
  #include <cstdio>
  #include <iostream>
  #include <map>
  #include <vector>
  #include <cstring>
  #include <algorithm>
  
  typedef std::pair<std::string, int> PAIR;
  bool cmp(const PAIR &a, const PAIR &b)
  {
      if (a.second > b.second)
      {
          return true;
      }
      if (a.second < b.second)
      {
          return false;
      }
      return a.first < b.first; // 注意相同时要考虑字典序
  }
  int main()
  {
      std::ios::sync_with_stdio(false);
      std::cin.tie(0);
      std::cout.tie(0);
  
      std::map<std::string, int> m;
      std::string s;
      int n;
  
      std::cin >> n;
      while (n--)
      {
          std::cin >> s;
          m[s]++;
      }
  
      std::vector<PAIR> vec(m.begin(), m.end());
      std::sort(vec.begin(), vec.end(), cmp);
      n = vec[0].second;
      std::cout << vec[0].first << "\n";
      for (int i = 1; i < vec.size(); i++)
      {
          if (vec[i].second < n)
              break;
          std::cout << vec[i].first << "\n";
      }
  
      return 0;
  }
  ```

- **D - Pairs**

  题意：给定$N$个数$A_1$至$A_N$。从中任取两个数相乘，并把结果放入新的数列中。按从小到大的顺序排列新的数列，问第$K$个数是什么?

  思路：

  ​	首先，显然我们不可能把所有的结果都算出来，这样会超时。

  ​	所以有几个优化的操作：

  > 1. 统计正负零的数目，可以确定出答案的区间范围。
  > 2. 采用二分查找的思路找答案。

  ​	而关于第二点，以负数区间查找为例，可以先将正数与负数分别排序。然后设定两个指针，一个指向正数的最大值，另一个从负数的最大开始查找，直到乘积大小大于二分中值区间。再者第一个指针指向下一个值，第二个指针继续前移寻找。如此找出所有在中值之前的个数。然后与要求的$k$进行比较，改变二分区间。

  ```c++
  #include <iostream>
  #include <vector>
  #include <algorithm>
  typedef long long LL;
  bool cmp(LL a, LL b) { return a > b; }
  int main()
  {
      std::ios::sync_with_stdio(false);
      std::cin.tie(0);
      std::cout.tie(0);
  
      std::vector<LL> positive, negative;       // 记录正数和负数
      LL n, k, cnt_p = 0, cnt_n = 0, cnt_z = 0; // 记录个数
  
      std::cin >> n >> k;
      int tmp;
  
      while (n--)
      {
          std::cin >> tmp;
          if (tmp > 0) // 统计正数
          {
              cnt_p++;
              positive.push_back(tmp);
          }
          else if (tmp < 0) // 统计负数
          {
              cnt_n++;
              negative.push_back(tmp);
          }
          else // 统计0
          {
              cnt_z++;
          }
      }
  
      // 预先排序
      std::sort(positive.begin(), positive.end(), cmp);
      std::sort(negative.begin(), negative.end(), cmp);
  
      LL n_n = cnt_p * cnt_n;                                     // 负数的组合个数
      LL n_0 = cnt_z * (cnt_n + cnt_p) + cnt_z * (cnt_z - 1) / 2; // 0的组合个数
      //LL n_p = cnt_n * (cnt_n - 1) / 2 + cnt_p * (cnt_p - 1) / 2; // 正数的组合个数
  
      if (k <= n_n) //负数
      {
          LL l = positive[0] * negative.back(), r = positive.back() * negative[0]; // 确定二分区间
  
          while (l <= r)
          {
              LL mid = (l + r) >> 1;
              LL cnt = 0, idx = 0;           // cnt记录mid前面的个数
              for (LL i = 0; i < cnt_n; i++) // 第一个指针遍历所有的负数，从大到小
              {
                  while (true)
                  {
                      if (idx < cnt_p && positive[idx] * negative[i] <= mid) // 找出mid前的数组合
                      {
                          idx++;
                          continue;
                      }
                      break;
                  } // 保存idx的位置，减少之后循环的次数
                  cnt += idx;
              }
              if (cnt < k)
                  l = mid + 1;
              else
                  r = mid - 1;
          }
          std::cout << l;
      }
      else if (k <= n_n + n_0) // 零
      {
          std::cout << 0;
      }
      else // 正数
      {
          // 颠倒顺序，方便下标处理,从小到大
          std::reverse(positive.begin(), positive.end());
  
          // 确定取值范围
          LL l = 1e18, r = 0;
          // 防止数据太小
          if (cnt_p >= 2)
          {
              r = std::max(positive.back() * positive[cnt_p - 2], r);
              l = std::min(positive[0] * positive[1], l);
          }
          if (cnt_n >= 2)
          {
              r = std::max(negative.back() * negative[cnt_n - 2], r);
              l = std::min(negative[0] * negative[1], l);
          }
  
          while (l <= r)
          {
              LL mid = (l + r) >> 1;
  
              LL cnt = 0;
  
              bool calc = true;
              LL idx = 0;
              for (LL i = cnt_p - 1; i >= 0; i--) // 第一个指针遍历所有正数，从大到小
              {
                  while (calc)
                  {
                      if (idx < i && positive[i] * positive[idx] <= mid)
                      {
                          idx++;
                          continue;
                      }
                      break;
                  }
  
                  if (i < idx) // 这里需要考虑重复问题
                  {
                      cnt += i;
                      calc = false; // 不用继续进行上面那个while了
                  }
                  else
                  {
                      cnt += idx;
                  }
              }
  
              calc = true; // 还原标记
              idx = 0;
              for (LL i = cnt_n - 1; i >= 0; i--) // 遍历所有负数 从小到大(乘积从大到小)
              {
                  while (calc)
                  {
                      if (idx < i && negative[i] * negative[idx] <= mid)
                      {
                          idx++;
                          continue;
                      }
                      break;
                  }
  
                  if (i > idx) // 这里需要考虑重复问题
                  {
                      cnt += idx;
                  }
                  else
                  {
                      cnt += i;
                      calc = false;
                  }
              }
  
              if (cnt < k - n_n - n_0)
                  l = mid + 1;
              else
                  r = mid - 1;
          }
          std::cout << l;
      }
  
      return 0;
  }
  ```

  

- **E - Payment**

  题意：在某个国家的货币体系中，只有现金，并且发行的现金面值为$10^n$其中$n \in (0,10^{100})$。现在你要购买一件价值为$N$的商品，假定你和售货员都有无数张所有面值的钞票，现在问你买这件商品与售货员交换的钞票张数最少是多少？

  示例：假定$N$为91。你付给售货员101（两张钞票100和1），售货员找零10（一张钞票），交换现金张数为3（1+2）。

  思路：贪心。这题$N$的数据范围极大，故~~易知~~我们没有必要对整体进行考虑，只用关心每一位即可。这里，对于每一位数，如果大于5的话，凑整进位然后让售货员找零，这样代价小。如果小于5的话就自己把零头付了。这里需要注意的是等于5的情况（在这被卡了……），需要考虑前一位数和5的大小关系，比如说65（或55），这里连进两位凑成100结果最优，而如果是45，则自己把零头付了最优。

  ```c++
  #include <cstdio>
  int s[10000001];
  
  int main()
  {
      // 预留开头，以防进位
      s[0] = 0;
      int cnt = 1;
  
      long long ans = 0;
      while (true) // 从1开始记录
      {
          s[cnt] = getchar();
          if (s[cnt] == EOF || s[cnt] == '\n')
              break;
          s[cnt] -= '0';
          cnt++;
      }
  
      while (s[cnt - 1] == 0)
      {
          cnt--;
      } // 处理完数字最后的0
  
      for (int i = cnt - 1; i > 0; i--) // 从最低首个非零处开始遍历
      {
          if (s[i] == 5) // 特殊情况
          {
              if (s[i - 1] >= 5) // 考虑前一位
              {
                  ans += 10 - s[i]; // 找零
                  s[i - 1]++;       // 进位
              }
              else
              {
                  ans += s[i]; // 把零头付了
              }
          }
          else if (s[i] > 5) // 大于5，凑整
          {
              ans += 10 - s[i]; // 找零
              s[i - 1]++;       // 进位
          }
          else // 小于5，自己付了
          {
              ans += s[i]; // 把零头付了
          }
      }
  
      ans += s[0]; // 加上进位
  
      printf("%lld", ans);
      return 0;
  }
  ```

  

- **F - Perils in Parallel**

  题意：有$N$个炸弹，编号从$1$至$N$。第$i$号炸弹安放在位置$A_i$，并且它具有一个属性$B_i$，当$B_i$为$1$时表示这个炸弹已经被激活，如果为$0$则表示炸弹被关闭。这$N$个炸弹由一个控制系统控制。该系统有$M$条绳子，编号从$1$至$M$。如果你切断了第$j$条绳子，那么放置在位置$L_j$到$R_j$之间所有炸弹的属性$B$会进行切换，即$1$会变为$0$，$0$会变为$1$。现在问你能否关闭所有的炸弹，如果能则输出需要切断的绳子编号。
  
  思路：~~留坑待补~~