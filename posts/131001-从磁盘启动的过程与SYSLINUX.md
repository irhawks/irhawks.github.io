---
title : 从磁盘启动的过程与SYSLINUX
date  : 2013-10-01
tags  : 开机原理, SYSLINUX, boot
---

磁盘启动原理
------------------------------------------------------------

PC在启动的时候是从执行ROM当中的代码开始的。这些代码常根据机器的不同而分布在不同的位置。PC上这种初始化代码称为BIOS(基本输入输出系统)。在PC里有几种不同的BIOS固件。如主板BIOS,显示卡BIOS,以及网卡BIOS.

BIOS通常让用户选择从哪一个设备引导。一旦确定引导设备，BIOS就加载在该设备开头的512字节的信息。这个512字节的段称为MBR.MBR中包含一个程序，它可以执行中决定从哪个位置（哪个分区）加载boot loader(也就是引导程序)。

实际上在一个磁盘设备上从0x0000到0x01bd这446字节为MBR代码，从0x01be到0x1fd这64字节包含有4组分区表信息DPT.在0x01be处的值为引导标志，值为80代表活动分区。而MBR中的0x01fe到0x01ff为结束标志，内容总是0x55aa.

每一个引导程序要求使用的MBR是不相同的，但其中分区位置对于每一个MBR都是相同的，一般来说，在为一个设备安装上引导程序的时候，仅覆盖前446字节中的一部分。

MBR成功执行后一般会进入到第2到第63扇区执行额外的启动代码，进一步创建引导程序环境。对于GRUB来说，boot.img里的内容被复制到MBR中，负责把第二扇区加载到内存中的0x8000位置并执行（称为diskboot.img）。而第二diskboot.img的功能则是加载GRUB的启动映象kernel.img.（kernel.img从第二扇区开始，到第63扇区结束）。

最终当然还是要进入具体的某个分区。因此在启动器中分区实际上是从某个扇区之后开始的。根据MBR中的信息可以确定每个分区的开始位置，因此理论上当然能够通过前63扇区把分区开始处的代码加载到内存并执行。

在某分区上的引导程序具有读取分区文件系统的能力，因而可以像一个操作系统那样使用特定的配置文件或者加载特定的配置。一般来说，引导程序的相关模块都位于该分区的boot目录下。实际上我们是通过引导程序定位我们需要启动的内核，以及启动时向内核传递的参数。

SYSLINUX创建可引导设备
------------------------------------------------------------

首先应下载并解压SYSLINUX软件。之后的步骤先以linux为例。

进入到SYSLINUX的软件目录，然后执行

```shell
$SYSLINUX$/linux/syslinux -i /dev/sdXn
```

这表示把syslinux安装到一个设备的特定分区当中。当然我们可以查SYSLINUX手册以向syslinux程序传递在该分区的安装目录。

之后我们需要将SYSLINUX的MBR映象写到设备的MBR当中，并将SYLINUX所安装的分区设置为活动分区：

```shell
dd conv=notrunc bs=440 count=1 if=mbr.bin of=/dev/sdX
parted /dev/sdX set 1 boot on
```

最后就是把内核映象复制到sdXn分区的适当位置，通过syslinux.cfg文件将内核映象的启动信息告知SYSLINUX引导程序。就等着在启动时SYSLINUX搜索syslinux.cfg文件了。

在WINDOWS下所做的工作与linux下实际没有什么不同。只不过在WINDOWS下面分区是通过盘符指定的。

```shell
$SYSLINUX$/win32/syslinux.exe --mbr -a X:
```

然后直接复制内核映象，创建内核启动配置参数。

如果使用EXTLINUX,则命令更为简单一些。先把它安装到特定目录下，EXTLINUX会在分区的引导扇区写上引导信息，然后在该设备的MBR上写入SYSLINUX的MBR引导程序。

### SYSLINUX系列引导程序

SYSLINUX系列的引导程序有SYSLINUX, ISOLINUX, PXELINUX与EXTLINUX. 其中的SYSLINUX只能安装在FAT或者FAT32分区下，ISOLINUX只能安装在ISO 9660/EI分区下，EXTLINUX只能安装在ext2/ext3/ext4/btrfs分区下，PXELINUX则是用于从网络位置启动内核。

相比于从本地磁盘启动，PXELINUX要麻烦一些，不仅需要TFTP,还需要DHCP等服务。更何况还需要特定的硬件支持。

刚才介绍了使用syslinux创建可启动分区的方法，extlinux与此类似。一般来说我们如果设置一个空白磁盘为可启动设备，首先要使用分区工具，然后使用格式化工具产生一个适合引导程序扩展功能的分区文件系统。为了更好地了解引导程序。我们借助于linux强大的设备虚拟能力介绍引导程序的安装与使用。

### 创建磁盘映象

首先创建一定大小的空白文件：

```shell
dd if=/dev/zero of=hdd.img bs=1M count=100
```

然后将这个空白文件虚拟成一个设备

```shell
insmod loop.o
losetup /dev/loop0 hdd.img
```

在使用losetup命令的时候，好像连root权限都不需要。

挂载这个设备后使用fdisk工具分区。进入fdisk的专家模式，使用p查看分区开始的位置（在start列下面）。计算出偏移值为Start*512bytes.实际上应当乘以sector size这一个参数，在主界面下使用p命令可以看出其大小。通常为512字节。

然后缷载该设备，重新从偏移位置挂载设备，这次挂载的就是刚才对应的分区了。

### 如何创建一个可引导光盘映象

使用ISOLINUX工具。除此之外还需要mkisofs工具。

首先创建一个 ``CD_root`` 目录，把所需文件都拷贝进去。然后创建isolinux子目录。将SYSLINUX软件包里的isolinux.bin以及相应的模块，配置文件都拷贝进去。 

之后在 ``CD_root`` 下面创建所需的内核与软盘映象，之后使用以下命令创建光盘：

```shell
mkisofs -o bootable.iso -b isolinux/isolinux.bin -c isolinux/boot.cat \
	-no-emul-boot -boot-load-size 4 -boot-info-table CD_root
```

其中的boot.cat是用于光盘文件系统的目录文件。

### SYSLINUX配置文件的查找

启动时ISOLINUX会尝试从三个目录中查找isolinux.cfg:/boot/isolinux,/isolinux/以及./。在syslinux中有根目录和家目录的概念。根目录是所在的分区，而家目录是启动文件所在的目录。

从4.02开始，ISOLINUX的也可以以syslinux.cfg作为配置文件名。如果在当前查找目录中没有isolinux.cfg,先在当前目录查找syslinux.cfg,失败再查找下一搜索目录。

SYSLINUX与EXTLINUX的查找配置文件也是按照以上的顺序。EXTLINUX与ISOLINUX类似，在查找extlinux.conf失败后查找syslinux.cfg,然后在下一目录中查找。

### SYSLINUX配置文件的格式与含义

全局选项当中：

| DEFAULT [module]:	所使用的菜单系统
| PROMPT [01]:	关闭选项时，仅在shift,alt,caps,scroll按下时进入SYSLINUX命令行
| UI [module] [options]:	用于设置菜单模块和菜单模块参数，会覆盖PROMPT
| NOESCAPE [01]:	生效时，忽略shift,alt,caps的动作
| NOCOMPLETE [01]:生效时，忽略TAB动作
| IMPLICIT [01]:	失效时，仅加载在label中出现的内核映象
| ALLOPTIONS [01]:生效时，允许用户修改内核参数
| TIMEOUT [int]:	用户没有动作的时候，菜单显示的时间（单位是1/10秒）
| TOTALTIMEOUT [int]:	所有选择所花费时间加起来不超过的某个数值。
| CONSOLE [01]:	是否向终端输出信息
| FONT [name]:	加载一个.psf字体文件，如果其中有unicode字符字体将被忽略。影响除版权所有这一行文字外的所有文字（因为后者是ldlinux.sys产生的）。
| KBDMAP [keymap]:加载一个简单的键盘布局
| SAY [message]:	在加载指定内核时在屏幕上显示的提示信息
| DISPLAY [filename]:	在启动的时候显示指定文件里的内容
| F[1-12] [filename]:	指定按次序要显示的文件，当功能键被按下时才显示

创建一个标签：

```shell
label <command name>
	menu label <label name displayed>
	[<menu default>]
	kernel ...
	append ...
	...
```

标签选项当中：

| ONERROR [cmd]:	当内核启动失败时执行的命令，实际上还是传给APPEND.
| KERNEL [executabe]:	使用该菜单项后所执行的SYSLINUX模块，内核映象，以及其它的自举程序。
| LINUX [image]:	效果等同于KERNEL选择，不过专门用于启动linux映象。
| APPEND [options]:	该选项指定了向KERNEL中所示程序传递的参数。
| INITRD [files]:	该选项指定linux内核启动时所需的initrd文件，等同于在APPEND中添加initrd=[files]选项。

<!--系统启动的时候的配置中，至少存在几个方面的问题。我们不如分类地学习。首先是启动器与内核参数的配置。然后是守护进程的配置，再次是在用户登录的时候，以及计算机启动的时候ROOT需要运行的脚本。最后一个则是运行级别。让我们控制服务如何被切换。这一系列的机制大概需要在我们对于POSIX有更详细的了解。-->
