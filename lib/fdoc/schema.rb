require 'diffy'
require 'yaml'

module Fdoc
  class Schema
    def initialize(hash)
      @hash = hash
    end

    def respond_to_missing?(method, include_private = false)
      @hash.send(:respond_to_missing?, method, include_private)
    end

    def method_missing(method, *args, &block)
      @hash.send method, *args, &block
    end

    def diff(schema)
      ::Diffy::Diff.new(
        schema.serialized_for_diff,
        serialized_for_diff,
        context: 1).to_s(:color)
    end

    protected

    def serialized_for_diff
      @serialized_for_diff ||= YAML.dump(@hash).each_line.map do |l|
        l unless l.match(/description|example/)
      end.compact.join
    end
  end
end
