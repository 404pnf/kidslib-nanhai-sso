# config.ru
require './server'

# sinatra add session secret by default, see sinatra README
# use Rack::Session::Cookie, :key => 'kidslib',
#                           :path => '/',
#                            :expire_after => 14400, # In seconds
#                            :secret => '3bac0be506708965eb0d37feefb6cb0'

run Sinatra::Application
