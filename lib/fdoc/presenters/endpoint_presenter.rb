# BasePresenter for an Endpoint
class Fdoc::EndpointPresenter < Fdoc::BasePresenter
  attr_accessor :service_presenter, :endpoint, :endpoint_presenter

  def initialize(endpoint, options = {})
    super(options)
    @endpoint = endpoint
    @endpoint_presenter = self
    @service_presenter = Fdoc::ServicePresenter.new(endpoint.service)
  end

  def to_html
    @service_presenter = service_presenter
    @endpoint_presenter = self
    @params = [{
      url_params: endpoint.url_params,
      post_params: example_request.json,
    }]
    render('show')
  end

  def to_markdown
    render_erb('endpoint.md.erb')
  end

  def url(extension = ".html")
    '%s%s-%s%s' % [ options[:prefix], endpoint.path, endpoint.verb, extension ]
  end

  def title
    '%s %s - %s' % [ endpoint.verb, endpoint.path, endpoint.service.name ]
  end

  def prefix
    endpoint.prefix || endpoint.path.split("/").first
  end

  def zws_ify(str)
    # zero-width-space, makes long lines friendlier for breaking
    #str.gsub(/\//, '&#8203;/') if str
    str
  end

  def description
    render_markdown(endpoint.description)
  end

  def root_path
    URI.parse("file://#{endpoint.endpoint_path}")
  end

  def request_parameters
    Fdoc::SchemaPresenter.new(endpoint.request_parameters,
      options.merge(request: true, root_path: root_path)
    )
  end

  def response_parameters
    return if endpoint.response_parameters.empty?
    Fdoc::SchemaPresenter.new(endpoint.response_parameters, options.merge(root_path: root_path))
  end

  def response_codes
    @response_codes ||= endpoint.response_codes.map do |response_code|
      Fdoc::ResponseCodePresenter.new(response_code, options)
    end
  end

  def successful_response_codes
    response_codes.select(&:successful?)
  end

  def failure_response_codes
    response_codes.reject(&:successful?)
  end

  def example_request
    return if endpoint.request_parameters.empty?
    Fdoc::JsonPresenter.new(
      example_from_schema(endpoint.request_parameters).except(*@endpoint.url_params.keys)
    )
  end

  def example_response
    return if endpoint.response_parameters.empty?
    Fdoc::JsonPresenter.new(example_from_schema(endpoint.response_parameters, endpoint.schema))
  end

  def deprecated?
    @endpoint.deprecated?
  end

  def base_path
    zws_ify(@endpoint.service.base_path)
  end

  def path
    if (@path = @endpoint.schema.extensions.try(:[], 'path_info')).present?
      return @path
    end
    @path = @endpoint.path.gsub(/__/, ':')
    @path = @path.gsub(/-#{@end}/) if @endpoint.schema.extensions.try(:[], 'suffix').present?
    @path
  end

  def verb
    @endpoint.verb
  end

  ATOMIC_TYPES = %w(string integer number boolean null)

  def example_from_schema(schema, obj=nil)
    if schema.nil?
      return nil
    end

    type = Array(schema["type"])

    if type.any? { |t| ATOMIC_TYPES.include?(t) }
      schema["example"] || schema["default"] || example_from_atom(schema, obj)
    elsif type.include?("object") || schema["properties"]
      example_from_object(schema, obj)
    elsif type.include?("array") || schema["items"]
      example_from_array(schema, obj)
    elsif (ref_path = schema['$ref'])
      root_path = obj.respond_to?(:abs_path) ? obj.abs_path : send(:root_path)
      ref_schema = Fdoc::RefObject.new(ref_path, root_path)
      example_from_object(ref_schema.schema, ref_schema)
    else
      {}
    end
  end

  def example_from_atom(schema, obj=nil)
    type = Array(schema["type"])
    hash = schema.hash

    if type.include?("boolean")
      [true, false][hash % 2]
    elsif type.include?("integer")
      hash % 1000
    elsif type.include?("number")
      Math.sqrt(hash % 1000).round 2
    elsif type.include?("string")
      ""
    else
      nil
    end
  end

  def example_from_object(object, obj=nil)
    example = {}
    if object["properties"]
      object["properties"].each do |key, value|
        example[key] = example_from_schema(value, obj)
      end
    end
    example
  end

  def example_from_array(array, obj=nil)
    if array["items"].kind_of? Array
      example = []
      array["items"].each do |item|
        example << example_from_schema(item, obj)
      end
      example
    elsif (array["items"] || {})["type"].kind_of? Array
      example = []
      array["items"]["type"].each do |item|
        example << example_from_schema(item, obj)
      end
      example
    else
      [ example_from_schema(array["items"], obj) ]
    end
  end
end
