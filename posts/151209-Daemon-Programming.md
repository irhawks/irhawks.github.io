---
title : 守护进程的编写思路（C与Python）
date  : 2015-12-09
tags  : daemon, linux, c, python, server
author : irhawks
---

参考<http://www.netzmafia.de/skripten/unix/linux-daemon-howto.html>。上面提到Linux守护进程应该做的基本的事情，守护进程主要包括了

* 从主程序中创建子进程
* 改变文件的umask任务
* 打开日志文件以记录日志
* 创建会话ID
* 将工作目录移动到一个安全的位置
* 关闭标准的文件描述符（守护进程不存在标准输入与输出的问题）

显然这是针对具体情况的需求建模的一部分。因为守护进程总是从系统中由一个脚本调用或者用户手动启动的。在启动的时候，守护进程和系统中其它的进程一样被对待。但是守护进程的目标要使得它能够独立于会话而存在。具体代码的执行还是由子进程完成的。在Linux当中，这是通过fork函数完成的。在守护进程的编写中，很大一部分代码全部是处理控制流的，特别是异常处理，这没有什么可问的：事实就是如此，我们也不得不面对。当然要接受这样的现实并写出大量异常处理的代码。编程的最本质的困难可能还是在于对于控制流的掌握把，至于具体的算法则是理论上的另外一方面的问题了。

进程成功创建子进程之后，父进程应该及时终止退出，然后由子进程执行任务。显然，这个时候子进程是沿着父进程的当前控制流继续执行的。接下来就是子进程的任务。


改变文件的掩码
--------------------------------------------

为了能够写入由daemon所创建的文件，必须保持daemon在创建这些文件的时候有写入的权限。该权限是由umask来控制的，可以保证它们可以正确地读取或写入文件。umask可以在命令行当中运行，但是保险的方法还是通过编程接口。在linux系统中完成切换umask任务的是umask函数。设置umask为0可以对文件有完全的访问权限。

第三步是打开日志。但是该步骤是可选的。该可选的步骤可以导出许多有用的信息。

第四步是创建SID结构。目的是让这个进程的父进程去掉，成为一个orphan进程，以便不受到用户会话的影响。方法是创建一个SID。使用setsid函数。

```c
pid_t pid, sid;
/* Fork off the parent process */
pid = fork()
if(pid < 0) { exit(EXIT_FAILURE); }  // fork process failed
if(pid > 0) { exit(EXIT_SUCCESS); }  // succeed and exit parent process

/* Change the file mode mask */
umask(0)

/* Open any logs here */

/* Create a new SID for the child process */
sid = setsid();
if (sid < 0) { exit(FAILURE); }  // don't forget to enable your log 
```

再一步是改变工作的目录。我们必须保证该目录存在。在按照FHS标准的系统中可以是/tmp的目录，但是保险的方法还是使用根目录作为当前的工作目录。使用chdir函数可以完成这样的任务。

```c
if ( (chdir("/")) < 0 ) { exit(EXIT_FAILURE); } // 失败返回-1
```

关闭标准文件描述符是最后的一步。这是因为守护进程根本就没有标准输入输出可以使用。使用的是close函数。如下：

```c
close(STDIN_FILENO);
close(STDOUT_FILENO);
close(STDERR_FILENO);
```


### 守护进程的执行逻辑

经过之上的步骤，终于算是符合了daemon的行为规范。接下来就需要写一系列的具体完成daemon的代码了。初始化守护进程中其中的第一步。常见的逻辑是：

```c
/* Daemon-specific initialization goes here */

/* The big loop */
while(1) { 
    /* Do your task here */
    sleep(30);
}
```

也就是说，这个时候守护进程是一个循环的程序。

注意，日志一般应使用syslog的系统，使用syslog提供的机制。


使用Python写Linux的守护进程
------------------------------------------------------------------

现在更多地是使用脚本语言和面向对象的技术来完成基本任务的编写。所以接下来我们选择一个使用Python来写守护进程的一个脚本。参考<http://blog.csdn.net/LikeHighTime/article/details/4602456}。原贴<http://www.jejik.com/articles/2007/02/a_simple_unix_linux_daemon_in_python/>。

其头部的关键是使用signal的库导入一些信号，并使用一些系统的头文件。之后则是创建一个Daemon的类。在该类中的初始化函数，daemonize化函数支撑函数的运行。

我们先来看Daemon的原型，用户的守护进程是从这个类继承过来的。

守护进程类原型有如下的几个重要的例子：

init函数：该函数表示的是进入守护进程的时候的初始的设置。如下：

```python
  def __init__(self, pidfile, stdin='/dev/null', stdout='/dev/null', stderr='/dev/null'):  
        self.stdin = stdin  
        self.stdout = stdout  
        self.stderr = stderr  
        self.pidfile = pidfile  
```

daemonize函数，该函数用于执行UNIX的所谓的double-fork方法。该方法可见Stevens' "Advanced  Programming in the UNIX Environment" for details (ISBN 0201563177) <http://www.erlenstar.demon.co.uk/unix/faq_2.html#SEC16>。

```python
def daemonize(self):
    try:   
        pid = os.fork()   
        if pid > 0:  
            # exit first parent  
            sys.exit(0)   
    except OSError, e:   
        sys.stderr.write("fork #1 failed: %d (%s)/n" % (e.errno, e.strerror))  
        sys.exit(1)  
  
    # decouple from parent environment  
    os.chdir("/")   
    os.setsid()   
    os.umask(0)   

    # do second fork  
    try:   
        pid = os.fork()   
        if pid > 0:  
            # exit from second parent  
            sys.exit(0)   
    except OSError, e:   
        sys.stderr.write("fork #2 failed: %d (%s)/n" % (e.errno, e.strerror))  
        sys.exit(1)   
  
    # redirect standard file descriptors  
    sys.stdout.flush()  
    sys.stderr.flush()  
    si = file(self.stdin, 'r')  
    so = file(self.stdout, 'a+')  
    se = file(self.stderr, 'a+', 0)  
    os.dup2(si.fileno(), sys.stdin.fileno())  
    os.dup2(so.fileno(), sys.stdout.fileno())  
    os.dup2(se.fileno(), sys.stderr.fileno())  
  
    # write pidfile  
    atexit.register(self.delpid)  
    pid = str(os.getpid())  
    file(self.pidfile,'w+').write("%s/n" % pid)  
```

该方法完成的就是之前的C语言的大部分的内容了。

之后是管理PID文件

```python
def delpid(self):  
    os.remove(self.pidfile)  
```

开始进程函数start完成开启进程，让进程运行的任务。该函数检查相应的PID文件是否存在，存在表示进程已经在运行，所以就退出

```python
def start(self):  
    """ 
    Start the daemon 
    """  
    # Check for a pidfile to see if the daemon already runs  
    try:  
        pf = file(self.pidfile,'r')  
        pid = int(pf.read().strip())  
        pf.close()  
    except IOError:  
        pid = None  
  
    if pid:  
        message = "pidfile %s already exist. Daemon already running?/n"  
        sys.stderr.write(message % self.pidfile)  
        sys.exit(1)  
      
    # Start the daemon  
    self.daemonize()  
    self.run()  
```

停止函数是这样的：

```python
def stop(self):  
    """ 
    Stop the daemon 
    """  
    # Get the pid from the pidfile  
    try:  
        pf = file(self.pidfile,'r')  
        pid = int(pf.read().strip())  
        pf.close()  
    except IOError:  
        pid = None  
  
    if not pid:  
        message = "pidfile %s does not exist. Daemon not running?/n"  
        sys.stderr.write(message % self.pidfile)  
        return # not an error in a restart  
    # Try killing the daemon process      
    try:  
        while 1:  
            os.kill(pid, SIGTERM)  
            time.sleep(0.1)  
    except OSError, err:  
        err = str(err)  
        if err.find("No such process") > 0:  
            if os.path.exists(self.pidfile):  
                os.remove(self.pidfile)  
        else:  
            print str(err)  
            sys.exit(1)  
```

接下来可以类似地定义restart与run函数。在写用户自己的进程的时候，用户需要手动写自己的run函数。重载之后就可以了。注意守护进程是有自己的特定的PID文件的。一般是放在/tmp目录。但是也有一些系统进程。至于在运行的时候切换到其它的进程，则可以通过一些库来完成。
