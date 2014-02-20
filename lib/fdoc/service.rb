require 'yaml'

# Services represent a group of Fdoc API endpoints in a directory
class Fdoc::Service
  attr_reader :service_dir, :schema
  attr_accessor :meta_service, :opened_endpoints
  SUFFIX = '.fdoc.service'

  def self.default_service
    new(Fdoc.service_path)
  end

  def initialize(service_dir, service_name = nil)
    @name = service_name
    @opened_endpoints = []
    @service_dir = File.expand_path(service_dir)
    @schema = if persisted? && (schema = YAML.load_file(service_path)).is_a?(Hash)
      Fdoc::Schema.new(schema)
    else
      Fdoc::Schema.new({
        'name'        => name,
        'basePath'    => '',
        'description' => ''
      })
    end
  end

  def persisted?
    File.exist?(service_path)
  end

  def service_path
    @service_path ||= "#{service_dir}/#{name}#{SUFFIX}"
  end

  def persist!
    FileUtils.mkdir_p(service_dir) unless Dir.exist?(service_dir)
    File.open(service_path, "w") { |file| YAML.dump(schema, file) } unless File.exists?(service_path)
    @opened_endpoints.each { |e| e.persist! if e.respond_to? :persist! }
  end

  def self.verify!(verb, path, request_params, response_params,
                   response_status, successful)
    service = Fdoc::Service.new(Fdoc.service_path)
    endpoint = service.open(verb, path)
    endpoint.consume_request(request_params, successful)
    endpoint.consume_response(response_params, response_status, successful)
    service.persist!
    service
  end

  # copied from check_response
  def verify!(verb, path, request_params, response_params,
                   response_status, successful)
    endpoint = open(verb, path)
    endpoint.consume!(request_params, response_params, response_status, successful)
  end


  # Returns an Endpoint described by (verb, path)
  # In scaffold_mode, it will return an EndpointScaffold an of existing file
  #   or create an empty EndpointScaffold
  def open(verb, path, scaffold_mode = Fdoc.scaffold_mode?)
    endpoint_path = path_for(verb, path)

    endpoint = if File.exists?(endpoint_path)
      Fdoc::Endpoint.new(endpoint_path, self)
    else
      Fdoc::EndpointScaffold.new(endpoint_path, self)
    end
    @opened_endpoints << endpoint
    endpoint
  end

  def endpoint_paths
    Dir["#{service_dir}/**/*.fdoc"]
  end

  def endpoints
    endpoint_paths.map do |path|
      Fdoc::Endpoint.new(path, self)
    end
  end

  def path_for(verb, path)
    flat_path   = File.join(@service_dir, "#{path}-#{verb.to_s.upcase}.fdoc")
    nested_path = File.join(@service_dir, "#{path}/#{verb.to_s.upcase}.fdoc")

    if File.exist?(flat_path)
      flat_path
    elsif File.exist?(nested_path)
      nested_path
    else # neither exists, default to flat_path
      flat_path
    end
  end

  def name
    @name ||= (@schema.try(:[], 'name') ||
               Pathname.new(Dir["#{service_dir}/*#{SUFFIX}"].first.to_s).basename.to_s.gsub(SUFFIX, '').presence ||
               'application')
  end

  def base_path
    base_path = @schema['basePath']
    if base_path && !base_path.end_with?('/')
      base_path + '/'
    else
      base_path
    end
  end

  def description
    @schema['description']
  end

  def discussion
    @schema['discussion']
  end
end
