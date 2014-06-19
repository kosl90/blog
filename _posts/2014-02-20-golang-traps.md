---
layout: post
title: Golang Traps
description: "record golang's traps"
modified: 2014-02-22
tags: [golang, go]
image:
  feature: abstract-3.jpg
  credit: dargadgetz
  creditlink: http://www.dargadgetz.com/ios-7-abstract-wallpaper-pack-for-iphone-5-and-ipod-touch-retina/
comments: true
share: true
---

这段时间，在公司项目中使用了golang，感觉golang的确有他独到的地方，尤其是
goroutine和channel使事情变的简单。可是作为一门新的语言golang仍然会有不少的问题
，例如没有检测文件是否存在的函数，没有拷贝文件的函数等等，诸如此类，除了这类问
题以外还存在一些与直觉有所不同的问题，此篇博客将会持续记录在使用golang的过程中
遇到的一些问题。


## 没有检测文件是否存在的函数

这个问题是我无意中在某项目中看到解决方案时发现的，解决方案也比较简单。

{% highlight go %}
func Exist(path string) {
    _, err := os.Stat(path)
    return err == nil || os.IsExist(err)
}
{% endhighlight %}


## 没有拷贝文件的函数

关于这一点，在github上有一个[项目](https://github.com/daaku/go.copyfile)可以一
定程度上的解决这个问题，不过这个项目还有待完善，而且我个人使用方法感觉很不习惯
，还是习惯以设置flag参数的形式来使用。


## filepath.Walk

这个问题是今天遇到的，当我天真的以为对一个不存在的路径进行Walk的时候，此函数什
么也不会做，然后像其他函数一样返回错误给我的时候，可结果却是该函数仍然会调用回
调函数。我之前还在纳闷第三个参数有什么用，好吧，今天发现你的文档的确是说了，
**所有**错误都在回调函数中处理，这是我的错。

{% highlight go %}
package main
import (
	"fmt"
	"os"
	"path/filepath"
)

func main() {
	notExistedPath := "/notExistedPath"
	filepath.Walk(
		notExistedPath,
		func(path string, info os.FileInfo, e error) error {
			fmt.Println("invoked",
				"\npath is:", path,
				"\ninfo is:", info,
				"\nerror is:", e)
			return nil
		},
	)
}
{% endhighlight %}


## flag.Bool

在吐槽这个之前，先简单的介绍一下命令行参数吧。命令行参数大致分为option（选项）/argument（参数）/command（命令）三种类型。

option的作用是改变程序的行为，通常具有长和短两种形式，根据选项行为可分为switches(开关)和flags（标志）两类。switches通常用于开启或关闭某项功能，不接受任何参数，而flags则通常会接受参数。

argument通常是命令行中除去option的部分，被操作的对象，可能是文件或者目录等等。

与option和argument不同，command具有更明确的意义，用来管理一些列复杂的行为。使一些程序比较复杂，例如git，更易于使用和管理。由于command的出现导致option分为了global option和command option。

关于命令行更详细的介绍《python标准库》中关于命令行模块和《Build Awesome Command-Line Applications in Ruby 2》都是不错的资料。

言归正传，go语言中flag.Bool是典型的开关型选项。在使用前，当然要写一个小程序来学习一下：
{% highlight go %}
package main

import (
	"flag"
	"fmt"
)

func main() {
	var b bool
	flag.BoolVar(&b, "b", false, "description for b")
	flag.Parse()
	fmt.Println(b)
}
{% endhighlight %}

测试：
{% highlight bash %}
% go run test.go
false
% go run test.go -b
true
{% endhighlight %}

It's simple and everything looks fine. 我再次天真的以为没问题了。接下来试一下另外一个程序吧。
{% highlight go %}
package main

import (
	"flag"
	"fmt"
)

func main() {
	var b bool
	flag.BoolVar(&b, "b", true, "description for b")
	flag.Parse()
	fmt.Println(b)
}
{% endhighlight %}

测试：
{% highlight bash %}
% go run test.go
true
% go run test.go -b
true
{% endhighlight %}

WTF!!!您这是闹哪样啊，欺负新来的是吧，反人类是吧，你还可以再叼一点大丈夫的。好吧，我承认我又没读文档，因为在文档上找到了这样一句话：
>You must use the -flag=false form to turn off a boolean flag.

所以说大牛的世界你不懂，你所需要做的就是好好读文档，如果有的话，然后吐槽吧。


## url
前段时间在处理背景图片的时候遇到一个问题，那就是url中空格的问题，空格无法直接使
用，需要转换为`%20`，而在go语言中正好有一个url的包，不过url包略有小坑。
在url包中有一个叫`url.QueryEscape`的全局函数，咋一看这似乎就是所需的函数。
{% highlight go %}
package main

import (
	"fmt"
	"net/url"
)

func main() {
	fmt.Println(url.QueryEscape("a b"))
}
{% endhighlight %}
得到的结果是：
{% highlight bash %}
a+b
{% endhighlight %}

这个必须不是正确的结果的。那么在go中到底有没有需要的函数呢？在网上查了老半天，
stackoverflow上也有类似的问题，不过却并没有的到解答。处于无奈，只能区看源代码了
，还好是开源的。在go的url包的源代码中发现却是存在将空格转换成`%20`的代码段，仔
细看看了，发现String()函数就是寻找的函数。
{% highlight go %}
package main

import (
	"fmt"
	"net/url"
)

func main() {
	fmt.Println(url.Parse("a b"))
}
{% endhighlight %}

输出结果为：
{% highlight bash %}
a%20b <nil>
{% endhighlight %}

也怪自己知识浅薄，不懂灵活运用，虽然知道在空格会转换成%20但是，并没有想到`%20`
才是url中的合法字符，对文档中对String函数的描述并没有在以，虽然很无奈，这么不起
眼的函数，也并没有想到会来处理编码问题（percent-encoding）。

小结一下：
<pre>
|javascript        |golang         |
|------------------|---------------|
|encodeURI         |URL.String     |
|escape            |url.QueryEscape|
|encodeURIComponent|none           |
</pre>

也许encodeURIComponent可以通过其他方法组合实现，但是去并没有提供一个单独的函数
来。
