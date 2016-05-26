CABAL=cabal
SITE_GEN_PROG=./dist/build/blog/blog

### 首先使用cabal安装blog程序，然后使用blog程序生成网站

default : preview
    
${SITE_GEN_PROG} : blog.cabal
	cabal build

rebuild: ${SITE_GEN_PROG}
	${SITE_GEN_PROG} rebuild

### you should never clean the _site directory
clean: ${SITE_GEN_PROG}
	${SITE_GEN_PROG} clean

preview: rebuild
	${SITE_GEN_PROG} watch -h "0.0.0.0"

### 接下来我们想使用github来作为部署的平台，部署到irhawks.github.io
### 包括部署源代码与部署网站
### 将主目录中的remote设置为
### 	(github) git@github.com:irhawks/irhawks.github.io.git
### 	(aliyun) git@code.aliyun.com:irhawks/homepage-my.git

commit-source-target :

	make commit-source
	make deploy-target-github

commit-source : 
	
	make auto-commit
	make deploy-source-aliyun
	make deploy-source-github

auto-commit : 

	git add -A
	git commit -am "更新博客源文件 $$(date)"

deploy-source-aliyun : ${SITE_GEN_PROG}
	
	ping -c 2 code.aliyun.com
	git push aliyun master --tags

deploy-source-github : ${SITE_GEN_PROG}

	ping -c 2 github.com
	git push github master:source --tags

deploy-target-github : rebuild

	### 现在_site目录是指向github.io.git上面的一个master分支的子模块
	ping -c 2 github.com
	### 问题是每次rebuild的时候，hakyll都会清空_site目录，所以每次都要init
	git submodule init && git submodule update
	cd _site && git add -A
	cd _site && git commit -am "更新github上面的博客 $$(date)"
	cd _site && git branch detached
	cd _site && git merge detached
	cd _site && git branch -d detached
	cd _site && git push -f origin master   ## 强制推送到github的master
