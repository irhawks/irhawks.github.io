---
title : linux下的守护进程
date  : 2013-01-05
author : irhawks
tags  : linux, daemon, 守护进程, xinetd
---


守护进程的一般概念
-----------------------------------------------

**系统提供某某服务，而提供服务的进程称为是守护进程**（用英文说一个是service, 一个是daemon.）

也就是说从操作系统的观点来看，是守护进程，从IP网络的概念来看是服务。从应用的角度来看是服务。

也许可以把守护进程看成是一种持续监听某个端口的应用程序。这样以来它就总能够提供某种服务，也就不必是系统进程。也不必非是以root身份运行的程序。

unix下的守护进程分为独立守护进程与超级守护进程。在英文中一个是standalone daemon,一个是super daemon.如果一个守护进程的作用是管理其它的守护进程，那么它就超级守护进程。这种分类方法更倾向于在功能上对守护进程进行分类，是一个静态的概念。而根据运行方式的不同分成独立运行方式，与被管运行方式。

被超级进程所管理的守护进程称为被管守护进程。其执行的原理是，超级守护进程常驻内存，当有某个端口的连接操作的时候根据配置启动某个守护进程处理连接请求。超级守护进程特点是统一管理连接，而运行起来的速度比较慢，因为一次连接之后往往要求被管守护进程退出运行。

守护进程按照工作状态分为定时执行的守护进程，与信号守护进程。后者指服务被连接请求信号所触发。

守护进程所守护的不一定是网络，也可能是本地的某种服务，如打印服务。

在IP连接上，服务与端口号的对应在/etc/services中写出。每行`#`之后的内容作为注释，非注释行标明了对应关系，格式是：

    <ApplicationLayerProtocol> <port/TransmissionLayerProtocol> <introduction>

守护进程一般需要执行档案，配置文件，运行环境这些条件。

进程运行的PID在`/var/run`目录下保存。


开机脚本
---------------------------------------------

守护进程一般都不是手工进行控制而运行的吧。所以要学习开机脚本的原理。

开机脚本实际上是Shell文件，具有执行权限。标准的开机脚本都放在`/ete/init.d/`目录之下（不是子目录）。初始配置不在`/etc`目录下，而是在`/etc/sysconfig`当中。超级守护进程xinetd的配置文件位于`/etc/xinetd.conf`.而被xinetd所管理的进程连接配置放在`/etc/xinetd.d`目录之下。各自的配置文件在`/etc`目录之下。各个服务产生的数据会写在`/var/lib`的相应目录下面。各进程的PID记录在`/var/run`下的PID文件当中。

<!-- 所不理解的是，什么放在`/var/lib`下面，什么放在`/var/run`下面。-->

开机脚本以服务名作为脚本名。规定当什么参数都不加的时候，脚本文件返回所有可用的参数。一般参数会有start,stop,status,restart等。语义和单词意思相同。可以通过直接控制脚本管理服务进程。但是也可以通过service脚本统一进行管理。貌似优势就在于不用输入脚本文件所在的路径。

被超级守护进程所管的守护进程的配置主要在 `/etc/xinetd.d/*` 下进行，每一个文件代表一个服务。比如rsync守护过程就是由xinetd来管理的。配置文件作为一个小节出现。格式如下：

``` {.sourceCode .c}
service ${service_name}
{
${configurations}
}
```

其中每一个配置都是一个var=value的形式，之间可以有空格。全局配置文件在xinetd.conf当中，括号开头是defaults.

其中的等于号可以换成是+=,-=,分别表示加入新参数，减去新参数。

**注：** 如果既有在xinetd当中的配置，又有自己的配置该怎么办？


### xinetd的配置

以下是在/etc/xinetd.conf当中进行的配置。

xinetd当中也有`log_type`, `log_on_failure`, `log_on_success`.这些选项，不过记录的不是被管守护进程的运行日志，而是xinetd启动它的日志。

------------------------ -------------------------------------------------
cps = 50 10              在一秒内的最大联机数为50，若超过数量，暂停10秒
instances = 50           同一服务的最大同时联机数为50
per_source = 10          来自于同一来源的客户端的最大同时联机数为10
v6only = no              是否只是允许IPv6通过
includedir /etc/xinetd.d 详细的设置查这个目录。
-----------------------  -------------------------------------------------

以下是在具体某个服务当中的配置，当有同名的全局设定时，全局设定被覆盖，加上，或者减去。


* disable = yes | no  是否禁用服务
* id = 服务的标识名   一般与启动进程相同

有时候同一进程通过不同的参数可以提供不同类型的服务，所以有必要对启动的进程名加以修改。

* server = 服务所使用的守护进程
* server_args = 服务所使用的守护进程启动时的参数
* user = 服务启动时使用的UID,当xinetd是由root启动的时候，被管守护进程才能以其它身份启动

因为在linux如果xinetd是root,那么它所fork出来的子进程能够改变UID.

* group = 服务启动时使用的GID,也是当xinetd是由root启动时才有效

* `socket_type = stream | dgram | raw` 封包时所使用的机制，stream实际代表了TCP,而dgram代表了UDP,而raw代表server要直接与IP层交谈。

怎么在IP层直接交谈？

* `protocol = tcp | udp 和socket_type` 的意思相同，两者使用一个即可
* `wait = yes | no` 是xinetd连接的进程可以加载多个，还是同一时间内只加载一个

注意同一时间内的连接数和同一时间内主机上的进程数是不相同的。若处理很快，只加载一个进程，也可以建立多个连接。

* instances = 最大联机数
* per_source = 每IP的联机数与超过联机数的中断时间
* cps = 每服务联机数与超过联机数的中断时间
* log_type = 以下三个和全局设置中的含义相同，应用于这个进程
* log_on_success=
* log_on_failure=
* env = 系统额外的环境变量

看来每个服务都离不开进程与子进程啊。

* port = 所监听的端口，如果是公共服务，应当与services中的相同
* redirect = 当client对该服务有请求的时候，重定向到其它服务器

这个就相当于我说我有一个服务，但是别人用的时候，转交给其它的机器。

* includedir = 在xinetd中还要包括的子配置

注意新包括的配置将直接被加到xinetd.conf当中，而不会作为该服务的子配置。

* bind = 服务所绑定的IP地址，也就是当主机有多个IP的时候，可以通过哪个IP地址访问该服务

* interface = 与bind的含义相同
* only_from = 限定哪些网络可以连接。可以是IP/Mask,hostname,或域名
* no_access = 禁止来自些网络的连接
* access_times = 服务开放的时间段，格式HH:MM-HH:MM
* umask = 使用者的服务建立文件时使用的掩码


守护进程概述
-----------------------------------------------------------

在Linux下面没有什么持久运行的程序与一次运行的程序的区别。以前我们总是以为，开机启动的程序和作为守护进程运行的程序是不同的。其实它们的差别也并没有那么大。开机运行的程序如果不停止，那么就作为守护进程一直运行了。在Linux中，/etc/init.d里面是开机运行的程序，但是也可以用于启动守护进程与开机脚本。本质上，它们作为“服务”出现。反映的有start, stop, restart, status等语义即可。

开机创建虚拟网卡，其实同样是一种服务。这种服务在开机的时候运行，创建出网卡，在关机的时候停止服务。

``` {.sourceCode .shell}
USER="root"
TAP_NETWORK="192.168.0.1"
TAP_DEV_NUM=0
DESC="TAP config"

do_start() {
if [ ! -x /usr/sbin/tunctl ]; then
    echo "/usr/sbin/tunctl was NOT found"
    exit 1
fi
tunctl -t tap $TAP_DEV_NUM -u root
ifconfig tap $TAP_DEV_NUM ${TAP_NETWORK} netmask 255.255.255.0 promisc
ifconfig tap $TAP_DEV_NUM
}

do_stop() {
ifconfig tap $TAP_DEV_NUM down
}

do_restart() {
do_stop
do_start
}

check_status() {
ifconfig tap $TAP_DEV_NUM
}

case $1 in
start) do_start ;;
stop) do_stop;;
restart) do_restart;;
status)
    echo "Status of $DESC:"
    check_status
    exit "$?"
    ;;
*) 
    echo "Usage: $0 {start | stop | restart | status}"
    exit 1
esac
```

上面就是一个符合chkconfig规范的启动脚本。

实际中我们可能把创建网桥的工作交给开机脚本，而把配置虚拟接口的网络地址这样的任务交给network子程序。

然后使用

``` {.sourceCode .bash}
chkconfig --add config_tap
chkconfig --level 345 config_tap on
```

让它启动。在Debian系的系统上，使用service命令完成这样的工作。

对于个人用户来说，登录的时候运行某一个程序才是恰当的。因此用户登入之后才需要相应的环境。
