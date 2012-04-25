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
    def style
      style = <<-CSS
table, tr, td {
  border-collapse: collapse;
  border:          1px solid gray;
}
      CSS
      style
    end
    def build
      body = ''
      @body.each do |element|
        unless element[:value].empty?
          body << _build(element[:tag], element[:value]).to_s 
        end
      end
      builder = Nokogiri::HTML::Builder.new do |doc|
        doc.html {
          doc.head {
            doc.title @title
            doc.style { doc << style } if @style
          }
          doc.body { doc << body }
        }
      end
      builder.to_html.gsub(/\n/, '')
    end
    def _build(tag, value)
      return '' if value.empty?
      _value = ''
      if value.is_a? Array
        value.each do |v|
          next if v.nil? or v.empty?
          if v.is_a? Hash
            _value << _build(v[:tag], v[:value])
          else
            _value << v.chomp.to_s
          end
        end
      elsif value.is_a? Hash
        value.each_pair do |k, v|
          next if v.empty?
          _value <<  _build(k, v)
        end
      elsif value.is_a? String
        _value = value
      end
      _tag = tag.to_s
      "<#{_tag}>" + _value + "</#{_tag}>"
    end
  end
end
