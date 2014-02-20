require 'yaml'
require 'json-schema'

# Endpoints represent the schema for an API endpoint
# The #consume_* methods will raise exceptions if input differs from the schema
class Fdoc::Endpoint

  attr_reader :schema, :service, :endpoint_path, :current_scaffold, :extensions
  attr_accessor :errors

  def initialize(endpoint_path, extensions={}, service=Fdoc::Service.default_service)
    @endpoint_path = endpoint_path
    @extensions = extensions
    @schema = Fdoc::Schema.new(
      YAML.load_file(@endpoint_path),
      stringify_keys(extensions)
    )
    @service = service
    @errors = []
    @current_scaffold = Fdoc::EndpointScaffold.new(
      "#{endpoint_path}.new", extensions, service
    )
  end

  def consume!(request_params, response_params, status_code, successful=true)
    consume_request(request_params, successful)
    consume_response(response_params, status_code, successful)
    raise_errors!
  end

  def consume_request(params, successful=true)
    if successful
      unless validate(request_parameters, params, 'Request')
        current_scaffold.consume_request(params, successful)
      end
    end
  end

  def consume_response(params, status_code, successful=true)
    response_code = response_codes.find do |rc|
      rc["successful"] == successful && (
        rc["status"]      == status_code || # 200
        rc["status"].to_i == status_code    # "200 OK"
      )
    end


    if !response_code
      raise Fdoc::UndocumentedResponseCode,
        'Undocumented response: %s, successful: %s' % [
          status_code, successful
        ]
    elsif successful
      unless validate(response_parameters, params, 'Response')
        current_scaffold.consume_response(params, status_code, successful)
      end
    else
      true
    end
  end

  def verb
    @verb ||= endpoint_path.match(/([A-Z]*)\.fdoc$/)[1]
  end

  def path
    @path ||= endpoint_path.
                gsub(service.service_dir, "").
                match(/\/?(.*)[-\/][A-Z]+\.fdoc/)[1]
  end

  def url_params
    @url_params ||= schema.extensions.except(
      "format", "controller", "action", "path_info", "method"
    )
  end

  # properties

  def deprecated?
    @schema["deprecated"]
  end

  def description
    @schema["description"]
  end

  def request_parameters
    @schema["requestParameters"] ||= {}
  end

  def response_parameters
    @schema["responseParameters"] ||= {}
  end

  def response_codes
    @schema["responseCodes"] ||= []
  end

  protected

  def validate(expected_params, given_params, prefix=nil)
    schema = set_additional_properties_false_on(expected_params.dup)
    unless (_errors = JSON::Validator.fully_validate(schema, stringify_keys(given_params))).empty?
      self.errors << prefix
      _errors.each { |e| self.errors << "- #{e}" }
      return false
    end
    true
  end

  def raise_errors!
    unless errors.empty?
      raise Fdoc::ValidationError.new((
        errors +
        ['Diff', current_scaffold.schema.diff(schema)]
      ).join("\n"))
    end
  end

  # default additionalProperties on objects to false
  # create a copy, so we don't mutate the input
  def set_additional_properties_false_on(value)
    if value.kind_of? Hash
      copy = value.dup
      if value["type"] == "object" || value.has_key?("properties")
        copy["additionalProperties"] ||= false
      end
      value.each do |key, hash_val|
        unless key == "additionalProperties"
          copy[key] = set_additional_properties_false_on(hash_val)
        end
      end
      copy
    elsif value.kind_of? Array
      copy = value.map do |arr_val|
        set_additional_properties_false_on(arr_val)
      end
    else
      value
    end
  end

  def stringify_keys(obj)
    case obj
    when Hash
      result = {}
      obj.each do |k, v|
        result[k.to_s] = stringify_keys(v)
      end
      result
    when Array then obj.map { |v| stringify_keys(v) }
    else obj
    end
  end
end
