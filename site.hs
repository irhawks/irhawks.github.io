{-# LANGUAGE OverloadedStrings #-}

import Control.Applicative ((<$>))
import Data.Monoid
import qualified Data.Set as Set
import Text.Pandoc.Options
import Hakyll

main :: IO ()
main = hakyll $ do
    match "static/css/**" $ route staticRoute >> compile compressCssCompiler

    match "static/favicon.ico" $ route staticRoute >> compile copyFileCompiler

    -- 单独列出一个图片目录
    match "static/img/**" $ route staticRoute >> compile copyFileCompiler   


    -- 用于百度站长工具的一些文件，比如robots.txt、站点管理验证等。
    -- 第一个是robots.txt
    -- 第二个是百度站点管理工具验证（用于验证github）
    match "static/robots.txt" $ route staticRoute >> compile copyFileCompiler
    match "static/baidu_verify_hGcluqdQRU.html" $ route staticRoute >> compile copyFileCompiler
    -- 百度站点管理工具验证（用于验证irhawks.coding.me）
    match "static/baidu_verify_vjCtJE2mnq.html" $ route staticRoute >> compile copyFileCompiler

    match "static/*.mkd" staticMarkdownRule

    match "resources/**" $ route idRoute >> compile copyFileCompiler

    tags <- buildTags "posts/**" $ fromCapture "tags/*.html"

    match "posts/**" $ do
        route $ setExtension "html"
        compile $ pandocCompiler'
            >>= loadAndApplyTemplate "templates/post.html" (taggedPostCtx tags)
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    create ["posts.html"] $ do
        route idRoute
        compile $ do
            let archiveCtx =
                    field "posts" (const $ postList recentFirst)    `mappend`
                    constField "title" "文章列表"                  `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/posts.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls

    tagsRules tags $ \tag pattern -> do
        let tagCtx = constField "title" ("具有“" ++ tag ++ "”的文章") `mappend` defaultContext

        route idRoute
        compile $ postsTagged tags pattern recentFirst
            >>= makeItem
            >>= loadAndApplyTemplate "templates/tag.html" tagCtx
            >>= loadAndApplyTemplate "templates/default.html" tagCtx
            >>= relativizeUrls

    create ["tags.html"] $ do
        route idRoute
        compile $ do
            let cloudCtx = constField "title" "标签云" `mappend` defaultContext

            renderTagCloud 100 300 tags
                >>= makeItem
                >>= loadAndApplyTemplate "templates/cloud.html" cloudCtx
                >>= loadAndApplyTemplate "templates/default.html" cloudCtx
                >>= relativizeUrls

    match "index.html" $ do
        route idRoute
        compile $ do
            let indexCtx = field "post" $ const (itemBody <$> mostRecentPost)
            -- let homeCtx = constField "title" "主页" `mappend` defaultContext
            let homeCtx = constField "title" "最新文章" `mappend` defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" homeCtx
                >>= relativizeUrls

    create ["rss.xml"] $ do
        route idRoute
        compile $ do
            let feedCtx = postCtx `mappend` bodyField "description"

            posts <- take 10 <$> (recentFirst =<< loadAllSnapshots "posts/*" "content")
            renderRss feedConfig feedCtx posts

    match "templates/*" $ compile templateCompiler

    create ["sitemap.xml"] $ do
           route   idRoute
           compile $ do
             posts <- recentFirst =<< loadAll "posts/*"
             let allPosts = (return posts)
             let sitemapCtx = mconcat
                              [ listField "entries" pageCtx allPosts
                              , constField "host" host
                              , defaultContext
                              ]
             makeItem ""
              >>= loadAndApplyTemplate "templates/sitemap.xml" sitemapCtx
              >>= cleanIndexHtmls




--    create ["sitemap.xml"] $ do
--        route   idRoute
--        compile $ do
--          posts <- recentFirst =<< loadAll "posts/*/*"
--          pages <- loadAll "pages/*"
--          let allPosts = (return (pages ++ posts))
--          let sitemapCtx = mconcat
--                           [ listField "entries" postCtx allPosts
--                           , constField "host" "irhawks.coding.me"
--                           , defaultContext
--                           ]
--          makeItem ""
--           >>= loadAndApplyTemplate "templates/sitemap.xml" sitemapCtx
--           >>= cleanIndexHtmls

extensions :: Set.Set Extension
extensions = Set.fromList [Ext_inline_notes, Ext_raw_html, Ext_tex_math_dollars]

feedConfig :: FeedConfiguration
feedConfig = FeedConfiguration {
        feedTitle       = "irhawks.github.io",
        feedDescription = "IRI's blog on irhawks.github.io",
        feedAuthorName  = "irhawks",
        feedAuthorEmail = "2927670573@qq.com",
        feedRoot        = "http://irhawks.github.io"
    }

mostRecentPost :: Compiler (Item String)
mostRecentPost = head <$> (recentFirst =<< loadAllSnapshots "posts/*" "content")

pandocCompiler' :: Compiler (Item String)
pandocCompiler' = pandocCompilerWith pandocMathReaderOptions pandocMathWriterOptions

pandocMathReaderOptions :: ReaderOptions
pandocMathReaderOptions = defaultHakyllReaderOptions {
        readerExtensions = Set.union (readerExtensions defaultHakyllReaderOptions) extensions
    }

pandocMathWriterOptions :: WriterOptions
pandocMathWriterOptions  = defaultHakyllWriterOptions {
        writerExtensions = Set.union (writerExtensions defaultHakyllWriterOptions) extensions,
        writerHTMLMathMethod = MathJax ""
}

postCtx :: Context String
postCtx = dateField "date" "%B %e, %Y" `mappend` defaultContext

postList :: ([Item String] -> Compiler [Item String]) -> Compiler String
postList sortFilter = do
    posts   <- sortFilter =<< loadAll "posts/*"
    itemTpl <- loadBody "templates/post-item.html"
    applyTemplateList itemTpl postCtx posts

postsTagged :: Tags -> Pattern -> ([Item String] -> Compiler [Item String]) -> Compiler String
postsTagged tags pattern sortFilter = do
    template <- loadBody "templates/post-item.html"
    posts <- sortFilter =<< loadAll pattern
    applyTemplateList template postCtx posts

staticMarkdownRule :: Rules ()
staticMarkdownRule = do
    route $ staticRoute `composeRoutes` setExtension "html"
    compile $ pandocCompiler'
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

staticRoute :: Routes
staticRoute = gsubRoute "static/" (const "")

taggedPostCtx :: Tags -> Context String
taggedPostCtx tags = tagsField "tags" tags `mappend` postCtx


------------------------------------------------------------------
-- to generate sitemap.xml

myCtx :: Context String
myCtx = mconcat
  [ constField "superTitle" "80x24的转化器"
  , defaultContext
  ]

host :: String
host = "http://irhawks.coding.me"

pageCtx :: Context String
pageCtx = mconcat
    [ modificationTimeField "date" "%Y-%m-%d"
    , constField "host" "irhawks.coding.me"
    , myCtx
    ]

cleanIndexHtmls :: Item String -> Compiler (Item String)
cleanIndexHtmls = return . fmap (replaceAll pattern replacement)
    where
      pattern = "/index.html"
      replacement = const "/"
