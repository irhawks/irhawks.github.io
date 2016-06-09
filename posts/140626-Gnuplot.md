---
title : Gnuplot绘图
date  : 2014-06-26
tags  : gnuplot, 绘图, 可视化, python
author: irhawks
---

使用过很多的绘图的软件了，但是用起来总是不那么方便。而且我的绘图是在文档当中的，要求与文档有相同的风格。但是通常情况下，这些都难以达到。因此，不管是Asymptote还是其它的软件，配置起来都比较麻烦。

MetaPost的问题是，Metapost与XeTeX不太兼容。使用中文的时候又不方便了。所以我们还是使用其它的方法。

gnuplot有一个优点，就是它可输出成TeX的源代码的格式。第一种是LaTeX自带的picture环境，在里面直接绘图。第二种是tikz环境。无论哪一种环境，排版的工作都是连同文字一起的。所以正文是什么格式，其它文章也可以是这样的格式。

如果将gnuplot的输出改成picture环境，那么在每个gnuplot文件前面添加如下的行：

```gnuplot
set terminal latex    ## 也可以是emtex环境。
set output "pic.tex"  ## 生成的.tex文件。
```

然后使用`\input{pic.tex}`将生成的文件嵌入到文本中，注意段落的安排，以及将图表排版有适当的空格。

如果将gnuplot的输出改成tikzpicture环境，那么在每个gnuplot文件前添加

```gnuplot
set terminal tikz     ## 也可以是 set terminal lua tikz。
## 还可以在 tikz 后添加额外选项，如 fontscale 0.9 , latex, tex, context。
set output "pic.tex"
```

同样使用`\input{pic.tex}`将生成的文件嵌入到文本中。不过tikz图像 也可以在 `plain TeX` 环境下使用，因此使用这种方法，支持在tex或者xetex环境中插入图片，并不局限于latex或者xelatex。如果是在LaTeX环境中使用，则需要使用如下的宏包：

```tex
\usepackage{tikz}
\usepackage{gnuplot-lua-tikz}
```

如果是plain TeX，则使用`\input gnuplot-lua-tikz.tex`命令。这样一来，gnuplot就非常能够满足我们的需要了。所以我们学习绘图也就从
它开始讲起。

## Gnuplot绘图基础

Gnuplot是一个交互式的绘图语言。绘出的图形展示在一个设备上。所以我们在绘图脚本中需要指定绘图的终端类型，以及输出的文件。默认情况下，Gnuplot是将图形输出到显示器。我们也可以更改成其它类型。前面我们就已经介绍了如何将图形导出成 `.tex` 格式。实际上，Gnuplot支持几乎所有的图片格式与文档格式，完整的支持可以参考Gnuplot官方文档的 `Terminal Types`一节。

从4.6版本开始，Gnuplot支持了控制语句 `if/else/while/do`。这使得一些 表达式变得非常简单。

建议对Gnuplot文件使用 `.gpl` 扩展名。

出于排版文档的需要，在绘图之前，我们需要明确地指定绘图画布的大小，使图片不超过这个区域。在Gnuplot中，是通过 `set termial` 命令的`size XX,YY`实现的。任何终端均支持这个选项，前面的文档也不例外。如果`terminal` 类型 是 `tikz` ，那么默认的单位是 `cm`，后面跟数字。实际上， `XX` 、 `YY` 的 单位也可以是`mm` 、 `in` 、 `pt`等。建议在绘图之前给图像确定一个大小。

`set size XX,YY` 命令也起到设置图片大小的命令。但是它只是改变绘图区的大小，而非改变画布的大小。绘图区的大小可以通过 `ratio` 等指定，分别表示在 \(X\) 或 \(Y\) 方向的比例缩放的情况。

在Gnuplot当中，绘图都是通过绘图语句实现的，因此讲的并不多。重点的是Gnuplot的数据类型与运算规则。

而Gnuplot的表达式运算规则主要来自于C语言。与C语言相同，Gnuplot的表达式中间的空格会被忽略。

在Gnuplot当中，复数值有特定的表示方法，一个二维数组，用大括号括起来，就是一个复数，第一分量代表实部，第二分量代表虚部。如 `{3,2}` 代表着复数 \(3+2i\)。如果对字符串使用用于数值类型的运算符，则Gnuplot尝试把字符串转成数值再进行运算。比如在Gnuplot当中， `"3"+"4"=7` ，并且 `6.78="6.78"` 。

对字符串允许使用下标运算符 `[BEGIN:END]` ，表示提取数组中区间$[BEGIN,END]$中的元素。使用 `*` 号，可以代表对其中一个区间不加限制。

在Gnuplot当中内置了许多数学函数，而反函数在原函数前加 `a` ，如 `sin(x)` 的 反函数是 `asin(y)` 。三角函数的单位是弧度。`**` 表示取幂运算， `*` 表示乘法。 `.`表示字符串的连接。 `ne` 、 `eq` 表示字符串的相等的判断（而 `==` 表示 的是两个数值类型的相等。

### 绘图语句

在Gnuplot中实际绘图的语句只有 `plot` 、 `splot` 、`replot` 三个。 `plot` 语句产生2D图形， `splot` 产生3D图形，而 `replot` 则是把它的参数 加到前一 `plot` 或 `splot` 语句绘图当中，并修改它们的绘图结果。

`plot` 绘图可以使用直角坐标或者极坐标，具体行为受到 `set polar` 命令的 影响。 `splot` 绘图仅能使用直角坐标，但是也能通过 `set mapping` 选项使用其它的一些坐标系。最后， `using` 命令可以让我们对付大多数的坐标系。

在直角坐标系下面， `plot` 命令可以使用四个坐标轴 \(X\) 、 \(X2\)、 \(Y\) 和 \(Y2\) 。它们分别代表底、顶、左、右方向的坐标轴。
`axes`
选项可以指定我们所使用的数对分别与哪一个坐标轴相对应。坐标轴的刻度也可以修改。比如 `set logscale xy` 允许我们对两个坐标轴都使用对度刻度。

`splot` 命令可以绘制表面图(surfaces)或者等高图(contours)。使用 `set contour` 或者 `set cntrparam` 命令可以改变绘图等高图时候的行为。在3D绘图中，对坐标轴同样可以使用不同的刻度，如对数刻数。

### 绘图的参数来源

Gnuplot的绘图语句中都可以直接书写绘图的表达式，它们含有若干个变量。但是表达式可以有不同的产生方法。在赋值语句中，以单引号括起来的内容表示一个Shell命令。在解释时，Gnuplot会将出现的地方替换成相应的结果。比如$f(x)=`whoami`$ ，实际上是$f(x)$等于命令$whoami$执行的结果。

在shell命令中，也可以通过 `@var` 引用Gnuplot里面的变量。即使 `\\\``出现在字符串双引号当中，也并不影响命令的执行。`"\`uname -a\`"`返回的仍然是命令的结果。不过 `"uname -a"`并不会引起Gnuplot执行一个系统命令。

绘图语句与绘图风格是相关联的。绘图风格指的是图形的类型，比如直方图，散点图等。绘图风格不同，绘图语句的行为也不相同。

绘图风格由 `set style` 指定。常包括 `set style data` 与 `set style function` 。它们影响其后的 `plot` 与 `splot` 语句的行为。


## GNUplot绘图工具


使用之后，除了命令行不太方便外，其它地方还很方便。至少可以直接整合到LaTeX里面，这样就使排版的效果大大增强了。

GNUplot的用法其实很简单，其设置是样式、选项与绘图的综合。绘图语法中需要指定数据源以及绘图的样式即可。坐标轴也各自有自己设置的办法。

对GNUPLOT有疑问的话，可以直接使用help语句，此时在对话界面中会显示出来相应的帮助。另外，gnuplot的一个简单的例子如下：

```gnuplot
set terminal png size 1000,400  
set output "./sin.png"  
plot sin(x)  
```

gnuplot的命令有两类，一类是修改状态，一种是绘图指令。set方法都是修改状态。使用plot, replot, multiplot来绘图。

gnuplot对于数据中的时间项有很好的支持，可以直接将文本中某些数据项设置成时间的格式。这一功能对于日志分析与统计报表极为有用。

\url{http://www.gnuplotting.org/tag/label/}上面列举了许多极有有趣的例子。

\url{http://www.phyast.pitt.edu/~zov1/gnuplot/html/histogram.html}上面给出了调整直方图的一个教程。

命令式编程语言的绘图包括Python绘图工具，gnuplot, 以及C语言的编译工具等。
