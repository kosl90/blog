# 引言

最近公司准备在新项目中使用 Git 替代 SVN 来管理项目，但是公司内部搭建的 Git 服务器不支持通过 HTTPS 的方式推送代码，同时由于 VSCode 可以支持 HTTPS 协议
推送代码时输入用户名和密码，但是使用 SSH 方式进行推送时则不会询问密码，直接报错报错，因此需要对 SSH 进行一番设置。


# 准备工作

- SSH 客户端，本文使用 PuTTY 中的相关软件，包括 plink 、 PuTTYgen 、 Pageant。
- Git 环境，直接使用 Git 官方的 Git for Windows 版本即可， Git Extension 或其他替代品。

由于项目可能跨平台的关系，推荐将 autocrlf 设置成 input 或者 false ， safecrlf 设置成 true。


# 配置

首先，使用 PuTTYgen 软件来生成 SSH2 的 RSA 类型密钥对。因为密钥并没有统一的保存文件格式，因此保存密钥对是比较关键的地方， PuTTYgen 在这方面比较友好，
可以导出多种格式的密钥，对于公钥而言通常将只读的文本区内的 OpenSSH 格式的内容复制粘贴到网站或其他需要存放公钥的地方保存即可，这是由于保存公钥的基本都
是服务器，而服务器基本都是类 Unix 环境，在这些环境中使用的 SSH 服务基本都是 OpenSSH。对于私钥，直接点击 “Save private key” 按钮保存即可，如果有其他
格式的需要，可以通过 Conversions 菜单将私钥保存为其他格式，但是这里不需要，因为 PuTTY 只识别自己的 ppk 格式。


第二步，启动 Pageant 软件，可以将其设置为开机启动，比如在开始菜单中的启动目录中存放一个 Pageant 软件的连接即可。启动软件后需要将刚才生成的私钥导入到
 Pageant 软件中，如果有将 ppk 格式的软件与 Pageant 软件关联的话，直接双击 ppk 文件即可，如果没有关联则可通过 TrayIcon 右键菜单中的 “Add Key” 添加
 私钥，如果在创建密钥对的时候有设置密码需要输入一次密码才能成功导入。


第三步，测试链接，以 Github 为例，在命令行输入 `plink git@github.com` 来测试，同时也用于保存 Git 服务器的 fringeprint。在测试时总是以 git 作为
用户名是一个好习惯。


第四步，设置 GIT_SSH 环境变量为 plink 程序。


完成以上步骤后即可在不输入密码的情况下使用 Git 推送和更新代码了。需要注意，第二步和第三步的顺序关系不能变更，否则在使用 plink 时会出现错误。


# 更多

有一点需要注意，出于安全性和 Windows 平台的限制，重启之后 Pageant 载入的密钥是不会自动重新载入的，需要手动添加。这个问题有两个解决办法。
第一方法是修改启动 Pageant 程序的连接文件，在“目标”中的 Pageant 程序后接上要载入的私钥的路径。第二中方法是将 ppk 文件与 Pageant 程序关联，
然后直接将ppk文件或其连接设置为开机启动。如果设置类 SSH 密码这，两种方法都需要在载入时输入密码。


另外还有一个引申出来的情况，在 Git for Windows 自带的 OpenSSH 有一个叫做 ssh-pageant 的程序，这个程序可以将 OpenSSH 的认证代理到 Pageant 程序
上，这样一来就可以直接使用 PuTTYgen 生成的 ppk 文件来作为 OpenSSH 的密钥文件，而不用多保存一份 OpenSSH 才能识别的 OpenSSH 格式的密钥。在使用
 ssh-pageant 程序时需要注意的是，需要在 Git Bash 中使用 `eval $(ssh-pageant)` 来执行 ssh-pageant 的输出内容进行一些环境变量的设置才能正常使用。
 
注：在 $HOME/.profile 中可以覆盖掉 GIT_SSH 环境变量，从而避免在 Git Bash 中使用 plink 程序作为 SSH 的替代品。
 
 
# Useful Links
 
- [GitHub's SSH key fingerprints](https://help.github.com/articles/github-s-ssh-key-fingerprints/)
- [Testing your SSH connection](https://help.github.com/articles/testing-your-ssh-connection/)
- https://winscp.net
- [Using SSH Keys in Visual Studio Code on Windows](http://www.cgranade.com/blog/2016/06/06/ssh-keys-in-vscode.html)
- [Windows git SSH authentication to GitHub](https://vladmihalcea.com/tutorials/git/windows-git-ssh-authentication-to-github/)
- [Automatically start Pageant with private keys in Windows](http://www.martijnburgers.net/post/2011/11/26/Automatically-start-Pageant-with-private-keys-in-Windows.aspx)
