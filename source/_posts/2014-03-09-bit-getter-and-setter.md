---
layout: post
title: Bit Getter and Setter
description: "a simple bit getter and setter"
modified: 2014-03-09
tags: [c, cpp, c++, bit-operation]
image:
  feature: abstract-6.jpg
comments: true
share: true
---

昨天周六，下午把床晒了晒，在晒床的时候呢，我则躺在沙发上看了看《算法精解》，正好看到位运算。里面有两个简单的操作，
一个是对某一位设1/0，另一个则是获取某一位是1/0。当时的直觉是，代码写的简单直白，应该还有更高效的处理方法。

虽然这个想法仅仅是在脑海中一闪而过，但是晚上正好在C++吧看到[一篇帖子](http://tieba.baidu.com/p/2900558125)，
楼主提出了类似的写法，并称该算法效率太差，希望高手指教。

进去看了看，首先看到的是楼主说即使将mask存入数组，可还是太慢。另外有人给出了一段简单的代码片段，楼主根据这个代码片段写了一个简单的宏：

~~~c
#define SetBit(LPByte,BitPlace,BitValue) ( BitValue==0? (*LPByte)&=~(1<<(BitPlace-1)) : (*LPByte)|=(1<<(BitPlace-1)));
~~~

代码很简单，首先判断要设的值是1还是0，然后根据这个值来对1进行位移等位操作然后根据不同的值使用其他位操作来对特定的位设值。
不过根据评论，似乎对性能没有多大的影响。看到这段代码的感觉是，应该可以不用判断BitValue的值，而是对BitValue进行某些位操作来得到某个值，
之后使用这个值与LPByte进行一定位操作之后的结果进行某个位操作之后即可得到正确的值。果然，楼主在楼下提出了另一段代码，实现了我所想的方案：

~~~c
#define SetBit(LPByte,BitPlace,BitValue) ( (*LPByte) = ( (*LPByte)&~(1<<(BitPlace-1) ))|(BitValue<<(BitPlace-1)) );

#define GetBit(LPByte,BitPlace,BitValue) ( BitValue=((*LPByte)&(1<<(BitPlace-1)))>>(BitPlace-1) );
~~~

宏看起来都比较麻烦，而且这段宏还存在着一定的问题，为了方便我将其整理成为了一下代码：

~~~ c
unsigned char set_bit(unsigned char b, int pos, int value)
{
    return (b & ~(1 << (pos - 1))) | (value << (pos - 1));
}

int get_bit(unsigned char b, int pos)
{
    return (b & (1 << (pos - 1))) >> (pos - 1);
}
~~~

这段宏改编的代码很简单，而且所采用的思想其实也很简单，对于set\_bit函数来说，首先通过对1的位移和取反，然后与b进行与操作将该位置为0，
然后对value进行位移，之后再与之前清空后的结果进行或操作得到最后的结果。类似的，get\_bit函数则是与set\_bit函数相反，将其他位置位0而保留需要获取的位，
之后将其位移得到最后的结果。后来楼主又贴出了另外一段对n位进行处理的代码：

~~~c
#define GetNBit (LPByte,Begin,End,BitValue) (BitValue=((*LPByte)&((255>>(8-End))&(255<<(Begin-1))))>>(Begin-1));

#define SetNBit (LPByte,Begin,End,BitValue) (*LPByte)=((*LPByte)&(~((255>>(8-End))&(255<<(Begin-1)))))|(BitValue<<(Begin-1));
~~~

这段代码就不改写了，原理和之前的是一样的。当然，还有人提到了内联汇编，使用BT/BTS之类的命令，不过我觉得已经没有必要了。
虽然我不是很懂汇编，也没有测试，不过我对使用这些带有测试的操作能够比直接通过简单的位操作来得到结果更快持怀疑态度，
过段时间我想我会测试一下。

不过既然提到了汇编，而主题又是位移什么的，不禁让我想起了以前看《深入理解计算机系统》的日子，情不自禁的将代码生成汇编代码观察了一番，
代码比较简单，没什么值得多说的，值得一提的是参数和本地变量是通过ebp寄存器做偏移得到的，eax寄存器则被频繁用于存储结果，并在最后用来
存储函数的返回值。而楼主以前使用switch很慢的原因，根据幻之上帝的说法是：要分支预测+间接操作慢个几十倍正常。

回头想一下，其实这些操作与思想都是很基础的，尤其是将对某一位进行保留和置1/0这几个操作可以说是基础中的基础。再次提醒自己，
不论做什么事情，基础都是最重要的，不要只看到别人的光鲜亮丽，要静下心来学习，打好基础，只有基础好了，才能够从基础中演变出各种犀利的东西。


参考资料（关于汇编的）：

1. [x86 Assembly Guide](https://www.cs.virginia.edu/~evans/cs216/guides/x86.html)
2. [IA-32 Assembly for Compiler Writers](https://www.cse.nd.edu/~dthain/courses/cse40243/fall2008/ia32-intro.html)
3. [A Readers Guide to x86 Assembly(pdf)](https://cseweb.ucsd.edu/classes/sp10/cse141/pdf/02/S01_x86_64.key.pdf)
4. [分析.cpp文件编译生成的汇编文件里语句的作用](http://www.cnblogs.com/justinyo/archive/2013/03/08/2950718.html)