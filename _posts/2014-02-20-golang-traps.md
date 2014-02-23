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
