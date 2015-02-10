require './server'

# config.ru (run with rackup)
run Nanhai

# run Sinatra::Application
#at_exit { File.delete 'sess.yml' }
