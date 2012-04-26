#!/usr/bin/env ruby
# encoding: utf-8

require 'nokogiri'

module Docx2html
  class Builder
    attr_accessor :title, :style
    def initialize(body)
      @title = ''
      @style = false
      @body = body
      if block_given?
        yield self
      end
    end
    def build
      body = ''
      @body.each do |e|
        body << _build(e[:tag], e[:content], e[:attributes]).to_s
      end
      builder = Nokogiri::HTML::Builder.new do |doc|
        doc.html {
          doc.head {
            doc.meta :charset => 'utf-8'
            doc.title @title
            doc.style { doc << style } if @style
          }
          doc.body { doc << body }
        }
      end
      builder.to_html.gsub(/\n/, '')
    end
    def _build(tag, content, attributes)
      return '' if content.empty?
      _content = ''
      if content.is_a? Array
        content.each do |c|
          next if c.nil? or c.empty?
          if c.is_a? Hash
            _content << _build(c[:tag], c[:content], c[:attributes])
          elsif c.is_a? String
            _content << c.chomp.to_s
          end
        end
      elsif content.is_a? Hash
        _content = _build(content[:tag], content[:content], content[:attributes])
      elsif content.is_a? String
        _content = content
      end
      _tag = tag.to_s
      _attributes = ''
      unless attributes.empty?
        attributes.each_pair do |k, v|
          _attributes << " #{k.to_s}=#{v.to_s}"
        end
      end
      "<#{_tag}#{_attributes}>#{_content}</#{_tag}>"
    end
    def style
      style = <<-CSS
table, tr, td {
  border-collapse: collapse;
  border:          1px solid gray;
}
table {
  margin: 3px;
}
td {
  padding: 3px 5px;
}
      CSS
      style
    end
  end
end
