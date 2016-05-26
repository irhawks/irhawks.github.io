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
git remote add aliyun git@code.aliyun.com:irhawks/homepage-my.git
git remote add github git@github.com:irhawks/irhawks.github.io.git
```


