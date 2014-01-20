# ## 依赖
require 'sinatra'
# require 'rexml' # because it's in the std lib
require 'http' # https://github.com/tarcieri/http

# ----
# ## 如何使用
#
#      ruby server.rb
#
# 站点会运行在 http://localhost:4567

# ## 整体思路说明
# 1. 第一次验证通过后，我们需要把验证信息对应用户在本地存一下，并设定过期时间
# 2. 这个信息用cookie的形式让用户也存着
# 3. 如果过期了，我们要求用户再去验证，如果没有过期.就继续允许用户访问
# 4. 由于kidslib网站没有任何地方让用户个性化和保存个人设置，
#    因此我们根本不需要得到用户名等信息。
#    只需确保ticket没有过期。
# 5. 每次用户访问一个页面，在本地的db中延长一下ticket过期时间

# ----
# ## sinatra全局设定
# URI.encode_www_form([['AppId', 'kidslib'], ['server', 'http://0.0.0.0:4567']])
configure do
  enable :sessions # all request will have session either we set it or rack:session sets it automatically
  set :site_url, 'http://0.0.0.0/'
  set :session_valid_for, 60 * 1 # 60 minutes
  set :sso_server, 'http://218.245.2.174:8080'
end

# ----
# ## 帮助函数
helpers do

  # 单线程跑这个程序，内存中就会持久化这个DB
  # 之前测试不行是因为每次请求 shotgun 都重新载入这个文件
  DB = {}

  # ----
  # interface呗。程序中直接调用只有interface这两个函数
  def save_ticket(ticket)
    DB[ticket] = Time.now.to_i
  end

  def valid?(ticket)
    !expired?(ticket) || (redirect '/login')
  end

  # ----
  # helper functions
  def expired?(ticket)
    ticket?(ticket) && (Time.now.to_i - timestamp(ticket) > settings.session_valid_for)
  end

  def ticket?(ticket)
    DB[ticket] || remote_ticket?(ticket)
  end

  # ----
  # 4 登陆后需要再次验证时候的接口:
  # http://sso.server.ip.address/ssoServer/serviceValidate
  # 登录到 ssoServer 成功后,返回到子系统,拿到 ticket 后,再拿 ticket 到上述接口地
  # 址去请求一下,以得到对应的用户名。
  def remote_ticket?(ticket)
    HTTP.get 'http://218.245.2.174:8080/ssoServer/serviceValidate'
  end

  def timestamp(ticket)
    DB[ticket].to_i # 如果 DB[ticket] 的值是 nil，会转为数字0，好让 expired? 函数做时间上的加减。
  end

  def extend_ticket_time(ticket)
    DB[ticket] = Time.now.to_i + settings.session_valid_for
  end

  def delete_ticket(ticket)
    DB.delete ticket
  end

end

# ----
# ## before filter
# 会运行在所有请求前
# 静态文件除外！！
# 这是sinatra源码中写死的。符合逻辑。可惜我正好不希望这样
# 因此后面采取了些非常规手段 ；）
before '/*.html' do
  if valid? session['ticket']
    pass
  else
    redirect '/login'
  end
end

# ----
# ## 路径 + HTTP VERB
get '/' do
  redirect '/index.html'
end

# ----
# ## 登陆
get '/login' do
  '据说登陆后学习效果更佳！'
  redirect 'http://218.245.2.174:8080/ssoServer/login?AppId=kidslib&server=http%3A%2F%2F0.0.0.0%3A4567'
end

# ----
# ## 登出
# 3 退出sso需要调用的接口:
# http://218.245.2.174:8080/nanhai/singleLogout
# Sso退出,这个退出调用,是删除调CAS的ticket 各子系统的session需要各子系统自己删除。
# 暂时没有提供用户logout的地方，也不准备提供。我们可以吧session过期时间设定短一点
# FIXME: 如何通知sso删除这个ticket？
get '/logout' do
  delete_remote_ticket session['ticket']
  session.clear
  redirect '/'
end

# ----
# ## 设置session
# 本接口返回的 service 地址后面带的参数:
# ticket(ticket 会在 service 地址后自动加上,
# 例如:http://xxx/yyy.asp?Ticket=qweury03432432423ktjgj)
get '/set-session' do
  ticket = params['Ticket']
  if remote_ticket?(ticket)
    session['ticket'] = ticket
    save_ticket ticket
    redirect '/'
  else
    redirect '/login'
  end
end

get '/db' do
  "#{DB.to_s}"
end

# ----
# ## 需要保护的html文件
# 1. 将要保护的html文件 从 public 目录移到与 server.rb 平行的html目录
# 1. 且要保持目录
get '/*' do |path|
  begin
    File.read "html/#{path}"
  rescue
    '你找谁？没这人啊！'
  end
end
