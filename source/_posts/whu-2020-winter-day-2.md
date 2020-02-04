---
title: 武汉大学新生寒假集训测试-Day2
date: 2020-02-04 11:09:28
tags:
- algorithm
- codeforces
mathjax: true
---

总体来说，这次测试感觉不太好，有两道题没有什么思路。

比赛地址：[vjudge](https://vjudge.net/contest/355097)

<!--more-->

- **A - Cutting Out**  [CodeForces 1077D](https://codeforces.com/problemset/problem/1077/D)

  题意：给定一个长度为$n$的数组$s$，从中取出$k$个数字（允许重复）组成一个数组$t$，现构造一个$t$使得从$s$中可以取出$t$中元素的次数最多。
  
  ~~不会做，先留一个坑~~
  
  思路：先想办法求出最多的取出次数，然后遍历输出结果。具体看注释吧！
  
  ```c++
  #include <cstdio>
  #include <algorithm>
  using namespace std;
  struct A
  {
      int i, v = 0; // i记录数字，v记录出现的次数
  } bucket[200005];
  bool cmp(A t1, A t2) // 按出现次数从大到小排序
  {
      return t1.v > t2.v;
  }
  int main()
  {
      int n, k, a;
      scanf("%d%d", &n, &k);
      for (int i = 0; i < n; i++)
      {
          scanf("%d", &a);
          bucket[a].v++;   // 次数累加
          bucket[a].i = a; // 记录数字
      }
  
      sort(bucket, bucket + 200005, cmp); // 从大到小排序
  
      // 二分查找最大的取出次数，最小的情况刚好是排好的第k个的重复次数，最大的是第一个的重复次数
      // an 记录最后的最大结果
      int l = bucket[k - 1].v, r = bucket[0].v, mid, cnt = 0, an;
      while (l <= r)
      {
          cnt = 0;
          mid = (l + r) >> 1;
          for (int i = 0; i < k; i++) // 遍历前k个数
          {
              cnt += bucket[i].v / mid; // 该数字可以取得的次数
          }
          if (cnt >= k) // 有解
          {
              // 使次数尽可能多
              l = mid + 1;
              an = mid;
          }
          else
          {
              // 减小次数
              r = mid - 1;
          }
      }
  
      int tot = 0, ans[(int)2e5 + 5]; // 开一个数组记录答案
      for (int i = 0; i < k; i++)     // 最坏的情况是前k个各取一个
      {
          for (int j = 0; j < bucket[i].v / an; j++) // 考虑一个数可以取多次的情况
          {
              ans[tot++] = bucket[i].i; // 记录答案
              if (tot == k)             // 到达k次后结束
              {
                  goto print; // 其实可以直接在这里输出并结束程序
              }
          }
      }
  
  print:
      while (k--)
      {
          printf("%d ", ans[k]);
      }
  
      return 0;
  }
  ```
  
  
  
- **B - Vasya and Books** [CodeForces 1073B](https://codeforces.com/problemset/problem/1073/B)

  题意：Vasya有$n$本书，每本书给定一个唯一的编号（从$1$到$n$）。这些书按顺序放成一堆，最上面的书编号为$a_1$，最下面的编号为$a_i$。现在Vasya要把书拿走，每次选定一个编号$b_i$，当他要取走这本书时，要将叠放在这本书上的所有书一起取到背包中，若那本书已经在背包中则不用再取。现问他每次拿走书的数量。

  思路：模拟。维护一个栈，即叠放的书，还有一个数组记录书是否在背包中。我们先把输入的$a_i$入栈，然后对于给定的每一个$b_i$，先判断书是否在背包中；若不在，则依次出栈，记录取出的书，直到找到目标的书籍。

  ```c++
  #include <cstdio>
  #include <stack>
  using namespace std;
  int a[200001];
  bool back_pack[200001] = {0};
  int main()
  {
      stack<int> stk;
      int n, x;
      scanf("%d", &n);
      for (int i = 1; i <= n; i++)
          scanf("%d", &a[i]);
      for (int i = n; i >= 1; i--)
          stk.push(a[i]);
  
      while (n--)
      {
          int count = 0;
          scanf("%d", &x);
          if (back_pack[x])
          {
              printf("0 ");
              continue;
          }
  
          while (true)
          {
              int tmp = stk.top();
              stk.pop();
              back_pack[tmp] = true;
              count++;
              if (tmp == x)
              {
                  printf("%d ", count);
                  break;
              }
          }
      }
      return 0;
  }
  ```

- **C - Vasya and Robot** [CodeForces 1073C](https://codeforces.com/problemset/problem/1073/C)

  题意：Vasya有一个机器人，它可以接受四个指令：UDLR，分别控制机器人向上、下、左、右四个方向移动一个单位。机器人一开始在原点$(0,0)$，要到达目标$(x,y)$。现在给定了一个指令序列，我们可能要修改指令使得机器人到达目标点。我们定义在序列中修改的指令位置最大为$maxID$，最小位置为$minID$，规定修改序列的长度为$maxID-minID+1$，若不需修改则长度为$0$。现问最小修改的区间长度或者输出无解。

  ~~不会做，再留一个坑~~

- **D - Frog Jumping** [CodeForces 1077A](https://codeforces.com/problemset/problem/1077/A)

  题意：有一只青蛙位于数轴原点上，它会跳$k$次，一次向右一次向左。它会在奇数次时向右跳$a$个单位，在偶数次时向左跳$b$个单位。求它跳跃完后的位置。

  思路：数学题，找出青蛙跳跃的最终位置的函数式。
  $$
  f(k)=
  \begin{cases}
  \frac{(a-b)k}{2}& k是偶数\\
  \frac{(a-b)(k-1)}{2}+a& k是奇数
  \end{cases}
  $$

  ```c++
  #include <cstdio>
  using namespace std;
  int main()
  {
      int t;
      long long a, b, k, ans;
      scanf("%d", &t);
      while (t--)
      {
          scanf("%lld%lld%lld", &a, &b, &k);
          if (k % 2 == 0)
          {
              printf("%lld\n", (a - b) * k >> 1);
          }
          else
          {
              printf("%lld\n", (((a - b) * (k - 1)) >> 1) + a);
          }
      }
  
      return 0;
  }
  ```

- **E - Good Array** [CodeForces 1077C](https://codeforces.com/problemset/problem/1077/C)

  题意：我们给出如下定义：从一个数组中取出一个元素后，将剩下的元素求和，若取出的元素等于求和的结果，则这个数组被称为“好的数组”。现在给定一个数组$a$，问去掉那些数字后可以使得剩下的数字组成的数组被称为“好的数组”。

  思路：我的思路比较暴力，在输入时先统计数组的和。然后将数组排序，依次去掉一个元素，判断最大的数是否等于剩下的和，也即判断$sum-a_i(去掉的元素)-a_{max}$是否等于$a_{max}$。

  ```c++
  #include <cstdio>
  #include <algorithm>
  using namespace std;
  int n;
  long long sum = 0;
  struct E
  {
      int index, val;
  } a[200005];
  int ans[200005], cnt = 0;
  bool cmp(E const &t1, E const &t2)
  {
      return t1.val < t2.val;
  }
  int main()
  {
      scanf("%d", &n);
      for (int i = 0; i < n; i++)
      {
          scanf("%d", &a[i].val);
          sum += a[i].val;
          a[i].index = i;
      }
      sort(a, a + n, cmp);
      for (int i = 0; i < n - 1; i++)
      {
          if (sum - a[i].val - (a[n - 1].val << 1) == 0)
          {
              ans[cnt] = a[i].index;
              cnt++;
          }
      }
      if (sum - a[n - 1].val - (a[n - 2].val << 1) == 0)
      {
          ans[cnt] = a[n - 1].index;
          cnt++;
      }
      printf("%d\n", cnt);
      for (int i = 0; i < cnt; i++)
          printf("%d ", ans[i] + 1);
      return 0;
  }
  ```

- **F - Disturbed People** [CodeForces 1077B](https://codeforces.com/problemset/problem/1077/B) 

  题意：有一栋$n$层的楼，每户人家是否开灯的属性由$a$表示，其中$a$为$0$时表示灯关了，$a$为$1$时表示灯是开着的。如果一户人家灯是开着的，而他相邻的两户灯是开着的，则表示他受到了打扰。现问至少关掉多少灯可以使得所有的人不受打扰。

  思路：从一头开始判断给定的条件，如果受到了干扰则标记加1，然后跳过接下来的两户继续进行判断。

  ```c++
  #include <cstdio>
  using namespace std;
  bool a[101] = {0};
  int main()
  {
      int n, count = 0;
      scanf("%d", &n);
      for (int i = 0; i < n; i++)
          scanf("%d", &a[i]);
      for (int i = 1; i < n - 1; i++)
      {
          if (a[i - 1] && a[i + 1] && !a[i])
          {
              count++;
              i += 2; // ignore
          }
      }
      printf("%d", count);
      return 0;
  }
  ```

- **G - Diverse Substring** [CodeForces 1073A](https://codeforces.com/problemset/problem/1073/A)

  题意：我们先下两个定义：一个字符串的“子串”指的是从原字符串中取出连续的一段字符形成的新字符串；“多样化”的字符串指的是当一个字符串长度为$n$时，其中任何字符的重复次数不能多于$\frac{n}{2}$。现在给定一个字符串$s$，让你找出一个“多样化”的“子串”，或者输出无解。

  思路：由于题目没有限制“子串”的长度，故我们只需关注长度最短的子串就行了，也即只需要找出一个长度为2且由不同字符组成的“子串”即可。

  ```c++
  #include <iostream>
  #include <cstring>
  using namespace std;
  int main()
  {
      int n;
      string str;
      cin >> n >> str;
      for (int i = 0; i < n - 1; i++)
      {
          if (str[i] != str[i + 1])
          {
              cout << "YES\n"
                   << str[i] << str[i + 1];
              return 0;
          }
      }
      cout << "NO";
      return 0;
  }
  ```

- **H - Berland Fair** [CodeForces 1073D](https://codeforces.com/problemset/problem/1073/D) 

  题意：有$n$个商户围了一圈，每个商户只卖一种东西且库存无限。题目告知我们第$i$个商户商品的价格为$a_i$，你手里的钱为$T$。你在这个商圈中遵循以下的购物策略：从1号商户开始按次序购买商品，买得起就买一件商品，然后前往下一家（第$n$家的下一家是1），如果你手中的钱不足以购买任何一件商品时就结束购买。

  思路：如果暴力模拟会TLE，所以我们可以一买一圈（$1-n$）为一个单位考虑。每次记录买一圈的消费，然后重复多次这一圈的消费直至不够，也即通过整除和求余来加速相同的购买操作，然后重新判断下一圈。

  ```c++
  #include <cstdio>
  using namespace std;
  #define LL long long
  #define MIN(a, b) ((a > b) ? (b) : (a))
  LL m[200005];
  int main()
  {
      LL n, T, min_num = 1e9 + 5;
      scanf("%lld%lld", &n, &T);
      for (int i = 1; i <= n; i++)
      {
          scanf("%lld", &m[i]);
          min_num = MIN(min_num, m[i]);
      }
  
      LL ans = 0;
      while (T >= min_num)
      {
          LL t = 0, pay = 0;
          for (int i = 1; i <= n; i++)
          {
              if (T >= m[i])
              {
                  t++;
                  T -= m[i];
                  pay += m[i];
              }
          }
          ans += t;
          // 加速相同的购买操作
          ans = ans + (T / pay) * t;
          T %= pay;
      }
      printf("%lld\n", ans);
      return 0;
  }
  ```

  

