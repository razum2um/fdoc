require 'sinatra/base'
require 'rack'

module Fdoc
  class Server
    # fixed rack_contrib implementation
    class TryStatic

      def initialize(app, options)
        @app = app
        @try = ['', *options.delete(:try)]
        @static = ::Rack::Static.new(
          Proc.new { [404, {}, []] }, # HERE proc, not lambda
          options)
      end

      def call(env)
        orig_path = env['PATH_INFO']
        found = nil
        @try.each do |path|
          resp = @static.call(env.merge!({'PATH_INFO' => orig_path + path}))
          break if 404 != resp[0] && found = resp
        end
        found or @app.call(env.merge!('PATH_INFO' => orig_path))
      end
    end

    def self.to_rack(options = {})
      default_path = options[:path] || 'lurker'

      Class.new(Sinatra::Base) do

        if !Rails.env.development? && (username, password = options.values_at(:username, :password)).all?(&:present?)
          use Rack::Auth::Basic, "Protected Area" do |u, p|
            username == u && password == p
          end
        end

        use TryStatic,
         :root => "#{::Rails.root}/#{default_path}",  # static files root dir
         :urls => %w[/],     # match all requests
         :try => ['.html', 'index.html', '/index.html'] # try these postfixes sequentially
      end
    end
  end
end
