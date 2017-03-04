---
layout: post
title: Golang Reflect 101
description: "golang reflect 101"
modified: 2014-02-22
tags: [golang, go]
image:
  feature: abstract-3.jpg
  credit: dargadgetz
  creditlink: http://www.dargadgetz.com/ios-7-abstract-wallpaper-pack-for-iphone-5-and-ipod-touch-retina/
comments: true
share: true
---

元编程是一个很有意思东西，正好golang中包含了一个reflect包提供反射功能，上周末看了看reflect包，在此记录一下学习体会。

## 元编程

首先，了解一下元编程及其相关概念。元编程是什么？元编程就是普通的编程。那么为什么会有元编程这个概念呢？这是因为元编程会做出一些比普通编程行为更酷的行为，它能够通过写好的代码来处理代码，因此给它起了一个新名字以示区分。听起来有些矛盾和拗口，下面来看一个例子说明一下吧。

有过Qt或者MFC编程经验的人都知道，如果我们想要给按钮或者其他控件添加对某个事件的响应处理函数，只需要按照一定的明明规范来命名一个函数即可。例如在Qt中，想要对一个名叫btn的按钮绑定一个点击事件的处理函数只需要位该函数命名为`on_btn_clicked`即可。但是，我们并没有显示的将该函数和btn连接在一起，这是怎么做到的呢？Qt中一些代码会分析函数名，当检测到以`on_objectname_signalname`命名的函数时，Qt会自动将该函数和`objectname`对象的`signalname`信号绑定。这就是元编程，通过代码来对其他代码进行处理。

## 反射(reflection)和内省(type introspection)

[反射](http://en.wikipedia.org/wiki/Reflection_(computer_science))和[内省](http://en.wikipedia.org/wiki/Introspection_(computer_science))是和元编程息息相关的两个概念，这两个概念非常相似，但却有很大的不同。

> **内省**是在运行时检查对象的类型和属性的能力，**反射**是在运行时检查和修改程序结构和行为的能力。

可以看出，反射比内省更加强大，内省是反射的子集，这一点不应该混淆。有些为地方可以看到说自省和反射是一回事，我想这个自省应该是根据`introspection`来翻译的，而`introspection`是`type introspection`的简称。so，不要相信那些人，他们应该去补习了。

## golang reflect

在golang中，提供了一个`reflect`包，这个包主要包含了两个主要类型`Type`和`Value`，并且在`reflect`包中还提供了两个非常方便的函数`TypeOf`和`ValueOf`来分别获得这两种类型。下面来看一段示例代码：
{% highlight go %}
package main

import (
	"fmt"
	"reflect"
	"regexp"
)

type Struct struct {
	Pub string
	pri int `pri:"private"`
}

func (s *Struct) Pri() int {
	return s.pri
}

func (s *Struct) sum(o int) int {
	return s.pri + o
}

func (s *Struct) Sum(o int) int {
	s.pri = s.sum(o)
	return s.pri
}

func (s *Struct) Name(firstName, lastName string) string {
	return firstName + " " + lastName
}

func sum(a, b int) int {
	return a + b
}

func main() {
	s := &Struct{}
	v := reflect.ValueOf(s)
	t := reflect.TypeOf(s)

	fmt.Println("Type:", t)
	fmt.Println("Value:", v)
	fmt.Println("Kind:", t.Kind())

	for i := 0; i < t.Elem().NumField(); i++ {
		f := t.Elem().Field(i)
		fmt.Printf("struct field %d: %s, %s， embeded?: %v, tag: %v\n", i, f.Name, f.Type, f.Anonymous, f.Tag)
	}
	for i := 0; i < t.NumMethod(); i++ {
		m := t.Method(i)
		fmt.Printf("struct field %d: %s, %s\n", i, m.Name, m.Type)
	}

	callMethod := func(s reflect.Value, methodName string, methodArgs ...reflect.Value) ([]reflect.Value, error) {
		t := s.Type()
		method, exist := t.MethodByName(methodName)
		if !exist {
			return nil, fmt.Errorf("\"%s\": is not existed for %s", methodName, t)
		}

		if regexp.MustCompile(`^[a-z]`).MatchString(method.Name) {
			return nil, fmt.Errorf("\"%s\": unexported field cannot be called", method.Name)
		}

		args := []reflect.Value{s}
		args = append(args, methodArgs...)

		return method.Func.Call(args), nil
	}

	fmt.Print("call Struct.Pri: ")
	fmt.Println(callMethod(v, "Pri"))

	fmt.Print("call Struct.Sum: ")
	fmt.Println(callMethod(v, "Sum", reflect.ValueOf(1)))

	fmt.Print("call Struct.Name: ")
	fmt.Println(callMethod(v, "Name", reflect.ValueOf("David"), reflect.ValueOf("Beckham")))

	fmt.Print("call Struct.sum: ")
	fmt.Println(callMethod(v, "sum", reflect.ValueOf(1)))

	fmt.Print("call Struct.s: ")
	fmt.Println(callMethod(v, "s"))

	fn := reflect.ValueOf(sum)
	ft := fn.Type()
	for i := 0; i < ft.NumIn(); i++ {
		in := ft.In(i)
		fmt.Printf("function argument %d: %s\n", i, in)
	}
	for i := 0; i < ft.NumOut(); i++ {
		out := ft.In(i)
		fmt.Printf("function return value %d: %s\n", i, out)
	}

	i, j := 1, 3
	fmt.Printf("Call sum(%d, %d) function: %v\n",
		i, j,
		fn.Call([]reflect.Value{
			reflect.ValueOf(i),
			reflect.ValueOf(j),
		})[0].Interface(),
	)
}
{% endhighlight %}

如果运行这段代码会得到一下输出：
{% highlight bash %}
Type: *main.Struct
Value: <*main.Struct Value>
Kind: ptr
struct field 0: Pub, string, embeded?: false, tag: 
struct field 1: pri, int, embeded?: false, tag: pri:"private"
struct field 0: Name, func(*main.Struct, string, string) string
struct field 1: Pri, func(*main.Struct) int
struct field 2: Sum, func(*main.Struct, int) int
struct field 3: sum, func(*main.Struct, int) int
call Struct.Pri: [<int Value>] <nil>
call Struct.Sum: [<int Value>] <nil>
call Struct.Name: [David Beckham] <nil>
call Struct.sum: [] "sum": unexported field cannot be called
call Struct.s: [] "s": is not existed for *main.Struct
function argument 0: int
function argument 1: int
function return value 0: int
Call sum(1, 3) function: 4
{% endhighlight %}


## 代码分析

这段代码虽然有点长，不过却非常简单和清晰，现在来分析一下这段代码及其输出结果。

在代码的开始部分，通过`reflect.ValueOf`来获取`Struct`结构体指针的值信息，通过`reflect.TypeOf`来获取`Struct`结构体指针的类型信息，需要留意的地方是，这里创建的是一个`Struct`的结构体指针，而不是一个`Struct`结构体。

### Kind

在代码的第47行调用了一个叫`Kind`的方法，`Kind`方法是用来表示一个`Type`是属于哪一种类型的，因此，通过`Kind`方法也可以准确的判断出这是一个`ptr`。


### Elem

在遍历结构体字段时用到了一个叫`Elem`的方法，由于`s`是一个指针类型，因此需要通过`Value.Elem`得到结构体的值信息，这样才能获取`Struct`结构体中的字段信息。同时需要注意，`Value.Elem`方法只对指针和接口——例如`error`——有效。

在`reflect.Value`和`reflect.Type`中有不少命名相同的方法，不过意义却不一样，`Elem`就是一个典型的例子，与`Value.Elem`不同，在`reflect.Type`中`Type.Elem`用来可以用来表示map中值的类型。


### struct tag

在golang中有一个被成为`struct tag`的东西，每次见到这个东西都感觉怪怪的，通常也很少使用。

`struct tag`通常是一个用空格分隔的键值对，在键中不包含双引号，冒号和空格，而值则是由双引号引起来的任意字符。

不过鉴于`struct tag`是一个字符串，而`reflect.StructTag`本身其实也是一个字符串，也许可以在适当的时候自由发挥一下。另外，`reflect.StructTag`只有一个`Get`方法。

下面是来自`reflect`包文档中的一个例子，更详细的展示了`struct tag`的用法：

{% highlight go %}
package main

import (
	"fmt"
	"reflect"
)

func main() {
	type S struct {
		F string `species:"gopher" color:"blue"`
	}

	s := S{}
	st := reflect.TypeOf(s)
	field := st.Field(0)
	fmt.Println(field.Tag.Get("color"), field.Tag.Get("species"))

}
{% endhighlight %}


### Method and Call

接下来是`callMethod`函数。在`callMethod`函数中有几个地方需要注意。

首先是通过`reflect.Type`中的`MethodByName`方法来获取`reflect.Method`类型的方法信息，以及判断该方法是否存在。

如果你愿意，同样可以使用`reflect.Value`中的`MethodByName`方法来获得`reflect.Value`类型的方法信息，然后通过`Value.IsValid`来判断该方法是否存在。这里的`reflect.Value`类型的信息等于`reflect.Method`类型中的`Func`字段。

第二个需要注意的地方时这里通过使用正则表达式来判断方法的名字的首字母大小写来判断该方法是否导出，这是由于`reflect`包中似乎并没有提供可以判断方法和字段是否导出的方法。

第三，在调用一个结构体方法时，需要将`receiver`作为第一个参数传递个方法。


### Value.Type()

在对`sum`进行反射时并没有使用`reflect.TypeOf`，而是使用了`Value.Type`方法，这个方法同样可以得到类型信息。


### Interface

在代码的最后一部分取得返回值时使用了`Value.Interface`方法。该方法的作用是返回一个`interface{}`以便能够获取真正的值。


## 改变对象的值

`reflect`包出了获取各种信息以外，还可以改变变量的值。一个对象能否设值，可以通过`Value.CanSet`方法来判断。不过需要记住，只有指针类型通过`Elem`函数来得到真正的对象才能设值。这是因为在[laws of reflection](http://golang.org/doc/articles/laws_of_reflection.html)中有这么一句话：

>	Just keep in mind that reflection Values need the address of something in order to modify what they represent.


## 总结

`reflect`保重常用的方法克功能基本都涉及到了，不过并没有事无巨细的讲解，还有channel，slice，map，embeded field等没涉及到，更详细的内容只有一边在实际中去探索，一边参看引用，才会更有意义。希望元编程能够在适当的地方改善我们的生活。


## reference

1. [golang reflect package document](http://golang.org/pkg/reflect/).
2. [laws of reflection](http://golang.org/doc/articles/laws_of_reflection.html).(注：网上有有中文翻译版本。)
