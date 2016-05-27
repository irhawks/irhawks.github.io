These are the files necessary to produce my personal [blog](http://www.austinrochford.com) using [Hakyll](http://jaspervdj.be/hakyll/), a static site generator written in Haskell.

To use, install its dependencies with

```bash
cabal install --only-dependencies
```

Be prepared for it the dependencies to take a while to build, depending on if you are using a sandbox or how many of the necessary packages are already installed.  Then build the package using

```bash
cabal build
```

You can then examine the Makefile to see how to generate the site (`make rebuild`) and to run a local preview server (`make preview`).

The executable will look in the `posts/` folder for posts (quelle suprise!).  Each post should be named `YYYY-MM-DD-short-title-for-url.mkd`.  Consult the Hakyll [tutorials](http://jaspervdj.be/hakyll/tutorials.html) for more informations on how to format posts to contain the correct metadata.

By default, the site is deployed using `rsync`.  To modify the desintation, change the value of `LIVE_URI` in the Makefile.

This code is distributed under the [MIT License](http://opensource.org/licenses/MIT).


## 注意事项

注意，修改site.hs需要重新编译cabal。


在克隆回来之后需要添加remote如下：　

```shell
git remote add aliyun git@code.aliyun.com:irhawks/blogpage.git
git remote add github git@github.com:irhawks/irhawks.github.io.git
```


静态网站的动态功能
---------------------------------------------------------

这句话现在有两种意思。第一种意思是静态网站像动态网站那样有明确的数据层。只不过，这些数据是在构建网站的时候生成的，比如yst的向yaml文件中查询最近的消息。另一种意思就是具有动态变化的功能。比如使用百度统计、Disqus评论系统，或者像Openswift这样的搜索功能。添加这些功能，对于网站的交互性有好处。


网站使用说明
---------------------------------------------------------

网站使用hakyll来构建，本文档前面就是构建说明。

appendix目录
~ [原作者](http://austinrochford.com/)的博客部署模板（Vagrant文件）

posts目录
~ 存放有博客的markdown文件

static目录
~ 网站静态文件，原样复制，包括css等各种资源文件

templates目录：网站模板，用于指导从Markdown生成HTML

Makefile目录
~ 自动化部署脚本


