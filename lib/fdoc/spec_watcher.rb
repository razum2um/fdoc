require 'json'
require 'fdoc'

module Fdoc
  module SpecWatcher
    extend ActiveSupport::Concern

    included do
      # _describe = self # RSpec::ExampleGroups::... # class
      [:get, :post, :put, :patch, :delete].each do |verb|
        send(:define_method, "#{verb}_with_fdoc") do |*params|
          action, request_params = params

          send("#{verb}_without_fdoc", *params)

          endpoint_path = path(@example)
          if endpoint_path == true && inside_rails_controller_spec?
            action, _params = params
            endpoint_path, _ = Rails.application.routes.generate_extras({
              controller: described_class.to_s.gsub(/Controller$/, '').tableize,
              action: action
            }.merge(_params))
          end
          check_response(@fdoc_service, verb, request_params, endpoint_path) if endpoint_path
        end

        send :alias_method_chain, verb, :fdoc
      end

      around do |example|
        # _it = self # RSpec::ExampleGroups::... # instance
        @example = example
        @fdoc_service = if defined?(Rails)
          Fdoc::Service.new(Rails.root.join(Fdoc::DEFAULT_SERVICE_PATH).to_s, Rails.application.class.parent_name)
        else
          Fdoc::Service.default_service
        end

        example.run.tap do |result|
          unless result.is_a? Exception
            @fdoc_service.persist! #rescue nil
          end
        end
      end
    end

    private

    def check_response(service, verb, request_params, endpoint_path)
      successful = Fdoc.decide_success(response_params, real_response.status)
      service.verify!(verb, endpoint_path, parsed_request_params(request_params), response_params,
                      real_response.status, successful)
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

    def path(_example=nil)
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

    def inside_rails_controller_spec?
      defined?(ActionController::Base) && described_class.is_a?(Class) && described_class.ancestors.include?(ActionController::Base)
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
  end
end
