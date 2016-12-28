---
layout: post
title: Golang Traps
description: "record golang's traps"
modified: 2014-02-22
tags: ['golang', 'go']
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

~~~go
func Exist(path string) {
    _, err := os.Stat(path)
    return err == nil || os.IsExist(err)
}
~~~


## 没有拷贝文件的函数

关于这一点，在github上有一个[项目](https://github.com/daaku/go.copyfile)可以一
定程度上的解决这个问题，不过这个项目还有待完善，而且我个人感觉很不习惯。


## filepath.Walk

这个问题是今天(2014-02-20)遇到的，当我天真的以为对一个不存在的路径进行Walk的时候，此函数什
么也不会做，然后像其他函数一样返回错误给我的时候，可结果却是该函数仍然会调用回
调函数。后来在文档中发现了这个小秘密，**所有**错误都在回调函数中通过第三个参数处理。我之前还在纳闷回调中的第三个参数有什么用，显然这是我没有仔细阅读文档而相当然的错。

~~~go
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
~~~


## flag.Bool

在吐槽这个之前，先简单的介绍一下命令行参数吧。命令行参数大致分为option（选项）/argument（参数）/command（命令）三种类型。

option的作用是改变程序的行为，通常具有长和短两种形式，根据选项行为可分为switches(开关)和flags（标志）两类。switches通常用于开启或关闭某项功能，不接受任何参数，而flags则通常需要接受参数。

argument通常是命令行中除去option的部分，被操作的对象，可能是文件或者目录等等。

与option和argument不同，command具有更明确的意义，用来管理一些列复杂的行为。使一些比较复杂的程序，例如git，更易于使用和管理。同时，由于command的出现导致option分为了global option和command option。

关于命令行更详细的介绍《python标准库》中关于命令行模块和《Build Awesome Command-Line Applications in Ruby 2》都是不错的资料。

言归正传，go语言中flag.Bool是典型的开关型选项。在使用前，当然要写一个小程序来学习一下：
~~~go
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
~~~

测试：
~~~bash
% go run test.go
false
% go run test.go -b
true
~~~

这个程序很简单，使用方式也很简单，并且程序的运行结果也正是所期待的结果。我再次天真的以为没问题了。接下来试一下另外一个程序吧。
~~~go
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
~~~

测试：
~~~bash
% go run test.go
true
% go run test.go -b
true
~~~

WTF!!!您这是闹哪样啊，欺负新来的是吧，你还可以再叼一点没关系的。好吧，我承认我又没读文档，因为在文档上找到了这样一句话：
>You must use the -flag=false form to turn off a boolean flag.

事实再一次教育我，Please RTFM carefully。只是我实在无法理解这样一种设计是出于何种原因。

UPDATE：发现一个不错的命令行解析库[kingpin](https://github.com/alecthomas/kingpin)。


## url

前段时间在处理背景图片的时候遇到一个问题，那就是url中空格的问题，空格无法直接使
用，需要转换为`%20`，而在go语言中正好有一个url的包，不过url包略有小坑。
在url包中有一个叫`url.QueryEscape`的全局函数，咋一看这似乎就是所需的函数。
~~~go
package main

import (
	"fmt"
	"net/url"
)

func main() {
	fmt.Println(url.QueryEscape("a b"))
}
~~~
得到的结果是：
~~~bash
a+b
~~~

这个必须不是正确的结果。那么在go中到底有没有需要的函数呢？在网上查了老半天，
stackoverflow上也有类似的问题，不过却并没有的到解答。处于无奈，只能去看源代码了
，还好是开源的。在go的url包的源代码中发现却是存在将空格转换成`%20`的代码段，仔
细看看了，发现`String()`函数就是寻找的函数。
~~~go
package main

import (
	"fmt"
	"net/url"
)

func main() {
	fmt.Println(url.Parse("a b"))
}
~~~

输出结果为：
~~~bash
a%20b <nil>
~~~

小结一下：
<pre>
|javascript        |golang         |
|------------------|---------------|
|encodeURI         |URL.String     |
|escape            |url.QueryEscape|
|encodeURIComponent|none           |
</pre>

也许encodeURIComponent可以通过其他方法组合实现，但是却并没有提供一个单独的函数
来。


## unsetenv

公司同事在写网络代理相关的代码，在设置系统代理时会设值环境变量，在设置和清空环境变量方面golang还是很方便的，只需要使用`os.Setenv`即可，可是如果需要删除一个环境变量时该怎么办呢？经过我的探索，sorry，在golang中目前并没有unsetenv函数，不过似乎已经有准备在以后的版本中将unsetenv添加到`os`包中。那么现在要使用unsetenv该怎么办呢？
于是同事写了一个UnsetEnv函数：
~~~go
func UnsetEnv(envName string) (err error) {
	envs := os.Environ()
	newEnvsData := make(map[string]string)
	for _, e := range envs {
		a := strings.SplitN(e, "=", 2)
		var name, value string
		if len(a) == 2 {
			name = a[0]
			value = a[1]
		} else {
			name = a[0]
			value = ""
		}
		if name != envName {
			newEnvsData[name] = value
		}
	}
	os.Clearenv()
	for e, v := range newEnvsData {
		err = os.Setenv(e, v)
		if err != nil {
			return
		}
	}
	return
}
~~~

这个函数在某些程序中确实可以正确的运行，可是在测试过程中我们发现这个函数对通过C绑定的gio函数调用的程序并没有生效，于是就想到使用C中的`unsetenv`函数，便有了以下的函数：
~~~go
func UnsetEnv(_name string) {
	name := C.CString(_name)
	defer C.free(name)
	C.unsetenv(name)
}
~~~

确实C绑定的函数调用的程序生效了，可是通过golang调用的程序却不生效了==，最后只有将两个函数柔和在一起才能生效。

我们并没有深入挖掘这个问题，也并不是非常确定是不是我们使用的姿势不对，这里仅供参考。
