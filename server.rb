require 'sinatra'
require 'http' # https://github.com/tarcieri/http

# ----
# ## 如何使用
#
#      rackup -p 4567
#
# 站点会运行在 http://localhost:4567

# ----
# ## 整体思路说明
# 1. 第一次验证通过后，我们需要把验证信息对应用户在本地存一下，并设定过期时间
# 2. 这个信息用cookie的形式让用户也存着
# 3. 如果过期了，我们要求用户再去验证，如果没有过期.就继续允许用户访问
# 4. 由于kidslib网站没有任何地方让用户个性化和保存个人设置，因此我们根本不需要得到用户名等信息。只需确保ticket没有过期。
# 5. 每次用户访问一个页面，在本地的db中延长一下ticket过期时间

# ----
# ## sinatra全局设定
# URI.encode_www_form([['AppId', 'kidslib'], ['server', 'http://0.0.0.0:4567']])
configure do
  # set :bind, '192.168.103.99' # http://stackoverflow.com/questions/16832472/ruby-sinatra-webservice-running-on-localhost4567-but-not-on-ip
  enable :sessions # all request will have session either we set it or rack:session sets it automatically
  set :site_url, 'http://0.0.0.0:9292'
  set :session_valid_for, 60 * 10 # 单位是秒
  set :sso_server, 'http://218.245.2.174:8080/ssoServer'
  set :app_id, 'kidslib'
end

# ----
# ## 站点帮助函数
helpers do

  # 单线程跑这个程序，内存中就会持久化这个DB
  # 之前测试不行是因为每次请求 shotgun 都重新载入这个文件
  DB = {}

  # ----
  # 对外暴露的函数
  def save_ticket(ticket)
    DB[ticket] = Time.now.to_i
  end

  def valid?(ticket)
    !expired?(ticket) || (redirect '/login')
  end

  # ----
  # 帮助函数
  def expired?(ticket)
    ticket?(ticket) && (Time.now.to_i - timestamp(ticket) > settings.session_valid_for)
  end

  def ticket?(ticket)
    DB[ticket] || remote_ticket?(ticket)
  end

  # ----
  # 验证ticket
  # http://sso.server.ip.address/ssoServer/serviceValidate
  # 需要参数是 service 和  ticket
  def remote_ticket?(ticket)
    true
    #HTTP.get "#{settings.sso_server}/serviceValidate"
  end

  def timestamp(ticket)
    DB[ticket].to_i # 如果 DB[ticket] 的值是 nil，会转为数字0，好让 expired? 函数做时间上的加减。
  end

  def extend_ticket_time(ticket)
    DB[ticket] = Time.now.to_i + settings.session_valid_for
  end

  def delete_ticket(ticket)
    DB.delete ticket # 本地不需要删除
  end

end # 帮助函数结束

before '/*.html' do
  if valid? session['ticket']
    pass
  else
    redirect '/login'
  end
end

get '/' do
  redirect '/index.html'
end

get '/login' do
  redirect "#{settings.sso_server}/login?AppId=#{settings.app_id}&service=#{settings.site_url}/set-session"
end

get '/logout' do
  delete_ticket session['ticket'] && session.clear
  redirect "#{settings.sso_server}/logout?url=kidslib"
end

# ----
# ## 设置session
# 登陆service在正常登陆后会在返回地址带上ticket
# 例如:http://xxx/yyy.asp?ticket=qweury03432432423ktjgj)
get '/set-session' do
  ticket = params['ticket']
  if remote_ticket? ticket
    session['ticket'] = ticket
    save_ticket ticket
    "#{ticket}"
    #redirect '/'
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
    '没找到请求的资源。试试其它的？'
  end
end
