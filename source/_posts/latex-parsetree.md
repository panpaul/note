---
title: 使用latex写证明树
date: 2020-03-18 19:27:42
tags:
- latex
- parsetree
mathjax: true
---

离散数学课的作业要求升级了！要求用$\LaTeX$写分析树。

<!--more-->

1. 什么是分析树？

   来自维基百科的解释是：

   > A **parse tree** or **parsing tree**[[1\]](https://en.wikipedia.org/wiki/Parse_tree#cite_note-1) or **derivation tree** or **concrete syntax tree** is an ordered, rooted [tree](https://en.wikipedia.org/wiki/Tree_(data_structure)) that represents the [syntactic](https://en.wikipedia.org/wiki/Syntax) structure of a [string](https://en.wikipedia.org/wiki/String_(computer_science)) according to some [context-free grammar](https://en.wikipedia.org/wiki/Context-free_grammar). The term *parse tree* itself is used primarily in [computational linguistics](https://en.wikipedia.org/wiki/Computational_linguistics); in theoretical syntax, the term *syntax tree* is more common.

2. 怎么写这玩意？

   这里使用了包`forest`（~~虽然我们老师推荐的是`tikz-qtree`~~）

   ```latex
   \usepackage{forest}
   --snip--
   \begin{forest}
   	[a
   		[b]
   		[c
   			[d 
   				[f]
   				[g]
   			]
   			[e]
   		]
   	]
   \end{forest}
   ```

   最终的效果是：<img src="/images/latex-parse-1.png" alt="latex-parse-tree-1">

   这个包使用起来很简单，所有的子元素都放置入`[]`中，无需关心排版的问题。

   同时这个包还支持使用`tikz`进行修饰，参考代码：

   ```latex
   \usepackage{forest}
   \usepackage{tikz}
   --snip--
   \begin{forest}
   		[$\exists$
   			[$x$,circle,draw,color=blue]
   			[$\wedge$,name=wedge
   				[$P$[$y$,circle,draw,color=green,name=leftmost][$z$,circle,draw,color=green]]
   				[$\forall$
   					[$y$,circle,draw,color=red]
   					[$\vee$,name=vee
   						[$\neg$
   							[$Q$
   								[$y$,circle,draw,fill=red!50,name=bottomleftmost]
   								[$x$,circle,draw,fill=blue!50]
   							]
   						]
   						[$P$
   							[$y$,circle,draw,fill=red!50]
   							[$z$,circle,draw,color=green,name=rightmost]
   						]
   					]
   				]
   			]
   		]
   		\node[draw=red,thick,fit=(vee)(bottomleftmost)(rightmost)] {};
   		\node[draw=blue,thick,fit=(wedge)(leftmost)(rightmost)(bottomleftmost)] {};
   	\end{forest}
   ```

   最终的效果是：<img src="/images/latex-parse-2.png" alt="latex-parse-tree-2">

   对于需要使用`tikz`修饰的节点，可以在其后用`,`添加相关的参数。但需要注意的是：在`[]`中`forest`会严格的匹配`[]`如果直接使用`\draw [...]`之类的命令会产生错误。

