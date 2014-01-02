require 'sinatra'
require 'pstore'

# 1. 第一次验证通过后，我们需要把验证信息对应用户在本地存一下，并设定过期时间
# 2. 这个信息用cookie的形式让用户也存着
# 3. 如果过期了，我们要求用户再去验证，如果没有过期.就继续允许用户访问
# 4. 由于kidslib网站没有任何地方让用户个性化和保存个人设置，
#    因此我们根本不需要得到用户名等信息。
#    只需确保ticket没有过期。
# 5. 每次用户访问一个页面，在本地的db中延长一下ticket过期时间

configure do
  enable :sessions
  set :site_url, 'http://0.0.0.0/'
  set :session_valid_for, 60 * 1 # 60 minutes
  set :sso_server, 'http://sso.server.ip'
end

helpers do

  TICKET_DB = PStore.new('sessions.pstore')

  def logged_in?(ticket)
    valid?(ticket) ? true : false
  end

  def has_ticket?(ticket)
    TICKET_DB.transaction { TICKET_DB.fetch(ticket, nil) }
  end

  def delete_ticket(ticket)
    TICKET_DB.transaction { TICKET_DB.delete(ticket) }
  end

  def save_ticket(ticket)
    TICKET_DB.transaction { TICKET_DB[ticket] = Time.now.to_i }
  end

  def extend_ticket_time(ticket)
    TICKET_DB.transaction { TICKET_DB[ticket] = Time.now.to_i + settings.session_valid_for }
  end

  def expired?(ticket)
    Time.now.to_i - has_ticket?(ticket) > settings.session_valid_for
  end

  def valid?(ticket)
    if has_ticket?(ticket) && !expired?(ticket)
      extend_ticket_time ticket
      true
    else
      delete_ticket(ticket)
      false
    end
  end

end

before '/ebooklist/*' do
  if valid? session['ticket'] # valid? session['ticket']
    pass
  else
    redirect '/login'
  end
end

get '/' do

  # redirect '/index.html'
end

# 1 直接登录 sso 的地址(假设未登录任何子系统,可以直接到本入口地址进行登录,登录后 再自动跳转回指定的子系统)
# 接口地址:http://sso.server.ip.address/ssoServer/login 提交给该接口的参数列表(get 形式的参数与 post 方式均可):
# 1)service:认证结束后跳转地址(希望登录成功后跳转到哪儿去的地址,
# 例如 http://xxx/yyy.asp)
# 2)AppId:子系统标识 ID(在 UCenter 中定义每个子系统的 AppId,也是 ssoServer 中的
# AppId)
# 3)signData:数据签名(用 MD5 对 service+AppId + 固定的混淆码加密)(本签名非必须)
get '/login' do
  'ready to login?'
  # redirect "http://sso.server.ip.address/ssoServer/login?AppId=kidslib;service:#{settings.site_url}/set;signData=digest_msg"
end

get '/logout' do
  session.clear
  redirect '/'
end

# 本接口返回的 service 地址后面带的参数:
# ticket(ticket 会在 service 地址后自动加上,
# 例如:http://xxx/yyy.asp?Ticket=qweury03432432423ktjgj)
get '/set-session' do
  ticket = params['Ticket']
  session['ticket'] = ticket
  save_ticket ticket
  "#{has_ticket? ticket}"
  # redirect to('/')
end

get '/all-tickets' do
  TICKET_DB.transaction { TICKET_DB[ticket] = Time.now.to_i }
end

get '/*' do |path|
  File.read "html/#{path}"
end
