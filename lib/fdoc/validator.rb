require 'json-schema/validator'

class Fdoc::Validator < JSON::Validator
  def open(uri)
    Kernel.open(uri)
  rescue Errno::ENOENT
    Fdoc::JamlDescriptor.new(uri)
  end
end

