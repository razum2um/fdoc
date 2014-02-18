require 'sinatra/base'
require 'rack/contrib/try_static'

module Fdoc
  class Server < Sinatra::Base
    use Rack::TryStatic,
     :root => "#{::Rails.root}/public/fdoc",  # static files root dir
     :urls => %w[/],     # match all requests
     :try => ['.html', 'index.html', '/index.html'] # try these postfixes sequentially
  end
end
