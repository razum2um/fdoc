require 'json'

module Fdoc
  module SpecWatcher
    extend ActiveSupport::Concern

    included do
      # _describe = self # RSpec::ExampleGroups::... # class
      around do |example|
        # _it = self # RSpec::ExampleGroups::... # instance
        fdoc_service = Fdoc::Service.default_service
        [:get, :post, :put, :patch, :delete].each do |verb|
          self.class.send(:define_method, "#{verb}_with_fdoc") do |*params|
            action, request_params = params

            send("#{verb}_without_fdoc", *params)

            check_response(fdoc_service, verb, request_params, example)
          end

          self.class.send :alias_method_chain, verb, :fdoc
        end

        example.run.tap do |result|
          if result == true
            fdoc_service.persist! #rescue nil
          end
        end
      end
    end

    private

    def check_response(service, verb, request_params, example=nil)
      successful = Fdoc.decide_success(response_params, real_response.status)
      service.verify!(verb, path(example), parsed_request_params(request_params), response_params,
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

    def path(example=nil)
      if example && example.respond_to?(:metadata)
        example.metadata[:fdoc]
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
