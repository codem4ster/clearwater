require 'clearwater/component/html_tags'
require 'clearwater/dom_reference'

module Clearwater
  module Component
    extend self

    attr_accessor :outlet
    attr_accessor :router
    attr_writer :html_text
    def html_text
      @html_text ||= []
    end

    def sub_buffer
      @sub_buffer ||= []
    end

    def plain(text)
      html_text << text
    end

    def render_component(comp)
      html_text << comp.render
    end

    def render; end

    def self.included(includer)
      define_method :to_s do
        includer.new.render
      end
    end


    HTML_TAGS.each do |tag_name|
      define_method tag_name do |attributes = nil, &content|
        tag(tag_name, attributes, &content)
      end
    end

    def join_tags(tags)
      return tags.join if tags.kind_of? Array
      tags
    end

    def eval_content(&content)
      result = instance_eval(&content)
      return if html_text == join_tags(result)
      sub_buffer << result if result.is_a? String
      sub_buffer.concat result if result.is_a? Array
      @html_text = [html_text] if html_text.is_a? String
      html_text.concat sub_buffer
      @sub_buffer = []
    end

    def build_style(attributes)
      return attributes unless attributes[:style].is_a? Hash
      attributes[:style] = attributes[:style].map do |attr, value|
        attr = attr.to_s.tr('_', '-')
        "#{attr}:#{value}"
      end.join(';')
      attributes
    end

    def check_class_name(attributes)
      map = %i[class_name className]
      found = map.find { |cls_name| attributes.key?(cls_name) }
      return attributes unless found
      attributes[:class] ||= attributes.delete(found)
      attributes
    end

    def build_attributes(attributes)
      return attributes unless attributes.is_a? Hash

      attributes = check_class_name attributes
      attributes = build_style attributes

      attributes.reject! do |key, handler|
        key[0, 2] == 'on' || handler.is_a?(DOMReference)
      end

      attributes.map do |key, value|
        next " #{key}" if value.eql? true
        value = '"' + value + '"'
        ' ' + [key, value].join('=')
      end.join
    end

    def tag(tag_name, attributes = nil, &content)
      start_tag = "<#{tag_name}#{build_attributes(attributes)}"
      start_tag += block_given? ? '>' : '/>'
      html_text << start_tag
      if block_given?
        eval_content(&content)
        html_text << "</#{tag_name}>"
      end
      @html_text = join_tags html_text
    end

    def params
      router.params_for_path(router.current_path)
    end

    def call(&block); end
  end
end
