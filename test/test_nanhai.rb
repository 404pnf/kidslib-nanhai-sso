require_relative '../server.rb'
require 'test/unit'
require 'rack/test'

class NanhaiTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_my_default
    get '/'
    assert(last_response.body, '首页有内容')
  end

  def test_user_can_log_in_with_correct_session
  end

  # def test_session_will_expired
  #   get '/meet', :name => 'Frank'
  #   assert_equal 'Hello Frank!', last_response.body
  # end

 def test_redirect_user_not_logged_in
    get "/ebooklist/category/12/3.html"
    follow_redirect!
    assert_equal "http://example.org/login", last_request.url
    end

  def test_set_session
    get '/test/set/ticket/name'
    res = YAML.load(File.read 'sess.yml') # test的ruby运行在项目根目录下
    assert res['ticket'][:user] == 'name', '正确地存储了session信息'
  end
end
