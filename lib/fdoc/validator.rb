require 'json-schema/validator'

class Fdoc::Validator < JSON::Validator
  # file encoded in YAML
  # readed as dumped JSON
  # to hack `open('...json').read`
  class JamlDescriptor
    def initialize(uri)
      @uri = uri.gsub(/\#$/, '').gsub(/\.json/, '.json.yml')
      @fd = open(@uri)
    end

    def read
      @read ||= JSON.dump(YAML.load(@fd.read))
    end
  end

  def open(uri)
    Kernel.open(uri)
  rescue Errno::ENOENT
    JamlDescriptor.new(uri)
  end
end

