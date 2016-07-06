---
title : JDK与OpenJDK的安装与使用
date  : 2013-05-01
tags  : JDK, Java, linux, Ubuntu
---

OpenJDK的官网上面的安装手册
---------------------------------------------------------------------------

在openjdk官网上面的资料<http://openjdk.java.net/install/index.html>

How to download and install prebuilt OpenJDK packages

### JDK 7

Debian, Ubuntu, etc.

On the command line, type:

``` {.sourceCode .bash}
sudo apt-get install openjdk-7-jre
```

The openjdk-7-jre package contains just the Java Runtime Environment. If you want to develop Java programs then install the openjdk-7-jdk package.

Fedora, Oracle Linux, Red Hat Enterprise Linux, etc.

On the command line, type:

``` {.sourceCode .shell}
su -c "yum install java-1.7.0-openjdk"
```

The java-1.7.0-openjdk package contains just the Java Runtime Environment. If you want to develop Java programs then install the java-1.7.0-openjdk-devel package.

### JDK 6

Debian, Ubuntu, etc.

On the command line, type:

``` {.sourceCode .shell}
sudo apt-get install openjdk-6-jre
```

The openjdk-6-jre package contains just the Java Runtime Environment. If you want to develop Java programs then install the openjdk-6-jdk package.

Fedora, Oracle Linux, Red Hat Enterprise Linux, etc.

On the command line, type:

``` {.sourceCode .shell}
su -c "yum install java-1.6.0-openjdk"
```

The java-1.6.0-openjdk package contains just the Java Runtime Environment. If you want to develop Java programs then install the java-1.6.0-openjdk-devel package.

### BSD Port

For a list of pointers to packages of the BSD Port for DragonFly BSD, FreeBSD, Mac OS X, NetBSD and OpenBSD, please see the BSD porting Project's wiki page.

### JAVA的环境变量设置

当安装好相应的JRE与JDK之后，一般Java的路径位于`/usr/lib64/jvm/java-1.7.0-openjdk`下面。注意如果只安装了JRE,那么这个目录就只有JRE一个子文件夹。

`JAVA_HOME` 就是上面的那个目录， `JRE_HOME`就是前面那个目录的jre子文件夹。一般而言我们还需要设置可执行文件的路径，以及需要加载的库文件。比如另外:

``` {.sourceCode .bash}
export JAVA_HOME=/usr/lib64/jvm/java-1.7.0-openjdk
export JRE_HOME=$JAVA_HOME/jre
export CLASS_PATH=.:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib.dt.jar:$JAVA_HOME/lib.rt.jar
export PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin
```

这就就完成的环境配置。一般情况下，还需要执行一下`java -version`{.shell}命令调试一下看看是否正常工作了。


JDK的相关的安装
-------------------------------------------------------------

随着版本的向前演变，程序的安装的方式也在不断变化。相对来说，JDK的安装还是比较容易的。我们只需要从官方网站上下载JDK，直接解压到/usr/lib/jvm目录下，然后更新目录即可。

比如下面就安装并配置好了JDK8

``` {.sourceCode .bash}
sudo bash
cd /usr/lib/jvm
tar zxvf jdk-8u25-linux-x64.tar.xz -C ./
##然后配置环境变量
vim .bashrc
export JAVA_HOME=/usr/lib/jvm/jdk1.8.0_25
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=$PATH:${JAVA_HOME}/bin
```

自从从Oracle收购Sun近三年来，已经有很多变化。早在8月，甲骨文将“Operating System Distributor License for Java”许可证终结，这意味着第三方将不可以依据这一许可分发他们的软件包。因此Ubuntu Linux已经开始禁用所有机器上的Oracle JDK浏览器插件，并很快会从档案中删除软件包。公司指出，禁用Oracle的插件将可以帮助提高安全性，因为这些插件已经被证实包含许多漏洞，虽然这是一个事实，但真正的原因恐怕是Sun的JDK在升级时会清理掉用户机器上自认为不安全的软件，大多数PC用户认为这样很安全，但通常基于UNIX系统的用户并不这么认为。Oracle的JDK被废弃后，OpenJDK将取代它的位置在Ubuntu及其它Linux中默认安装。

虽然很多Linux发行版现在已经自带OpenJDK，但是在开发过程中与Oracle-JDK(SUN-JDK)还是略有不同。通常，Java开发人员还是以Oracle-JDK为标准来进行开发。下面介绍一下Linux下的JDK安装与配置，这里使用的Linux发行版是Ubuntu 12.04。

由于一些Linux的发行版中已经存在默认的JDK，如OpenJDK等。所以为了使得我们刚才安装好的JDK版本能成为默认的JDK版本，我们还要进行下面的配置。

执行下面的命令：

``` {.sourceCode .bash}
sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk7/bin/java 300
sudo update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/jdk7/bin/javac 300
```

注意：如果以上两个命令出现找不到路径问题，只要重启一下计算机在重复上面两行代码就OK了。

执行下面的代码可以看到当前各种JDK版本和配置：

``` {.sourceCode .bash}
sudo update-alternatives --config java
```

注意Ubuntu的update-alternatives机制。它使得我们自己安装的软件也可以被系统很好地识别出来。

Java的版本库的管理
------------------

可以用Nexus来完成这件事件，不然Java的库在国内基本上下不来。参考网上的手册配置该应用程序。
