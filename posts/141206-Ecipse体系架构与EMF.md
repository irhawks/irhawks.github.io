---
title : Eclipse体系结构与Ecore技术
date  : 2014-12-06
tags  : Eclipse, Ecore, Modeling, 建模, Feature Model, 特征建模, EMF
---

这对于理解Eclipse的建模的技术至关重要。Eclipse Modeling Framework(EMF)是Eclipse提供的一套建模的框架，可以使用EMF建立自己的UML模型，设计模型的XML格式或编写模型的Java代码。EMF提供了一套机制实现功能的相互转换，大大提高了效率。

统一Java、UML与XML的Ecore文件
---------------------------------------------

故事不妨从程序员开始。一般的程序员都是上来写Java代码，但是按照软件工程的要求，往往要先开始建模。两种思路各有千秋吧。但是如果我们能写一份代码，然后自动转成另一种格式，明显会使程序员舒服许多，同时又减少了程序员对软件工程的抵触情绪。这种思路能够转变成为现实，这是因为，Java代码描述，UML描述是等价的，理论上也就存在一种转换的可能。（特别是类图的转换）。

Java的接口是统一UML类图与代码的关键。因为Java的接口只有声明而不需要实现，与UML的类图的描述正好相同。如果Java类中包含了代码实现，反而比UML描述的东西更多了。（也许UML不适合在算法的级别上描述软件）。UML图形的保存的格式是XML的，准确地说，是基于XML Schema。

如果我们想设计一种模型，然后在三种模型之间转换，那么就要借助于EMF Model了.EMF给我们的回答是，在软件开发中，设计既可以从UML图形开始，也可以从Java代码开始，也可以从XML Schema开始。这样，大概结束了设计与编程的地位的高低的问题。解决了这个“To model or to program, that is not the question”。(这个思想大概同Knuth的观点相同，关键是EMF似乎也允许了既不是自顶自下也不是自低向下的设计。）

但是我们先看为了统一三种模型，我们应该考虑哪些现实的问题：

* 在UML与Java中是类的东西，在XML Schema中被定义成复杂类型
* 在UML中使用属性，在Java中使用get/set方法，而在XML Schema中是内嵌元素类型
* 在UML中是类的关联或者引用，在Java中可能是方法，在XML Schema中是另一种复杂类型的内嵌元素类型

于是要实现EMF和三种模型的转换，需要一种能够描述EMF模型的模型，这个模型我们称为元模型，也就是Ecore(Meta)模型。

Ecore模型位于MOF的M2层，它本身也是EMF模型。Ecore模型本身是可以用于描述自身的模型。Ecore是OMG的MOF建议在Eclipse下的一种实现，同时MOF的M2模型还有其它的实现形式。Ecore模型的实例，使用XMI序列来表示。在Eclipse中，导出EMF模型，实际上是导出一个EMF模型，也就是导出EMF模型的XMI格式。

EMF能够将Java接口自动生成UML的属性和方法，但是并非所有的Java接口都自动会生成UML的属性和方法。其实要生成相应接口与方法，编写Java代码的时候必须符合一定的规范。

EMF的核心就是Ecore和它的XMI序列化格式。通过UML、XML Schema与Java接口，Eclipse提供了一种转换成Ecore模型的方法。而且转换Ecore之后，可以生成这三种模式以及其它形式的模型。

使用XML Schema不仅定义了模型，而且还指定了模型实例的持久格式（？）。还有其它的持久模型格式，如Relational Database Schema (RDB)。

注：持久模型好像指的是，Java代码中也有不是自动生成的部分，这部分需要我们手动编写。如果自动工具能够识别哪些是手写的，哪些是自动生成的，然后在更新模型的时候保留我们手写的那部分，则就称为是一个持久化的模型。

EMF是一个强类型的语言。我们也许可以从形式语言的一般理论中理解它。

Ecore模型可以使用GMF可视化工具编辑(就是那个树形的编辑框)。注意，使用Eclipse新建Ecore文件的时候，最好还是不要使用纯文件建立一个空白文件类型，那样要做很多多余的工作，直接新建Ecore Diagram即可，因为它生成的是Ecore文件。

Papyrus插件中再安装上Extras软件包之后就可以有生成Java或者C++的代码的功能了。
Papyrus<http://download.eclipse.org/modeling/mdt/papyrus/updates/releases/luna/extra>。


Eclipse的体系结构
---------------------------------------------

了解Eclipse的体系结构对于后面要进行的开发会有一些好处吧。Eclipse的骨架是OSGi体系结构，它是Open Services Gateway Initiative的简称。OSGi技术原是为嵌入式硬件而开发的，使网络上的服务提供者和使用者互相交互。

在OSGi中，所有被配置的组件都是以插件的方式提供的。SWT和JFace是Eclipse的最基本的用户接口API。在其上提供了基本的UI Workbench。在然后上面就有了更新管理器与帮助系统，它们构成了Eclipse的框架。

插件为了自身能够对其它插件进行扩展而提供“扩展点”。当要为插件提供增加功能的时候就可以利用这个扩展点。在扩展点的基础上，插件之间可以互相连接。扩展和扩展点之间的连接是在程序执行的时候被建立的，提供扩展点的插件事先并不知道该扩展点在实际运行的时候被展了什么样的行为。使用扩展点的插件需要在其源代码的plugin.xml配置中使用`<extension>`元素声明该扩展点。基本格式为:

```xml
	<extension point="被使用扩展点的ID">
	    ......
	</extension>
```

像这样的扩展点和扩展不断地积累，使得Eclipse平台能够实现各种各样的功能。Eclipse平台提供的扩展点许多类，其中有三类比较基础：

* 增加菜单项
* 增加视图
* 增加编辑器

在Eclipse的帮助中有Eclipse提供的所有扩展点的说明，可供编写扩展时参考。我们也可以为自己的插件定义一个扩展点。

在开发Java的时候，我们已经熟悉了Eclipse窗口由工作台、菜单栏、工具栏、工作台页（也就是包含一个个子窗口的容器）、状态栏构成。其中工作台页又有视图、编辑器等类型的子窗口，通称为透视图(Perspective)。Eclipse工作台即Workbench，它是整个用户接口的总称。

我们的插件使用org.eclipse.ui.PlatformUI类访问工作台，示例如下：

```java
//取得工作台
IWorkbench workbench = PlatformUI.getWorkbench();
//取得工作台窗口
IWorkbenchWindow window = workbench.getActiveWorkbenchWindow();
//取得工作台页面
IWorkbenchPage page = window.getActivePage();
//取得当前处于活动状态的编辑器窗口
IEditorPart part = page.getActiveEditor();
```

在Eclipse启动时，会要求用户配置一个工作空间(workspace)作为开发人员作业的一个区域。它在物理上是一个文件夹。在逻辑上，生成工程、创建文件等操作，一般都会在工作空间中的指定文件夹里面生成实际的文件。Eclipse使用org.eclipse.core.resource在Eclipse启动时，会要求用户配置一个工作空间(workspace)作为开发人员作业的一个区域。它在物理上是一个文件夹。在逻辑上，生成工程、创建文件等操作，一般都会在工作空间中的指定文件夹里面生成实际的文件。Eclipse使用org.eclipse.core.resources包定义的虚拟对象操作工作空间里的资源。如工程是IProject、文件夹是IFolder、文件是IFile。对工作空间的访问就使用org.eclipse.core.resources.ResourcesPlugin。下面的代码给出了访问工作空间的代码示例：

```java
//取得工作区的root
IWorkspaceRoot wsroot = ResourcesPlugin.getWorkspace().getRoot();
//取得项目
IProject[] projects = wsroot.getProjects();
```

工作台和资源访问的API是Eclipse提供的API中最基本的，在插件开发时使用频率较高的API。使用PlatformUI作为工作台访问的入口点和使用ResourcesPlugin作为工作区访问的入口点，是无论如何也要记住的。

插件如何与Eclipse交互全在plugin.xml配置文件当中。`<extension>`元素有point属性以指定扩展点的位置，里面通常包括将插件的图标放在哪里，以及点击插件的时候要调用的动作。另外，注意Activator类，该类为插件提供了生命周期管理。

Eclipse中的Compare功能已经可以在Ecore与UML模型之间相互比较了，在Package Explorer中选择多个文件，然后右键找Compare中的Compare as Model，即可以在语法的级别上进行模型的不同的检查。

Papyrus中包含一些Components，比如Diagram generation, 用于从一个语义UML模型中生成Papyrus图表。Papyrus Compare则用于以语义的形式或图表的形式比较Papyrus模型。C++ Code Generation用于生成C++的Profile与代码。


模型驱动开发
---------------------------------------------

为了支持软件工程以建立大规模的软件系统，传统的编程思想必须发生改变。比如，如果直接访问数据，那么数据读写之后就只是数据的读写，而不会对其它的类产生影响，也不会向软件系统中的其它部分发出通知。这表明，编程方法的好坏是有条件的。在小程序上工作很好的方法，在处理软件系统的问题的时候，就变成非常差的方法了。如果我们坚持不用get/set方法，那么读写数据之后触发其它的动作简直就是不能想象的。

### 工厂方法

Eclipse中为我们展示了一个基本的例子。一般创建对象的时候，我们总是使用new的方法。但是这种方法，并没有形成创建对象的统一的模式。于是就了有工厂类。该类的功能就是提供创建各种对象的接口，把它们封装起来。比如：

```java
PurchaseOrder aPurchaseOrder = 
	POFactory.eINSTANCE.createPurchaseOrder();
```

用于创建一个购物单。调用该类的其它方法，可以创建其它的对象。使用这种模式，使得创建一个对象，看起来就像是访问不同的数据库一样。像是所有的数据访问的操作都被这一个对象代理了，于是就实现了所谓的“数据抽象”。相当于在人类社会中，有专门的仓库保管员来给我们做这样的事情，我们只需要发号施令即可（看起来人类总是希望指挥别人）。

我想EMF框架的最吸引人的地方不是自动地创建代码中的接口和类，而是配置生成器使得可以根据需要生成Factory类、Package类、Adapter类、Switch类等。EMF框架对面向对象的支持程度还有一些局限。比如动态绑定技术，在EMF中好像就没有得到充分的利用。但是我们知道UML是充分利用了这些技术的。

注：写到这里，我想到了Scala提供强大的面向对象的机制，使编程语言本身再结合面向对象的编程方法，可以写出非常漂亮、功能非常完善的程序的。

官方的软件提供了一些源，但是我们最好能够使用Eclipse Marketplace。该插件可以从Ecipse官方软件源中的General Purpose Tool中选择Marketplace Client选项。


Eclipse下Feature Model插件
---------------------------------------------

Eclipse下Feature Model是这样做的，首先在EMFT下面有Feature Model的Project，我们可以下载这个Project.然后我们要添加pure_systems提供的更强大的Feature Model与UML相结合的工具，因为Feature Model是变化性建模的标准工具。为此，先从<http://www.emftext.org/index.php/EMFText_Download>找到EMFtext的下载地址<http://emftext.org/update_trunk>下载EMFtext。

EMFText is an Eclipse plug-in that allows you to define text syntax for languages described by an Ecore metamodel. EMFText enables developers to define textual Domain Specific Languages quickly and without the need to learn new technologies and concepts.

下载后的EMFtext要被FeatureMapper工具使用。该工具可以从<http://featuremapper.org>找到，Eclipse源地址是<http://featuremapper.org/update>下载之后安装，然后可以使用这样的工具了。还有几篇论文可以使用。
