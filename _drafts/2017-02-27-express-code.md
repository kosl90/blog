# 预备知识

设计理念：以中间件为核心打造简单，灵活，健壮的HTTP Server

内置支持：Router，Template，SendingFiles，JSONP

不支持：multipart，需要使用中间件


# 源码分析

## express.js

express.js 文件为入口，导出创建实例的工厂函数和以 Router 为主的内置增强功能接口。

一个 express 实例，会 mixin EventEmitter 和 Application 两个类。**为什么不是 Application mixin EventEmiiter？？？因为实际上 Application 内部实现是需要 EventEmitter 支持的**


## application.js

包含设置，模板和路由相关内容，大部分功能会转发个 Router 处理

### 属性
- cache，{}，对模板的 cache，在 production 环境下默认请用，可通过设置在飞 production 环境下启用
- settings，{}，设置信息
- engines，{}，扩展名和对应方法的键值对
- locals，{}，一个 app 内部共享使用的内容，替代 express3 中 configure
- mountpath，app 的挂在路径，顶层 app 的路径默认为 '/'，在获取 path 时，会和父 app 的 path 拼接在一起  # TBD
- _router，Router 对象，
- parent，Application 对象，子 app 中会存在 parent 属性


### public方法

private 方法比较简单，主要是做一些初始化的工作。其中要注意的是 `lazyrouter`，由于设置的内容可能会在创建 app 之后设置或修改，因此需要延迟创建 router，并将内置的中间件加载到 router 上。

- app 提供了一些便捷用于 settings 的设置和获取方法
- engine，设置模板引擎
- path，返回 app 的绝对路径，会和父 app 的 path 拼接起来
- param，代理到 Router 的 param 方法，根据 path 中 param 的值进行某些操作
- listen，默认使用 node 自带http模块创建 HTTP server 的便捷方法，只是将 this 传给了http.createServer 方法
- render，根据 view 的设置，将设置和 locals 传给模板引擎用于渲染，模板渲染相关的具体内容在view.js文件中
- MEHOTD，根据 HTTP verb 生成的方法，会转发给 router 处理。all 是 METHOD 的便捷方法，将请求绑定到所有 HTTP verb上。
- route，代理给 Router，创建路由
- use，一个 app 最核心的方法，在做完参数检查和调整后，会遍历传入的中间件，将中间件传递给 router.use 方法，如果中间件是 Application 的话会为其设置 mountpath 和 parent，然后通过 app.handle 方法代理给 router.use 处理，在将中间件或子 app 代理给 router 之后触发 'mount' 信号。
中间件只需要满足是一个签名满足 `function(req,res,next)` 的函数即可，因此 Application 也是一个有效中间件，如果传入的中间件有 handle 方法则认为是一个 Application。


# Router

## 机制

在 express 的 router 目录中有三个文件，分别是 index.js 、 route.js 、 layer.js 。
在继续之前需要先理解什么是 route，什么是 router。 route 指的是一条路由，用于将某个 URI 对应到某个 handler 上进行处理。而 router 被称为“路由器”，是 route 的管理者，主要用于收集和分发 route 。
回到 express ，通过代码的阅读可以发现，之所以分为了这三个文件是因为在 express 中 router 其实是作为一个中间件的管理者而存在，而并不是传统意义上的 router 。既然 router 更像是一个中间件的管理者，那么 route 自然是不适合直接作为 router 的存储对象而存在的，因此 express 的作者抽象了一个叫做 Layer 的对象用来封装中间件，处理链式调用。当创建一条 route 时，会创建一个新的 Route 对象并赋值给 Layer.route，将每条 route 也作为一个中间件封装到 Layer 对象中，然后再由 router 来处理就变得合情合理了。Layer.route 也成为了区分普通中间件和路由的重要属性。


## Router

属性
- stack，[Layer]，
- params，{}，// TODO
- _params，[]，// TODO
- caseSensitive，bool
- mergeParams，bool
- strict，bool，strict 模式下回区分 path 结尾的 '/'

Router 中两个核心方法是 use 和 handle。

- use ，[Layer]，将参数整理后创建 Layer 对象并放入 stack 对象中。与 Application 中的 use 函数有一些不同的地方在与， Router 的中间件，只能是函数
- handle，调用 stack 中的中间件处理请求，遍历 `stack` ， // TODO: 流程图
- 匹配的 layer
- 是一个 route
- 有支持的方法 goto 处理参数
- goto 处理参数
- next loop
- 如果 layer 不匹配则跳过，
- 处理参数
- 如果是 route，直接调用 layer.handle_request。
- 如果不是 route， trim_prefix，调用 layer.handle_request 或 layer.handle_error
- route 、 METHOD 和 all，METHOD 和 all 内部会调用 route 方法创建一个 route ，然后将对应的  METHOD 绑定到 route 上，并由 route 的 dispatch 函数分发。
- params // TODO


## Layer

Layer 对象比较简单，接受 path，options， callback （代码里叫 fn）作为参数。拥有如下属性：
- handle，function，中间件的处理函数
- name，string，中间件的名字，不存在则使用 '<anonymous>'
- params，{} | undefined，路径中的参数，默认为 undefined，在 match 时会用到，保存有效的参数供 router 使用
- path，layer 正在处理的 path
- regexp，RegExp，源自 express 的依赖库，将传入的 path 转换为 RegExp，regexp 有一个用于优化的属性 fast_slash

- handle_error ，在 router 中出错时调用。函数内部调用 `function(err, req, res, next)` 作为签名的函数进行错误处理，如果不存在则将错误传递给下一个中间件处理。
- handle_request ， 调用构造 Layer 对象时传入的 handle 进行处理（handle 中处理 next），handle 出错时，将错误传递给下一个中间件处理。
- match， Layer 对象中最重要的函数，用于根据传入的 path 匹配，如果匹配成功将 path 和 URL 中的参数保存下来，在 Router 中会被使用到。


## Route

属性
- path，string|RegExp，路由的路径
- stack，[Layer]，存储 route 中处理请求的中间件。在 all 和 METHOD 方法中被使用
- methods，{}，Route 中的 HTTP Verb 与其对应的 handler


## Router 流程

app.use/all/METHOD -> router.use/all/METHOD。


## 请求处理流程

app.handle -> router.handle


## Request和Response

request.js, response.js分别继承nodejs中的http.IncomingMessage和http.ServerResponse，提供一些额外的便捷方法满足常用的需求。以使用 express 的依赖库为主，查看文档即可，有一些不错的方法。

在 Request 中有两个需要和注意的地方：
- `host` 表示的并不是真正意义上的 hostname + ':' + port ，而是 hostname 的别名，在 express5 已经修正
- param 函数，按照路由参数，body，querystring的顺序获取某字段的值。个人觉得这个函数比较鸡肋，不小心的话容易出问题，显示的指明从  params 、 body 或者 querystring 中获取值比较好。该函数在 express5 中被取消了。

// TODO: 挑选一些有意思的内容


# View

response.render -> app.render -> view.render。view 这一部分比较简单，根据路径找到要渲染的文件，然后调用使用的模板将其编译并发送给前端


# vs koa （TODO：另外写一个）

虽然koa与express都是以中间件为核心的极小化HTTP Server，但是koa是自身维护中间件，而express则是以Router为核心维护中间件。


# 引用
- [koa vs express](https://github.com/koajs/koa/blob/master/docs/koa-vs-express.md)


# 别人的express分析
- http://syaning.com/2017/01/10/web-route/
- http://syaning.com/2015/05/20/dive-into-express/
- http://syaning.com/2015/06/16/dive-into-express-2/
- http://syaning.com/2015/10/22/express-in-depth/
