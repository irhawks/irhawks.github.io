---
title : 在Debian/Ubuntu系统下面的Java与Scala包
author : irhawks
date : 2015-05-24
tags : scala, java, sbt, ubuntu, deb
---

Java包目前在Ubuntu下面的管理
------------------------------------------------------

目前的情况是，许多的Java包也安装在系统当中，在系统中的路径是`/usr/share/doc`、`/usr/share/java`以及`/user/share/maven-repo`。三个路径中，`/usr/share/java`里面用于放置所需要的库，我们可以通过`apt-get source libjdom1-java`，并在当前目录下解包这个文件，然后就知道jdom1这个jar包是怎样被安装到系统当中去的了。

这里有一个官方的“为Java库构建deb安装包”
<https://wiki.debian.org/Java/MavenBuilder>
的指南。思想是利用Maven构建一个deb安装包。

I think a better way forward is to write a little program that takes the source jar (which most jars in the Maven central should already have) and the POM, then generate a build script that simply compiles the source jar into the binary jar. The said program should also inspect the jar file to figure out any resource files, and treat them as source files. That way, we can machine-generate Debian source packages. Granted, not all source packages produced that way would pass the requirements of the Debian Freesoftware Guideline, but I bet substantial number of Maven artifacts are simple enough that this will be actually completely satisfactory. And then humans can concentrate on harder ones.

对于Debian的世界来说，推荐的方式是在有二进制包的同时，提供源代码包（bin形式的包，与doc、src、dev都是不相同的）。所以目前的maven的只下载二进制包的方式与Debian的理念有一些冲突。

而且，目前的Java的做法的冲突的地方，就是指定了一个Java的版本之后，必须只用当前的那一个Java的版本。比如2.11.5与2.11.6就是不通用的。然而在一般的软件版本管理系统中，同一个major之下，只要比所需minor大的版本应该都是可用的。

The Debian folks have a standard response for this kind of attitude: “Patches are welcome.” If you don’t like it, you have the power to fix it. If you fix it, share the fixes.

Debian的理念是欢迎使用者在不同的情况下对软件作出修改。特别是，用户能够知道错误在什么地方，同时能够得到及时的反馈。如果应用程序出现一些错误，用户能够自己重新编译与测试这些东西。参考Debian社群契约<https://www.debian.org/social_contract>

Java与Scala的ABI规范可以参考<http://blog.ometer.com/2012/01/24/the-java-ecosystem-and-scala-abi-versioning/>。上面详细说明了Java与Scala的API版本管理的策略。其实主要的版本改变之后，整个工程就升级为一个“元工程”了。这个工程重要的是工程的思想，而不是工程制造出来的产品实践。

<https://wiki.debian.org/Java/MavenDebianHelper>上面介绍直接根据maven工程生成deb包是很容易的，只需要`mh_make`命令就可以了。但是现在Ubuntu上面好像没有这个工具了。（现在又有了）

<http://www.scala-sbt.org/0.13/tutorial/Installing-sbt-on-Linux.html>上面介绍了怎样在Linux发行版下面安装sbt。这里采用的是rpm/deb软件包的方式安装sbt。这是值得推荐的做法。但是并不一定每一个都是按照这种做法来做的。

生成maven的软件包可以参考所谓的jdeb与apt-repo工具，在github上面：<https://github.com/tcurdt/jdeb>。


Scala下面构建适用于特定系统的包
---------------------------------------------------

但是Scala下面的做法有了大大的不同，得益于scala-naive-packager工具。<https://github.com/sbt/sbt-native-packager>。它还是受到官方支持的sbt构建的方法。生成tar、rpm、deb等都不在话下。关于deb包的，可以参考：<http://www.scala-sbt.org/sbt-native-packager/formats/debian.html>。

sbt-native-packager可能的缺点就是它把依赖的jar包都放在程序当中，因此，整个程序显得非常拥挤了。其实按照集群来配置的话，/usr目录是放置软件的，没有必要每个结点机器上都安装一遍，那样也太占空间了。

我们来看具体的做法。

生成deb包被看成是构建任务的一部分。所以简化到使用一个plugin的程度。首先，我们指定sbt的版本：

```scala
sbt.version = 0.13.7
```

然后，在project/plugins.sbt文件中添加如下的插件：

```scala
addSbtPlugin("com.typesafe.sbt" % "sbt-native-packager" % "1.0.0")
```

之后，在build.sbt中启用相应的插件，并指定生成debian包的时候所需要的一些关键字段，比如维护者名称，开发者名称等。

```scala
name :="example-app"
version := "1.0"

//enablePlugins(DebianPlugin)
enablePlugins(JavaAppPackaging)
```

如果只想启用生成Debian包的功能，添加DebianPlugin模块就可以了。注意，这种方便性只能在sbt-native-packager版本不小于1.0，以及sbt版本不低于0.13.5的时候才能使用。

接下来，我们就要创建自己的应用程序了。比如TestApp.scala。这个文件的路径是src/main/org/scala/TestApp.scala。

```
object TestApp extends App {
  println("IT LIVES!")
}
```

要构建相应的工具，则使用sbt stage命令。这个时候，在target/universal/stage目录下可以看到bin、lib等目录。缺省情况下，会为JavaApp创建一个shell脚本，以及一个.bat批处理脚本。

接着，使用sbt universal:packageBin，sbt universal:packageZipTarball可以创建相应的tar包或者zip压缩包。这个包就可以直接发布出去了。


构建适合于Debian的包
-------------------------------------------------------------------

要想构建.deb包，直接的操作很简单，`sbt debian:packageBin`就是在target目录下生成.deb文件的最终命令。

然而，在生成.deb包之前，要对一些字段进行配置，如维护者的名称，邮件，软件的描述等。

```
packageDescription in Debian := "Example Cli"

maintainer in Debian := "Josh Suereth"

name := "Debian Example"

version := "1.0"

maintainer := "Max Smith <max.smith@yourcompany.io>"

packageSummary := "Hello World Debian Package"

packageDescription := """A fun package description of our software,
  with multiple lines."""
```

整体而言，这些字段不需要怎么理解，只需要自己填上去就可以了。

`sbt-native`支持`debian:package-bin`作为构建deb包的命令，`debian:lintian`作为使用lintian命令检查deb包是否正确的命令，以及`debian:gen-changes`作为生成.changes文件的命令。

为了在某种程度上能够保证软件包能够正常工作，在bulid.sbt中添加如下的依赖：

```scala
debianPackageDependencies in Debian ++= Seq("java2-runtime", "bash (>= 2.05a-11)")

debianPackageRecommends in Debian += "git"
```

如果还想自己编写DEBIAN的preinst、postinst等命令，直接写到src/debian/DEBIAN目录里面就可以了。

If you use the `packageArchetype.java_server` there are predefined postinst and preinst files, which start/stop the application on install/remove calls. Existing maintainer scripts will be extended not overridden. 这说明，Sbt对于布署Java服务器也有很好的支持。

完整的Debian配置文档，参考<http://www.scala-sbt.org/sbt-native-packager/formats/debian.html>。此外，<http://www.scala-sbt.org/sbt-native-packager/gettingstarted.html>还告诉我们可以使用`windows:packageBin`生成MSI安装文档。

sbt-native-packager生成的Java应用有两种，一种是JavaApplication，另一种是Java Server。前者是具有一个bash/bat调用接口，后者则除了有调用脚本之外，还有一些配置文件可以使用，还能够开机自动启动（不过目前还只是支持Fedora的systemd管理工具）。

注：Linux的服务管理机制很多。在Ubuntu下面，默认使用的是upstart，当然，也有systemV服务管理工具。Windows下面的，则是Windows Services程序来管理开机启动的各个服务脚本。

今天就先到这里吧。关于Python的软件包的配置，先放在后面再说。


Sbt配置nexus软件包的方法
-------------------------------------------------------------

类似于在maven中的添加软件版本库，sbt的方法是添加repositories的字段。注意里面的repositories的配置是在用户的.sbt/conf配置的repo.properties文档，内容为：

```config
[repositories]
  local
  nexus:  http://127.0.0.1:8081/nexus/content/groups/public
  sonatype-snapshots:
```

然后在conf目录中的sbtconfig.txt中添加三行

```shell
-Dsbt.global.base=E:/sbt/.sbt
-Dsbt.ivy.home=E:/sbt/.ivy2
-Dsbt.repository.config=E:/sbt/conf/repo.properties
## 可选的选项 -Dsbt.override.build.repos=true
## 这些选项也可以通过sbt_opts的环境变量进行全局的配置这样sbt执行的时候就不需要访问外网了。
```

之后从nexus的私服下载jar包。在nexus里面需要添加typesafe的仓库。<http://repo.typesafe.com/typesafe/ivy-releases>。但是注意一般还是要修改nexus虚拟库中的配置，需要把中央仓库放在最后，而把sbt的仓库放在前面。

不过nexus的配置也不是一件容易的事情。这些事情可以写成一本书了。比如<http://my.oschina.net/guanzhenxing/blog/209600>中介绍的配置nexus的数据库的原理。

<http://www.tuicool.com/articles/vMnyIb>上面告诉了我们scala的三个主站，分别是

安装Nexus后默认会有一个Public Repositories组，可以将其作为Maven的镜像组，并添加一些常用的第三方镜像：

```
cloudera: https://repository.cloudera.com/artifactory/cloudera-repos/
spring: http://repo.springsource.org/libs-release-remote/
scala-tools: https://oss.sonatype.org/content/groups/scala-tools/
```

对于Ivy镜像，我们创建一个新的虚拟组：ivy-releases，并添加以下两个镜像：

```
type-safe: http://repo.typesafe.com/typesafe/ivy-releases/
sbt-plugin: http://dl.bintray.com/sbt/sbt-plugin-releases/
```

另外一种方法是直接去配置`~/.m2/settings.xml`文档。或者maven目录下面的`conf/settings.xml`文件。
