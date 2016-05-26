CABAL=cabal
SITE_GEN_PROG=./dist/build/blog/blog

### 首先使用cabal安装blog程序，然后使用blog程序生成网站

default : preview
    
${SITE_GEN_PROG} : blog.cabal
	cabal build

rebuild: ${SITE_GEN_PROG}
	${SITE_GEN_PROG} rebuild

clean: ${SITE_GEN_PROG}
	${SITE_GEN_PROG} clean

preview: rebuild
	${SITE_GEN_PROG} watch -h "0.0.0.0:8000"

### 接下来我们想使用github来作为部署的平台，部署到irhawks.github.io
### 包括部署源代码与部署网站
### 将主目录中的remote设置为
### 	(github) git@github.com:irhawks/irhawks.github.io.git
### 	(aliyun) git@code.aliyun.com:irhawks/homepage-my.git

deploy-source-aliyun : rebuild

	git checkout source
	git add -A
	git commit -am "更新博客源文件 $$(date)"
	git push aliyun master --tags

deploy-source-github : rebuild

	git checkout source
	git add -A
	git commit -am "更新博客源文件 $$(date)"
	git push github master
