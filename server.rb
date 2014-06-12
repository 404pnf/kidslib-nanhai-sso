# 如何使用
#
#      rackup
#
# 站点会运行在 http://localhost:9292

# 整体思路说明
# 1. 第一次验证通过后，我们需要把验证信息对应用户在本地存一下，并设定过期时间
# 2. 这个信息用cookie的形式让用户也存着
# 3. 如果过期了，我们要求用户再去验证，如果没有过期.就继续允许用户访问
# 4. 由于kidslib网站没有任何地方让用户个性化和保存个人设置，因此我们根本不需要得到用户名等信息。只需确保ticket没有过期。
# 5. 每次用户访问一个页面，在本地的db中延长一下ticket过期时间
# 6. 将要保护的html文件 从 public 目录移到与 server.rb 平行的html目录，且要保持目录
# 7. 在sinatra中对匹配html的路径做限制
# 8. 为了能够适合多线程的web 服务器如 thin 等，不用内存中的hash而是pstore
# 9. 站点运行时可以查看文件夹内的 sess.yml 文件，记录了用户session
# 10. 程序退出时会自动删除 sess.yml

require 'sinatra'
require 'http' # https://github.com/tarcieri/http
require 'uri'
require 'pstore'
require 'yaml/store'
require 'sanitize'

configure do
  # set :bind, '192.168.103.99' # http://stackoverflow.com/questions/16832472/ruby-sinatra-webservice-running-on-localhost4567-but-not-on-ip
  enable :sessions # all request will have session either we set it or rack:session sets it automatically
end

# 站点帮助函数
helpers do
  # true: thread safe. see pstore doc
  DB = YAML::Store.new('sess.yml', true)

  # 一些常量
  def site_url
    'http://0.0.0.0:9292'
  end

  def sso_server
    'http://218.245.2.174:8080/ssoServer'
  end

  def app_id
    'kidslib'
  end

  def cas_service
    "service=#{ site_url }/set-session"
  end

  def cas_login_url
    "#{ sso_server }/login?AppId=#{ app_id }&#{ cas_service }"
  end

  def cas_validate_url
    "#{ sso_server }/serviceValidate?#{ cas_service }&ticket="
  end

  def cas_logout_url
    "#{ sso_server }/logout?#{ cas_service }"
  end

  def session_valid_for
    60 * 10
  end # 单位是秒

  # 对外暴露的函数
  def save_ticket(ticket, name)
    DB.transaction do
      DB[ticket] = { user: Sanitize.clean(name), time: Time.now.to_i }
      DB.commit
    end
  end

  def valid?(ticket)
    valid_ticket?(ticket)
  end

  def delete_ticket(ticket)
    DB.transaction do
      DB.delete ticket
      DB.commit
    end
  end

  # 验证ticket
  # - http://sso.server.ip.address/ssoServer/serviceValidate
  # - 需要参数是 service 和  ticket
  # - 正确的话返回用户名字符串 \n\t\n\t\tzhj\n\n\n\t\n\n
  # - 不正确返回字符串 "\n\t\n\t\tticket 'ST-161-QmfeHOdqIkjfo6Wim3aa-ssoServerf' not recognized\n\t\n\n
  def remote_ticket?(ticket)
    res = HTTP.get "#{ cas_validate_url }#{ ticket }"
    status = !res.to_s['recognized']
    r = res.to_s.gsub(/\s/, '')
    save_ticket(ticket, r) if status
    status
  end

  # 帮助函数
  def valid_ticket?(ticket)
    if not_expired(ticket) # 本地或者cas服务器上有ticket有效。因为我本地设定的过期时间很可能比cas上短
      extend_ticket_time(ticket)
      true
    else
      false
    end
  end

  def not_expired(ticket)
    Time.now.to_i - timestamp(ticket) < session_valid_for # 这里是小于号啊！！！
  end

  def timestamp(ticket)
    DB.transaction(true) do # true means read-only
      DB[ticket] ? DB[ticket][:time].to_i : 0
    end
  end

  def extend_ticket_time(ticket)
    DB.transaction do
      DB[ticket][:time] = Time.now.to_i
      DB.commit
    end
  end

end # 帮助函数结束

# 截获所有要求访问html的请求。
# 如果已经有了该html的静态文件在public
# 则无法截获
# sinatra的规则是先探测静态文件再到路由
before '/*.html' do
  if valid?(session['ticket'])
    pass
  else
    redirect '/login'
  end
end

# 路由
get '/' do
  redirect '/index.html'
end

get '/login' do
  redirect cas_login_url
end

get '/logout' do
  delete_ticket(session['ticket']) && session.clear
  redirect cas_logout_url
end

# ## 设置session
# - 登陆service在正常登陆后会在返回地址带上ticket
# - 例如:http://xxx/yyy.asp?ticket=qweury03432432423ktjgj)
get '/set-session' do
  ticket = params['ticket']
  r = remote_ticket?(ticket)
  if r
    session['ticket'] = ticket # 可浏览器设定session
    redirect '/'
  else
    redirect '/login'
  end
end

get '/db' do
  "#{DB.psych_to_yaml}" # DB.to_s only gives you  "#<PStore:0x000001014b54b8>"
end

get '/test/set/:ticket/:name' do
  save_ticket params[:ticket], params[:name]
end

get '/*' do |path|
  begin
    File.read "html/#{path}"
  rescue
    '没找到请求的资源。试试其它的？'
  end
end
