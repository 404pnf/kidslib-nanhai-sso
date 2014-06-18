require './server'

run Sinatra::Application

#at_exit { File.delete 'sess.yml' }
