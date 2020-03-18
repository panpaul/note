---
title: 使用latex写证明树
date: 2020-03-15 19:50:53
updated: 2020-03-17 19:45:00
tags:
- latex
- prooftree
mathjax: true
---

最近离散数学课的作业要求用$\LaTeX$写证明树和推导序列，故研究了相关内容，以此记录。

<!--more-->

1. 首先是最基本的证明树

   这里引用了包`bussproofs`

   ```latex
   \usepackage{bussproofs}
   --snip--
   A simple proof tree.
   \begin{prooftree}
   	\AxiomC{$p$}
   	\AxiomC{$p \to q$}
   	\RightLabel{$\to e$}
   	\BinaryInfC{$q$}
   \end{prooftree}
   ```

   最终的效果是：<img src="/images/latex-proof-1.png" width="80%" alt="latex-proof-tree-1">

   从代码中看，构造的这个证明树有几个元素：

   - `\AxiomC{}` 如同其名字，这个元素用于放置假设、条件、公理等
   - `\RightLabel{}` 在横线右边添加注释，同样地还有`\LeftLabel`
   - `\BinaryInfC{}` 绘制横线以及得到的结论，其中`\BinaryInfC{}`对应两个条件元素，`\UnaryInfC{}`对应一个条件元素，`\TrinaryInfC{}`对应三个条件元素

2. 其次是一个较为复杂的证明树

   ```latex
   Yet another proof tree.
   \begin{prooftree}
   	\AxiomC{$p \vee q$} <-----------最外层的内容
   
   		\AxiomC{$p$}          |
   		\AxiomC{$p \to s$}    |
   		\RightLabel{$\to e$}  |<----一个块
   		\BinaryInfC{$s$}     _|
   
   		\AxiomC{$q$}          |
   		\AxiomC{$q \to s$}    |
   		\RightLabel{$\to e$}  |<----第二个块
   		\BinaryInfC{$s$}     _|
   
   	\RightLabel{$\vee e$} <---------最外层的内容
   	\TrinaryInfC{$s$}
   \end{prooftree}
   ```

   这里我们无需关心`bussproof`如何完成公式的渲染，对于复杂的证明树，我们只需要按照“堆栈”的思想去编写证明树代码即可。

   效果如图：<img src="/images/latex-proof-2.png" width="80%" alt="latex-proof-tree-2">

3. 绘制带框的证明树

   这里采用`\fbox`与`\parbox`的配合完成加框。总体效果如下：

   <img src="/images/latex-proof-3.png" width="80%" alt="latex-proof-tree-3">

   ```latex
   \usepackage{calc}
   --snip--
   Proof tree(s) with boxes.
   \newsavebox{\prooftreeOne}
   \sbox{\prooftreeOne}{
   	\AxiomC{$p$}
   	\AxiomC{$p \to s$}
   	\RightLabel{$\to e$}
   	\BinaryInfC{$s$}
   	\DisplayProof
   }
   \newsavebox{\prooftreeTwo}
   \sbox{\prooftreeTwo}{
   	\AxiomC{$q$}
   	\AxiomC{$q \to s$}
   	\RightLabel{$\to e$}
   	\BinaryInfC{$s$}
   	\DisplayProof
   }
   \begin{prooftree}
   	\AxiomC{$p \vee q$}
   	\AxiomC{\fbox{\parbox{\widthof{\usebox{\prooftreeOne}}}{\usebox{\prooftreeOne}}}}
   	\AxiomC{\fbox{\parbox{\widthof{\usebox{\prooftreeTwo}}}{\usebox{\prooftreeTwo}}}}
   	\RightLabel{$\vee e$}
   	\TrinaryInfC{$s$}
   \end{prooftree}
   ```

   需要注意的是当引用`box`时需测量子块的宽度，否则会出现框直接占满整页的情况

4. 单独一条横线的绘制

   其实只用放置一个空的`\AxiomC{}`元素就可以了

   ```latex
   LEM example.
   \begin{prooftree}
   	\AxiomC{}
   	\RightLabel{$LEM$}
   	\UnaryInfC{$p \vee \neg p$}
   \end{prooftree}
   ```

   <img src="/images/latex-proof-4.png" width="80%" alt="latex-proof-tree-4">

5. 证明序列的编写

   这里需要强调的是，我目前的方法十分局限并且复杂。它不适用于需要换页的情况，并且当框的数目多起来后要编写许多冗余的代码。

   效果如图：<img src="/images/latex-proof-5.png" width="80%" alt="latex-proof-tree-5">

   ```latex
   \usepackage{tikz}
   \usetikzlibrary{tikzmark,fit}
   --snip--
   A simple proof sequence.
   \begin{enumerate}
   	\item \qquad $p \vee q$ \hfill $Premise$
   
   	\item \qquad \qquad \tikzmarknode{block1}{$p$} \hfill $(1)$
   	\item \qquad \qquad $p \to s$ \hfill $Premise$
   	\item \qquad \qquad \tikzmarknode{end1}{$s$ \qquad\quad} \hfill $(2)+(3)+\to e$
   
   	\item \qquad \qquad \tikzmarknode{block2}{$p$} \hfill $(1)$
   	\item \qquad \qquad $p \to s$ \hfill $Premise$
   	\item \qquad \qquad \tikzmarknode{end2}{$s$ \qquad\quad} \hfill $(5)+(6)+\to e$
   
   	\item \qquad $s$ \hfill $(1)-(7)+\vee e$
   \end{enumerate}
   \begin{tikzpicture}[overlay,remember picture]
   	\node[draw,inner sep=9pt,fit=(block1)(end1)]{};
   	\node[draw,inner sep=9pt,fit=(block2)(end2)]{};
   \end{tikzpicture}
   ```

6. 最后附上完整的代码

   ```latex
   \documentclass[UTF8]{ctexart}
   
   \usepackage{bussproofs}
   \usepackage{calc}
   
   \usepackage{tikz}
   \usetikzlibrary{tikzmark,fit}
   
   \begin{document}
   	A simple proof tree.
   	\begin{prooftree}
   		\AxiomC{$p$}
   		\AxiomC{$p \to q$}
   		\RightLabel{$\to e$}
   		\BinaryInfC{$q$}
   	\end{prooftree}
   
   	Yet another proof tree.
   	\begin{prooftree}
   		\AxiomC{$p \vee q$}
   
   		\AxiomC{$p$}
   		\AxiomC{$p \to s$}
   		\RightLabel{$\to e$}
   		\BinaryInfC{$s$}
   
   		\AxiomC{$q$}
   		\AxiomC{$q \to s$}
   		\RightLabel{$\to e$}
   		\BinaryInfC{$s$}
   
   		\RightLabel{$\vee e$}
   		\TrinaryInfC{$s$}
   	\end{prooftree}
   
   	Proof tree(s) with boxes.
   	\newsavebox{\prooftreeOne}
   	\sbox{\prooftreeOne}{
   		\AxiomC{$p$}
   		\AxiomC{$p \to s$}
   		\RightLabel{$\to e$}
   		\BinaryInfC{$s$}
   		\DisplayProof
   	}
   	\newsavebox{\prooftreeTwo}
   	\sbox{\prooftreeTwo}{
   		\AxiomC{$q$}
   		\AxiomC{$q \to s$}
   		\RightLabel{$\to e$}
   		\BinaryInfC{$s$}
   		\DisplayProof
   	}
   	\begin{prooftree}
   		\AxiomC{$p \vee q$}
   		\AxiomC{\fbox{\parbox{\widthof{\usebox{\prooftreeOne}}}{\usebox{\prooftreeOne}}}}
   		\AxiomC{\fbox{\parbox{\widthof{\usebox{\prooftreeTwo}}}{\usebox{\prooftreeTwo}}}}
   		\RightLabel{$\vee e$}
   		\TrinaryInfC{$s$}
   	\end{prooftree}
   
   	LEM example.
   	\begin{prooftree}
   		\AxiomC{}
   		\RightLabel{$LEM$}
   		\UnaryInfC{$p \vee \neg p$}
   	\end{prooftree}
   
   	A simple proof sequence.
   	\begin{enumerate}
   		\item \qquad $p \vee q$ \hfill $Premise$
   
   		\item \qquad \qquad \tikzmarknode{block1}{$p$} \hfill $(1)$
   		\item \qquad \qquad $p \to s$ \hfill $Premise$
   		\item \qquad \qquad \tikzmarknode{end1}{$s$ \qquad\quad} \hfill $(2)+(3)+\to e$
   
   		\item \qquad \qquad \tikzmarknode{block2}{$p$} \hfill $(1)$
   		\item \qquad \qquad $p \to s$ \hfill $Premise$
   		\item \qquad \qquad \tikzmarknode{end2}{$s$ \qquad\quad} \hfill $(5)+(6)+\to e$
   
   		\item \qquad $s$ \hfill $(1)-(7)+\vee e$
   	\end{enumerate}
   	\begin{tikzpicture}[overlay,remember picture]
   		\node[draw,inner sep=9pt,fit=(block1)(end1)]{};
   		\node[draw,inner sep=9pt,fit=(block2)(end2)]{};
   	\end{tikzpicture}
   
   \end{document}
   ```

   

