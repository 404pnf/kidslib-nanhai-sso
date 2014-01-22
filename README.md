nanhai-sso
==========

# 安装ruby环境和需要的ruby gems

     ./INSTALL_DEPENDENCIES.sh

# 运行程序

    ./start.sh # 如果希望在后台 ./run.sh &

# 停止程序 

    ./stop.sh 

# 遇到的问题
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


# 直接将session信息存到内存的hash中

之前不成功是因为开发时用shotgun，每次访问页面都重载整个rb文件，因此，内存中的db每次都重新被初始化，自然只能记住最后一次的结果。

在没想到是这个原因的时候，我改用pstore持久化到文件中。效果也不错。但还是麻烦。

现在改回用内存中的hash了。

