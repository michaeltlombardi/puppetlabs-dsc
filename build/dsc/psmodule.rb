# rubocop:disable Style/ClassAndModuleChildren
module Dsc
  # Handle PowerShell module manifests
  class Psmodule
    attr_accessor :name
    attr_reader :module_manifest_path

    def initialize(module_name, module_manifest_path)
      @name = module_name
      @module_manifest_path = module_manifest_path
      @attributes = nil
    end

    def version
      raise "ModuleVersion not found for module #{@name} / #{@module_manifest_path}" if !attributes.key?('moduleversion') || attributes['moduleversion'].empty?
      attributes['moduleversion']
    end

    private

    def attributes
      unless @attributes
        attrs = {}
        regex = %r{^(.*) *= *['"](.*)['"] *(;)? *$}
        File.open(@module_manifest_path, 'r') do |psd1|
          content = File.read(psd1)
          utf8_encoded_content = utf8_encode_content(content)
          utf8_encoded_content.lines.each do |line|
            dos2unix(line)
            matches = regex.match(line)
            attrs[matches[1].strip.downcase] = matches[2] if matches
          end
          @attributes = attrs
        end
      end
      @attributes
    rescue => e
      raise "could not read psd1 manifest file for #{@name} / #{@module_manifest_path}: #{e}"
    end

    def utf8_encode_content(content)
      detection = CharlockHolmes::EncodingDetector.detect(content)
      CharlockHolmes::Converter.convert content, detection[:encoding], 'UTF-8'
    end

    def dos2unix(line)
      line.gsub!(%r{\r\n$}, "\n")
    end
  end
end
