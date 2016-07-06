---
title : 快速了解Modelica与OpenModelica建模2-ModelicaML与方程
date  : 2016-03-13
tags  : Modelica, OpenModelica, ModelicaML, 仿真, 建模, DAE
---

ModelicaML
---------------------------------------------

ModelicaML同样地用于系统建模。不过不是语言的方式，而是首先以UML类似的模型表示出相应关系，然后这种模型被转换成Modelica的代码。转换代码后就可以执行，模拟出结果。ModelicaML是UML Profile的一个具体的扩展。

ModelicaML的一个开发的方法是在Papyrus UML环境下进行。在此环境之下，通过Acceleo工具生成Modelica的代码，经过M2T工具生成Modelica的.mo文件，之后可以通过任何一个符合Modelica语言要求的模拟工具中运行出来结果。安装Modelica Development Tool的Eclipse插件之后，新建Papyrus工程，在模型语言（Diagram Language）提供的UML、SysML、ModelicaML、Profile中选择ModelicaML，这样就进入了ModelicaML的建模的环境了。之后我们就可以使用ModelicaML来完成建模了（UML本身可以用于元建模，这个时候，UML规范本身就是元元建模工具了）。

Modelica使用类UML的图形表示模型。有结构图、需求图、行为图等描述方法。注意到Modelica本身也是一种元模型规范。Modelica中的元素被看成是prototype，所有的类都是继承自该原型。ModelicaML充分利用了Modelica语言的特性，可以在状态图中使用Modelica的谓词语言与条件判断，同时，也增强了UML建模算法的能力（算法流程以及代数方程）。


另外，运行Modelica Script是使用runScript命令。Script可能不是Modelica语言规范的一部分，因为像System Modeler之类的工具的脚本是基于Wolfram语言的（比如典型的用中括号而非小括号调用函数）。OpenModelica还具有交互式模拟的能力。在运行的图表中，如果有ModelicaML的需求文档，能够对比需求目标与设计目标的差距（是不是比软件工程中的过设计与欠设计在功能方面的东西更直观？），另外，根据需要，可以建立可视化的模拟过程演示，包括3D力学系统的功能演示。

OpenModelica还提供了OMPython这样一个环境，可以整合Python语言工作区以及Modelica模拟语言。Modelica3D则能够实现3D图形模拟同步的演示，模拟流体、力学系能各种模型的结构化展示，而不仅是模拟出来函数图表。

OPENPROD提出了使用Modelica建模Cyber-Physical模型的一些开发方法，与模型驱动方法以及软件生命周期都有结合。里面还使用了业务流程控制、需求捕获、PIM与PSM的转换等概念。注意ModelicaML也是OMG规范的一种建模的格式。此外还有MetaModelica，需要注意的是，OpenModelica的编译器本身也是通过15万行的MetaModelica代码实现。

loadFile、loadModel之类的函数是所谓的CORBA API函数。


通过Modelica来理解多领域建模
---------------------------------------------

自己之前一直想不清楚控制理论与控制工程是怎样运行的。今天看到一个关于Modelica多领域建模的图表自己一下子就明白了。

这个图表是这样的，首先有一个电源驱动，然后进入电机的控制系统，电机系统最后与机械系统相连（电动力控制运行系统）。机械系统之后有一个所谓的角速传感器，这个传感器可以完成反馈。结果，这个传感器的信号就可以经过PID控制系统反馈到电力系统当中，通过调整输入电压、电流等方式间接地影响力学系统的转速等参数。这样的系统中涉及到电力系统、机械系统与控制系统三个领域，但是共同服务于一个现代电机。大概许多现代的系统都是多领域的吧。

Simulink是典型的使用因果关系建模的软件，系统中所有的信号都具有流向。但是Modelica的典型的方式是使用结构建模，通过方程约束完成建模。Simulink的这种建模思路需要人工做更多的处理。和Simulink一样，Modelica也支持子系统的建模。

Modelica可以看成是强类型的语言。在数组与矩阵运算模仿Matlab的同时，也可以进行非常多的强类型检查活动（似乎强类型以及静态类型成为最近程序语言的热点发展方向之一了）。

Modelica作为面向对象的语言，支持继承的概念，似乎因此我们可以扩展PNlib中的一些类，实现多个参数的建模过程（比如增加PetriNet中变迁的能力。[@book897383]是一本不错的介绍Modelica的入门书籍，讲解如何建模的。

英文中有simulation与emulation这两个东西。语义上似乎还有一些不同。在Modelica的领域，建模是与数学建模密切相关的。因为建模包括了物理系统、数学系统、语言的、心理的等几个领域。而数学与物理建模在科学与工程中起着重要的作用。Modelica的建模，通常可以从数学建模中分成静态与动态模型、定性与定量模型、连续与离散模型这一分类开始：比如说，Modelica通常是动态模型，能定性也能宣，能描述连续性也能描述离散性质。（甚至大概Verilog也是此类模拟语言吧，不过Verilog似乎只模拟信号系统，而不模拟物理系统的特性--不妨把不同系统的建模与模拟当成是本辑笔记第二卷与第三卷的内容）。

Modelica的特点可以总结如下：声明式为主，也支持过程式；支持多领域综合，使用面向对象的语言并且保留了矩阵运算的方便性。此外，还可以与ModelicaML，以及可视化组件相结合。Modelica具有一些函数式的风格（至于支持方程，应该是属于等式编程语言那一类）。Modelica内在是并行的，其函数有作用域的（不像Matlab），然后其类型系统受到Abadi/Cardelli的影响（其实面向对象语言大部分地方也是声明性的）。

Modelica语言规范可以从其官网上下载。不过其语言规范不是很有意思，因为Modelica提供了ModelicaML作为其抽象语法的另一种描述形式。后者或许看起来更直观一些（应参考Modelica最近的语言规范3.3版）。


Modelica的方程描述能力
---------------------------------------------

Modelica中的方程典型的形式是代数方程与左边为方程导数，右边为导数值的形式。另外的形式就是一个复杂的加减乘除的四则表达式。不知道是否支持隐式方程与复杂的导数方程（比如高阶导数以及导数的平方？）

下面是几种容许的约束形式：

```modelica
apollo.gravity = moon.g * moon.mass / ( apollo.altitude + moon.radius ) ^ 2;
apollo.thrust = if (time < thrustDecreaseTime) then force1 else force2;
red + blue + green = 1;
```

和SysML相比，Modelica虽然在描述模型的精确行为上很强大，但是在描述复杂系统中的继承关系、需求等的进候并不像SysML那样强大。为此就有了所谓的ModelicaML。该图表扩展了SysML的许多内容。比如，在基本Diagram概念增加了Simulation Diagram，在Structure Diagram中做了增强，在行为描述中添加了Equation Diagram。其余的大部分则与SysML保持了相同。

比如说，ModelicaModel也被认为是一种特殊的Class。
