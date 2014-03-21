require 'sinatra/base'
require 'rack'
require 'rack/contrib/try_static'

module Fdoc
  class Server
    def self.to_rack(options = {})
      default_path = options[:path] || 'lurker'

      Class.new(Sinatra::Base) do

        if (username, password = options.values_at(:username, :password)).all?(&:present?)
          use Rack::Auth::Basic, "Protected Area" do |u, p|
            username == u && password == p
          end
        end

        use Rack::TryStatic,
         :root => "#{::Rails.root}/#{default_path}",  # static files root dir
         :urls => %w[/],     # match all requests
         :try => ['.html', 'index.html', '/index.html'] # try these postfixes sequentially
      end
    end
  end
end
