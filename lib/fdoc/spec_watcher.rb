require 'json'
require 'fdoc'

module Fdoc
  module SpecWatcher
    extend ActiveSupport::Concern

    included do
      # _describe = self # RSpec::ExampleGroups::... # class
      [:get, :post, :put, :patch, :delete].each do |verb|
        send(:define_method, "#{verb}_with_fdoc") do |*params|
          @__action, @__request_params, @__env = params
          @__request_params ||= {}

          check_rails_request_spec! if @__action.is_a?(Symbol)

          if @__env
            send("#{verb}_without_fdoc", @__action, @__request_params, @__env)
          else
            send("#{verb}_without_fdoc", @__action, @__request_params)
          end

          endpoint_path = explicit_path(@__example)

          return if endpoint_path.nil? # not fdoc

          if inside_rails_controller_spec?
            if endpoint_path == true
              endpoint_path = path_regexp
            elsif endpoint_path.to_s.match(/^[^\/]/)
              endpoint_path = "#{path_regexp}-#{endpoint_path.gsub(/[^[[:alnum:]]]/, '_')}"
            end
          end

          if endpoint_path.blank?
            raise Fdoc::ValidationError.new(<<-MSG.gsub(/^ {14}/, '')
              cannot determine path for .fdoc, please, do it explicitly:
                it "tests", fdoc: 'some-fdoc-file-suffix' do
                  ...
                end
              MSG
            )
          end

          if successful = Fdoc.decide_success(response_params, real_response.status)
            @__request_params.stringify_keys! # FIXME
            @__fdoc_service.verify!(
              verb, endpoint_path, path_params.merge(extensions),
              parsed_request_params(@__request_params), response_params,
              real_response.status, successful
            )
          end
        end

        send :alias_method_chain, verb, :fdoc
      end

      around do |example|
        # _it = self # RSpec::ExampleGroups::... # instance
        @__example = example
        @__fdoc_service = if defined?(Rails)
          Fdoc::Service.new(Rails.root.join(Fdoc::DEFAULT_SERVICE_PATH).to_s, Rails.application.class.parent_name)
        else
          Fdoc::Service.default_service
        end

        example.run.tap do |result|
          unless result.is_a? Exception
            @__fdoc_service.persist! #rescue nil
          end
        end
      end
    end

    private

    def extensions
      @extensions = {
        path_info: request.env['PATH_INFO'],
        method: request.env['REQUEST_METHOD'],
        suffix: ''
      }
      if (suffix = explicit_path(@__example)).is_a?(String)
        @extensions[:suffix] = suffix.gsub(/[^[[:alnum:]]]/, '_')
      end
      @extensions
    end

    def path_regexp
      @__path_regexp ||= current_route_params.first.try(:path).try(:spec).to_s.sub('(.:format)', '')
    end

    def path_params
      @__path_params ||= current_route_params.last || {}
    end

    # ActionDispatch::Journey::Route || nil
    def current_route_params
      return [@__current_route, @__path_params] if @__current_route && @__path_params
      router.recognize(request) do |route, _, parameters|
        return [@__current_route = route, @__path_params = parameters]
      end
      [] # never?
    end

    # ActionDispatch::Journey::Router
    def router
      Rails.application.routes.router
    end

    def parsed_request_params request_params
      if request_params.kind_of?(Hash)
        request_params
      else
        begin
          JSON.parse(request_params)
        rescue
          {}
        end
      end
    end

    def explicit_path(_example=nil)
      if _example && _example.respond_to?(:metadata)
        _example.metadata[:fdoc]
      elsif defined?(::RSpec) && ::RSpec.respond_to?(:current_example) # Rspec 3
        ::RSpec.current_example.metadata[:fdoc]
      elsif respond_to?(:example) # Rspec 2
        example.metadata[:fdoc]
      else # Rspec 1.3.2
        opts = {}
        __send__(:example_group_hierarchy).each do |example|
          opts.merge!(example.options)
        end
        opts.merge!(options)
        opts[:fdoc]
      end
    end

    def check_rails_request_spec!
      return false unless @__example.metadata[:type] == :request
      unless @__example.metadata.described_class.is_a?(Class)
        raise 'cannot determine request url: provide proper described class like: "describe MyController do"'
      end
      controller_name = @__example.metadata.described_class.name.tableize.gsub(/_controllers$/, '')
      @__action = URI.parse(url_for({ controller: controller_name, action: @__action }.merge(@__request_params))).path
      true
    end

    def inside_rails_controller_spec?
      defined?(ActionController::Base) && respond_to?(:controller) && controller.is_a?(ActionController::Base)
    end

    def real_response
      if respond_to? :response
        # we are on rails
        response
      else
        # we are on sinatra
        last_response
      end
    end

    def response_params
      begin
        JSON.parse(real_response.body)
      rescue
        {}
      end
    end

  end
end

if defined?(RSpec)
  RSpec.configure do |config|
    config.include Fdoc::SpecWatcher, type: :controller
    config.include Fdoc::SpecWatcher, type: :request
  end
end
