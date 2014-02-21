---
layout: post
title: Copy Constructor 101
description: "C++ copy constructor 101"
modified: 2014-02-22
tags: [c++, oo]
image:
  feature: abstract-3.jpg
  credit: dargadgetz
  creditlink: http://www.dargadgetz.com/ios-7-abstract-wallpaper-pack-for-iphone-5-and-ipod-touch-retina/
comments: true
share: true
---

今天打包组的同事要我帮他解决一个C++重载出错的问题，虽然当时解决了，但是并没有找
到准确的错误原因，后来通过clang++的错误提示发现其实是一个很基础的C++概念，所以
说学过的东西不用就容易忘记，另外g++的错误提示弱爆了。

如下代码是模拟实际代码的精简改编版。

{% highlight cpp %}
class C {
    C(C&){}
    C(int){}
    C(double){}
};

void f(C)
{}

int main()
{
    f(C(1));
}
{% endhighlight %}

如果直接编译当然会出错，从clang++的错误输出中可以很轻松的看出这是由于传递给构造
函数一个右值而导致的错误。从理论上讲，拷贝构造函数只需要传递引用避免无限递归调
用即可。确实不采用任何修饰的引用在一般情况下也可以正常使用，可是当传入一个右值
的时候，就会出错，即以上代码的问题所在。

那么要如何解决这个问题呢？很简单，只需要使用const reference即可，因为在C++中，
如果想要引用一个右值必须使用const reference。而从语义上来讲，作为一个拷贝构造函
数，其参数是用来构造新的类，不应对其进行修改。当然，如果使用c++0x标准使用右值引
用同样可以解决此类问题。

{% highlight cpp %}
class C {
    C(const C&){}  // const-reference
    C(C&&){}  // r-value reference, c++0x and later
    C(int){}
    C(double){}
};

void f(C)
{}

int main()
{
    f(C(1));
}
{% endhighlight %}


#Much More
1. [Copy Constructor, assignment operators, and exception safe assignment](http://www.cplusplus.com/articles/y8hv0pDG/)
2. [what is the copy-and-swap idiom](http://stackoverflow.com/questions/3279543/what-is-the-copy-and-swap-idiom)
3. [Want speed? Pass by Value](http://cpp-next.com/archive/2009/08/want-speed-pass-by-value/)
