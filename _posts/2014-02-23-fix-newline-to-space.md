---
layout: post
title: Fix Newline to Space
description: "jekyll converts newline to space, it's not good for chinese."
modified: 2014-02-22
tags: [jekyll]
image:
  feature: abstract-2.jpg
comments: true
share: true
---

之前，[RandomK](http://randomk.gitcafe.com/)说我的blog有bug，其实在他说之前我就已经知道了，只是当时比较晚，所以没有修，今天周末将其解决之。

## 原因

我使用的是redcarpet作为markdown的转换器，jekyll将多行的段落转换成html之后在浏览
器中显示会很奇怪，在原始的markdown中的某一行最后一个字与下一行的第一个字之间存
在一个空格，作为使用单词的外国淫来说没什么问题，可是作为大天朝子民是无法忍受的。
<figure>
<img data-echo="{{ site.url }}/images/fix-space/space.png" alt="space" title="space">
<figcaption>文字之间存在空格</figcaption>
</figure>


## 解决方案一 段落写为一行

我只能说这种行为好痛苦。


## 解决方案二 在markdown转换为html前处理一下

由于无法忍受第一种解决方案，只能在markdown转换为html之前进行一些预处理了。在网
上搜索一番后发现果然不止我一人遇到此问题，并且找到了一个[解决方案][solution]。
不过该解决方案有一定的局限性，第一，没有处理汉英和英汉这两种情况，第二，没有处
理摘要。

为了解决以上两个问题，必须做出一些更改。

首先，作为一个非octopress用户，果断得去github上将octopress的[post\_filters plugins][post_filters]得到，
然后，从[解决 Markdown 转 HTML 中文换行变空格的问题][solution]将代码拷贝并保存
到存放plugins的目录。然后就可以开始修改了。

修改1:

```ruby
class String
  han = '\p{Han}|[，。？；：‘’“”、！……（）]'
  @@hh = /(#{han}) *\n *(#{han})/m
  @@he = /(#{han}) *\n *(\p{Alpha})/m
  @@eh = /(\p{Alpha}) *\n *(#{han})/m
  def join_chinese!
    gsub!(@@hh, '\1\2')
    gsub!(@@he, '\1\2')
    gsub!(@@eh, '\1\2')
    self
  end
end
```

经过修改后，blog就能够正常显示了。
<figure class="half">
<img data-echo="{{ site.url }}/images/fix-space/space.png" alt="space" title="space">
<img data-echo="{{ site.url }}/images/fix-space/no-space.png" alt="no-space" title="no space">
    <figcaption>第一阶段成果</figcaption>
</figure>

修改2:
虽然blog中的问题解决了，但是摘要部分并没有的到解决。
<figure>
<img data-echo="{{ site.url }}/images/fix-space/wrong-excerpt.png" alt="wrong-excerpt" title="wrong-excerpt">
    <figcaption>摘要中显示错误</figcaption>
</figure>
由于在pre\_render中添加`{%raw%}post.excerpt.join_chinese!{%endraw%}`会导致jekyll创建html时失败，
因此采用添加一个filter供Liquid使用，从而解决解决此问题。

将一下代码加入Jekyll模块中

```ruby
  module TemplateJoinChineseFilter
    def join_chinese(input)
      input.join_chinese!
    end
  end
```
然后将`Liquid::Template.register_filter(Jekyll::TemplateJoinChineseFilter)`添加到最后一行。
最后，只需要在使用摘要的时候使用`{%raw%}{{ page.excerpt | join_chinese }}{% endraw %}`替代`{% raw %}{{ page.excerpt }}{% endraw %}`即可。
<figure class='half'>
<img data-echo="{{ site.url }}/images/fix-space/wrong-excerpt.png" alt="wrong-excerpt" title="wrong-excerpt">
<img data-echo="{{ site.url }}/images/fix-space/excerpt.png" alt="excerpt" title="excerpt">
<figcaption>摘要中空格也不存在了</figcaption>
</figure>


# The End

问题基本得到了解决，不过还有几点需要注意：

1. markdown中标题与正文之间需要一行空白行（我不习惯）。
2. 标点符号和数字没有处理，因此有些地方是不适合换行然后通过插件解决的。
3. 应该还存在这一些bug。


## Reference

1. [解决 Markdown 转 HTML 中文换行变空格的问题][solution]。
2. [post\_filter][post_filters]。


[solution]: http://chenyufei.info/blog/2011-12-23/fix-chinese-newline-becomes-space-in-browser-problem/
[post_filters]: https://github.com/imathis/octopress/blob/master/plugins/post_filters.rb
