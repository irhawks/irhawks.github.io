---
title : 命令行下面的关机，PXE远程启动
date  : 2014-09-20
tags  : PXE, halt, 远程启动, PXELINUX
---

下午针对这个问题google了一下，原因大概就是 halt 是强制关机，而poweroff 会先给 ACPI （Advanced Configuration and Power Management Interface）一个命令，之后再关机（不知道这么理解是不是准确，逃）。感觉是我直接用 halt 才出的问题。继而观察了下这三个命令，

shutdown实际上是调用init 0, init 0会cleanup一些工作然后调用halt或者poweroff。其实主要区别是halt和poweroff，做没有acpi的系统上，halt只是关闭了os，电源还在工作，你得手动取按一下那个按钮，而poweroff会发送一个关闭电源的信号给acpi。但在现在的系统上，他们实际上都一样了

可以参考juju-charm上面的关于maas的区域控制器的介绍。上面用图表的形式列出了区域控制器所依赖的psql、sstream等组件。

远程启动
-----------------------------------------------------------------------

不同计算机支持的远程启动协议是各种各样的，在Intel的机器上，使用的是所谓的PXE(Preboot Execution Enviroment)技术。PXE协议是根据服务器端收到的工作站的MAC地址，使用DHCP服务给这个MAC地址指定一个IP。在PXE中，待启动的机器常称为工作站。PXE工作的大致过程是，工作站开机后，PXE BootROM(网卡上的自启芯片)获得控制权之前先做自我测试，然后以广播形式发出一个请求FIND帧。服务器若收到工作站的要求，就会发出DHCP回应。内容包括用户端的IP地址、预设通讯通道、开机映象文件等。工作站收到后回应相应的帧请求传送所需文件。之后将会有多次协商过程，以决定启动参数。之后BootROM由TFTP通讯协议从服务器下载开机映象文件。这个映象档就是软盘映象文件（系统映象文件）。工作站使用TFTP接收启动文件后，将控制权转交启动块，引导操作系统映象，完成自启动过程。

配置过程中，针对DHCP、TFTP、NFS进行相应的配置。DHCP用于将引导模块交给工作站，TFTP用于传送操作系统映象，而NFS用于加载开机启动时所需的各个文件。

TFTP的配置可由xinetd决定。而DHCP中的一些选项是与TFTP启动配合的。所以在正常配置好DHCP服务器之后，由next-server选项指定TFTP服务器的地址，由filename选项指定TFTP服务器文件的路径。这是因为，根据DHCP协议的规范，next-server就是TFTP服务器的地址。

``` {.sourceCode .c}
## 目标机器的DHCP配置项
host target {
## 目标机器所匹配的MAC地址
hardware ethernet 00:13:21:1F:F1:82;
## 目标机器分配到的IP地址
fixed-address 192.168.0.10;
## 目标机器所使用的网关地址
option routers 192.168.0.254;
## 目标机器所用的DNS
option domain-name-servers 208.67.222.222,208.67.220.220;
## 指定TFTP服务器的地址。如果TFTP与DHCP服务器是一个IP，则可以忽略
next-server 192.168.0.2;
## 指定开机文档在TFTP服务器上的路径
filename "/ubuntu-installer/i386/pxelinux.0";
}
```

然后可以开启TFTP服务，并且操作系统映象也可以放在TFTP服务器上。对于Ubuntu来说，可以将光盘中的/install/netboot/ubuntu-installer/目录复制到TFTP目录下面。之后，打开客户机的电源，BIOS中选择从网络启动即可。

上面的DHCP配置中仅有被启动的工作站的配置节，而正常的DHCP应当有针对子网的配置。dhcpd.conf文件的其他部分可参考示例文件：

``` {.sourceCode .c}
ddns-update-style none;
ignore client-updates;
allow booting;
allow bootp;

subnet 192.168.5.0 netmask 255.255.255.0 {
option routers 192.168.5.1;
option subnet-mask 255.255.255.0;
option domain-name-servers 202.112.128.50;
range dynamic-bootp 192.168.5.33 192.168.5.38;
default-lease-time 21600;
max-lease-time 43200;
}
```

我们知道，本地启动的时候，有GRUB和LINUX系统映象两个文件。前面的pxelinux.0就相当于GRUB、整个光盘就相当于开机系统。linux发行版光盘的`install/netboot`目录中有pxelinux.0文件及相应的配置选项，使用的时候，该文件夹的内容全部拷贝到TFTP根目录下面。

Ubuntu一系的软件，光盘映象基本上都放在HTTP服务器上。也就是操作系统映象自TFTP传到工作站并运行的时候，Ubuntu自动从本网络的一台HTTP服务器上查找安装所需文档。此时，我们可以选择将整个光盘映象挂载至HTTP服务器的 `/ubuntu`目录下面。工作站的PXELINUX启动的时候，会向我们询问操作系统映象的地址。

如果合适，我们也可以将安装好的系统分发给其它的工作站，而不用远程安装系统。

实战
----

首先安装Ubuntu上所需要的各种软件，然后将Ubuntu14.04的映象下载过来。

``` {.sourceCode .bash}
apt-get install nfs-common nfs-kernel-server
apt-get install tftpd-hpa tftp-hpa
apt-get install isc-dhcp-server
```

DHCP服务的端口号是TCP67，而TFTP服务的端口号是UDP59，可以通过netstat命令查看相关的设置。

tftp-hpa使用的配置文件是 `/etc/default/tftpd-hpa` ，可以根据需要，将TFTP的服务器目录改变到其它的位置。不过，配置的时候，注意权限问题。

isc-dhcp-server使用的配置文件是 `/etc/dhcp/dhcpd.conf` 。配置的时候按照格式。

配置DHCP的时候，应将这里的DHCP与服务器上的DHCP区分开。一般而言，笔记本在连接无线的时候，有线网络并不受到影响。这个时候我们可以指定本机的地址，然后在dhcpd.conf文件中，将网关的位置填写成自己的。其实，如果是局域网里面访问，则根本不需要网关地址。因为局域网中的主机访问，不需要通过网关。

NFS服务是可选的。如果需要使用这个服务的话，使用NFS的时候，别忘了安装nfs-kernel-server。然后编辑 `/etc/exports` 文件，选择需要导出的数据。

然而在共享的时候，NFS需要用户的密码。这一点需要我们注意。没有`/etc/exports`里面的文件的时候，导出的目录是空的，NFSD守护进程也不会运行。简单的导出可
以是 `/srv/www *(ro)` 这样的行。

PXELINUX介绍
------------

其实使用TFTP服务全部依赖于所谓的PXELINUX启动程序。该程序与SYSLINUX、EXTLINUX同属于一个发行版。PXELINUX的pxelinux.0文件所在的TFTP的根目录，其实就相当于本地启动的时候的boot分区而已。

下载PXELINUX程序之后，将 `/usr/lib/syslinux/pxelinux.0` 文件复制在TFTP根目录下面。然后在TFTP根目录下建立pxelinux.cfg目录。在目录中建立default文件。其实，PXELINUX的解释是， `pxelinux.cfg`目录代表了对不同的客户机的启动选项的配置，以便支持不同的系统。而只有一个`default`文件的时候，相当于局域网中只有一个主机。

下面是PXELINUX的配置文件的一个示例写法：

``` {.sourceCode .shell}
DEFAULT ubuntu
LABEL ubuntu
kernel linux
append initrd=initrd.nfs root=/dev/nfs nfsroot=192.168.1.88:/home/cache/netboot/root ip=dhcp rw
```

kernel与append命令所需的linux与initrd文件，都是以TFTP根目录为根所得到的文件路径。因此内核linux与initrd文件要与pxelinux.0一起放在TFTP根目录下。

任何linux内核均支持root=这样的参数，大部分也支持nfsroot选项。如果把nfsroot都指定了，那么工作站将以nfsroot所指的位置作为根系统。然后，找到根系统后，我们就可以从根文件系统的 `/etc/fstab`中加载其它的NFS挂载选项。通过不同的组合，可以实现无盘工作站或者有盘工作站。

如果理解了内核的root=选项，以及联想到OpenSUSE安装光盘具有指定光盘位置的选项，那么远程安装系统就不是什么困难的事情了。

对于Ubuntu来说，不同之处在于，Ubuntu的安装映象支持ks=选项，而ks=又可以调用http服务，因此Ubuntu具有从HTTP服务器上下载文件的能力。显然，如果工作站能够下载服务器上的安装映象，那么自然就能够完成接下来的安装。

网络唤醒功能
------------

网络唤醒功能一个是网卡支持，第二个是BIOS启用，另外一个是有应用工具。网卡的支持是生产商的问题。BIOS中启用与否，可以在机器BIOS中启用，应用工具则是运行在具体操作系统下面的。

linux的ethtool工具可以用于修改网卡上WOL的状态，决定从网络唤醒是否启用。使用 `ethtool -s eth0 wol g` 就可以启用网卡的网络唤醒功能。 `wol d`表示禁用。

linux的 `wakeonlan`工具是唤醒网卡的终端。它接受MAC地址作为参数，唤醒局域网中具有此MAC的机器。

完成PXE启动的时候，导出NFSROOT目录，配置为

``` {.sourceCode .c}
/etc/exports: the access control list for filesystems which may be exported
    to NFS clients.  See exports(5).

Example for NFSv2 and NFSv3:
/srv/homes       hostname1(rw,sync,no_subtree_check) hostname2(ro,sync,no_subtree_check)

Example for NFSv4:
/srv/nfs4        gss/krb5i(rw,sync,fsid=0,crossmnt,no_subtree_check)
/srv/nfs4/homes  gss/krb5i(rw,sync,no_subtree_check)

/srv/www    *(ro)
/srv/tftpboot/ *(no_subtree_check,rw,no_root_squash,async)
```

然后在启动文件 `pxelinux.cfg/default` 中配置启动选项为:

``` {.sourceCode .shell}
# D-I config version 2.0
prompt 0
timeout 100

DEFAULT ubuntu
LABEL ubuntu
KERNEL ../ubuntu/casper/vmlinuz.efi
APPEND initrd=../ubuntu/casper/initrd.lz boot=casper netboot=nfs root=/dev/nfs nfsroot=10.10.10.1:/srv/tftpboot/ubuntu ip=dhcp
```

其中 `/srv/tftpboot/ubuntu` 相当于光盘的根目录，里面有linux安装光盘里面的所有的文件。这种方式只需要NFS就可以，不用HTTP服务，因此是一种比较好的解决的办法。

剩下的就是 `wakonlan` 的测试了。这也应该是不成为问题的。只需要将网卡配置好就可以了。
