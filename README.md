nanhai-sso
==========

sinatra中到的before filer对public目录中的静态文件不起作用。 sinatra源码中

dispatch方法定义中statck!在filter!前面
https://github.com/sinatra/sinatra/blob/master/lib/sinatra/base.rb#L1065

我已经像社区询问更好的解决方法
https://github.com/sinatra/sinatra/issues/761#issuecomment-31435059

这个设定是完全合理的。

但我这个项目有个不合理的要求，因此我用蹩脚的方案来解决吧。

1. 将所有静态文件复制到 public 目录

2. 将希望收到保护的文件按原有在public结构放到 html 目录

3. 将需要保护的文件从public目录删除

4. 在before filter中设定验证逻辑，过了，就让用户访问 html/ 中的html页面，方法是 File.read 'html/somefile.html' 返回给用户

相当蹩脚。没有更好方法前，就先这样了。

我希望的方法就是只用到sinatra，不和任何web server采用 x-sendfile 的方式结合。

你能帮帮我么？


