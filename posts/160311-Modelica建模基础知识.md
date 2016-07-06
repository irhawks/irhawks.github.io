---
title : 快速了解Modelica与OpenModelica建模1-基本知识
date  : 2016-03-11
tags  : Modelica, OpenModelica, 仿真
---


Modelica里面倒是有不少的面向对象的建模的工具，也支持PetriNet的描述。而且最近也有相关的论文的发表[@DBLP:conf/wsc/ProssBJH12]。OpenModelica上面的PNlib工具包倒好像是不错的。

OpenModelica是其一个实现。OpenModelica环境由若干个子系统构顶成。包括文本模型与图形模型编辑器、编译器调试器与执行环境、笔记本、优化器以及Eclipse插件。其中的编译子系统用于将Modelica语言编译成C代码。面向Eclipse的插件被称为MDT。最基本的方式自然是安装之后点击OMShell进入文本编辑环境。里面输入Modelica的代码。OMShell命令会打开一个新的窗格，使用OMShell-terminal命令可以直接在Linux终端中进入OpenModelica的环境。这时进入的就是交互式模式。

```modelica
model A Integer t= 1.5; end A;
instantiateModel(A);
model C
Integer a;
Real b;
equation
    der(a) = b;
    der(b) = 12.0;
end C
```

模型是Modelica中的基本元素，许多内容也就围绕着模型的定义来。模型可以用文件来定义，一般使用后缀.mo。使用loadFile命令就可以从文件中加载模型。使用system命令则可以执行操作系统的Shell的代码。

比如下面是使用Modelica写的冒泡排序的代码：

```modelica
function bubblesort
input Real[:] x;
output Real[size(x,1)] y;
protected
Real t;
algorithm
    y := x;
    for i in 1:size(x,1) loop
        for j in 1:size(x,1) loop
            if y[i] > y[j] then
                t := y[i];
                y[i] := y[j];
                y[j] := t;
            end if;
        end for;
    end for;
end bubblesort;
```

从上面可以看出Modelica的代码风格做得非常“冗余”。每个循环与条件语句必须显式被结束，每个函数体与模块也必须带显式的结尾处理。函数体中的输入、输出、局部变量与算法体必须各自区分开。

实际上Modelica的输出是通过基于CORBA的客户端实现的。更好的方式是通过readFile实现将文件中的函数等对象加载到当前工作区。在OMShell中，使用cd()函数可以返回当前工作路径，添加字符串参数之后可以切换工作路径。

OpenModelica有一些标准模型，它们使用loadModel()函数加载。比如loadModel(Modelica)，加载Modelica的标准库。下面是一个模拟运行的示例文件：

```modelica
loadFile("/usr/share/doc/omc/testmodels/dcmotor.mo")
list(dcmotor)  // 列出模型源代码
instantiateModel(dcmotor) //对模型进行实例化，得到实例化后的代码
simulate(dcmotor, startTime=0, stopTime=10.0)
```

模拟之后我们可以得到一系列变量，然后用它们来画图。val(variableName, time)函数就是用于得到模拟结果中的变量在特定时间的值的。

比如我们看如下的代码：

```modelica
loadFile("/usr/share/doc/omc/testmodels/BouncingBall.mo");
list(BouncingBall);
simulate(BouncingBall, stopTime=3.0);
plot({h,flying});
```

在OMShell中运行的代码可以保存成.mos格式（Modelica script）。然后通过runScript命令来运行。（使用writeFile可以将字符串写入特定文件）。

接下来我们演示一个开关的模拟的例子：

```modelica
model Switch
    Real v;
    Real i;
    Real i1;
    Real itot;
    Boolean open;
equation
    itot = i+i1;
    if open then v=0;
    else i=0;
    end if
    1-i1=0;
    1-v-i=0;
    open = time >= 0.5;
end Switch;
simulate(Switch, startTime=0, stopTime=1);
val(itot,0);
```

类似于Matlab，可以使用clear()清楚当前工作区，使用list()查看加载的模型。在OpenModelica当中，控制结构、函数、变量、类型都是非常正常的概念，还可以使用typeOf()函数查看变量的类型。Modelica实现模拟主要是通过simulate函数。函数既可以输出成特定的模拟结果，也可以只保存特定的变量。也可以使用并行模拟（启动omc的时候指定并行的参数）。

Model的library又称package，使用package来定义，里面可以添加一些注释。

```modelica
package Modelica
annotation(uses(Complex(version="1.0"),ModelicaServices(version="1.1")));
end Modelica;
```

在加载模块的时候，如果指定了对指定包的依赖关系，那么指定包也会加载上去：

```modelica
model M
annotation(uses(Modelica(version="3.2.1")));
end M;
instantiateModel(M)
instantiateModel(Modelica.Electrical.Analog.Basic.Ground) //只加载其中的模块
list(Modelica) //查询名为Modelica的模块的模型。
quite() //退出Modelica环境
```

Modelica的模型可以转换成Matlab的模型，只需要一个exportDAEtoMatlab()函数就可以完成转换了。

omc命令是modelica的编译器。它可以读取一个.mo文件然后编译模型。另外，omc也可以执行.mos格式的脚本命令，以非交互的方式运行。还可以在运行中执行调试工作。

OMEdit是图形化的编辑模型的界面。里面可以使用预定义的模型、用户定义的模型，组件接口，以及模拟过程，还可以绘制图形。

在Model里面也可以定义algorithm。以调试算法。OpenModelica支持文学编程方法。在交互式Notebookk　就可以实现。

面向Eclipse的MDT支持Modelica与MetaModelica的开发。在相关网站上可以下载到OpenModelica的插件。之后就可以在Eclipse环境下进行工作了。也有高亮，也可以绘制出来图形。还可以进行调试等工作（使用GDB）。也有一些3D库，可以完成3D图形的建模等工作。除此之外，还可以方便地调用外部的C函数，或者调用Python的函数。另外，从Python中也可以调用Modelica的函数，使用OMPython。


## 关于Modelica

Modelica当然是一种通用的建模与模拟的软件。但是其建模的方式也有其特殊之处。首先是使用了面向对象的技术，一个模型可以看成是一个对象，并且像编程语言那样使用class关键字来声明。然后变量有相应的类型。模型中的恒等式可以使用DAE（微分代数方程，连续情形）或者Event triggerg来表示（离散时间）。比如如下的VanDerPol的方程模型：

```modelica
class VanDerPol "Van Der Pol振子模型"
Real x(start=1) "描述变量x";
Real x(start=1) "y变量";
parameter Real lambda = 0.3;
equation
der(x) = y;
der(y) = -x + lambda*(1-x*x)*y;    // 微分方程约束
end VanDerPol;
```

另外，Modelica还可以处理连续与离散情形混合的情况，进行混合的建模。另外则是Modelica语言显著缩短了在建模的时候进行系统定义、系统分解、子系统建模、因果关系推测、实现以及模拟所花费的时间。

Simulink是基于信号流进行建模的语言。但是Modelica语言则是完全按照物理模型的结构来的，中间不需要刻意去写成信号流图的形式。因此，我们可以直观地画出电路图就可以模拟，而不用转换成Matlab那种信号流的模式。另外，Modelica也可以进行图形可视化的建模，通过拖动实现模块的组合。

比如如下的直流电机的建模：

```modelica
model DCMotor
    Resistor R(R=100);
    Inductor L(L=100);
    VsourceDC DC(f=10);
    Ground G;
    ElectroMechanicalElement EM(k=10,J=10,b=2);
    Inertia load;  //器件与器件的性能参数
equation 
    //连接方程，Modelica会根据连接方程自动推导函数关系，转化成ODE与DAE的形式
    connect(DC.p, R.n);
    connect(R.p, L.n);
    connect(L.p, EM.n);
    connect(Em.p, DC.n);
    connect(DC.n, G.p);
    connect(EM.flange, load.flange);
end DCMotor
```

中间的执行流程是图形或者文本模型经过处理变成Modelica的源代码。变成Modelica的模型。然后通过Translator变成混合DAE所描述的方程。然后使用分析器进行分析，再用优化器优化成C代码。最后编译并执行。模拟的时候，OpenModelica中也可以选择交互式模拟的方式。

Modelica在生物、机械、化学、工业中都有比较成功的应用。练习OpenModelica的时候，刚开始可以从图形化的OMedit开始，建立一个RLC电路的模拟。网上有相关教程：

#.  打开OMEdit，文件菜单中选择新建模型，输入模型名RLCircuit（也就是新建Class，在OMEdit中也可以新建Modelica的元模型）。
#.  在左侧的库中选择Modelica下面的电路元件，将它们按标准连接起来。
#.  点击模拟即可。

Modelica与SysML、ModelicaML、UML也有合作。其中的ModelicaML就是为了支持软件与硬件建模而设计的UML Profile。还可以将UML/SysML映射到Modelica。

在Modelica语言中，类型有Boolean等。而变量可以加上constant或者parameter，表示不变的量或者变化的量（后者允许模拟的时候交互式调整）。class声明与model声明类似，但是class声明的可以被实例化，还有protected、public等修饰的变量。Modelica中函数也可以看成是特别的类。但是多了input/output、algorithm等块体。函数中也有protected的成员。record可以表示记录体结构、定义参数形式。Modelica也支持所谓的多继承。

最好可能还是从OMNotebook开始。因为里面有许多可视化。如果是离散的，那么可以在变量前面加上discrete修饰词。比如如下的离散模型：

```modelica
model SamplingClock
    Integer i;
    discrete Real r;
equation
    when sample(2,0.5) then
        i = pre(i) + 1;
        r = pre(r) + 0.3;
    end when;
end SamplingClock;
```

图形建模的时候有自己的规则。比如特别规定了connector为一种连接器类别。Modelica中定义了许多物理系统的连接器。使用connnect函数可以连接许多内容。连接器需指定连接方程，默认的方程是两端信号值相等。如果是flow函数，则表示流量相等，方向也是相同的。

在Modelica中不能被实例化的类称为partial class。DrControl是专门用于讲控制理论的一个建模的手册，可以方便地写出控制的方程来。
