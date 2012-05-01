#!/usr/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'docx2html/html_methods'

module Docx2html
  class Builder
    include HtmlMethods
    attr_accessor :body, :indecies, :title,
                  :frame, :style
    def initialize(body)
      @body = body
      @container = {}
      @indecies = []
      @style = false
      @title = ''
      init
      if block_given?
        yield self
      end
    end
    def init
    end
    def build
      if @container.has_key?(:content)
        @container[:content] = @body
        @body = [@container]
      end
      if before_content = build_before_content
        @body.unshift before_content
      end
      if after_content = build_after_content
        @body.push after_content
      end
      body = ''
      @body.each do |e|
        body << build_tag(e[:tag], e[:content], e[:attributes])
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
    private
    def build_after_content
      nil
    end
    def build_before_content
      nil
    end
    def build_tag(tag, content, attributes)
      return '' if content.empty?
      _content = ''
      if content.is_a? Array
        content.each do |c|
          next if c.nil? or c.empty?
          if c.is_a? Hash
            _content << build_tag(c[:tag], c[:content], c[:attributes])
          elsif c.is_a? String
            _content << c.chomp.to_s
          end
        end
      elsif content.is_a? Hash
        _content = build_tag(content[:tag], content[:content], content[:attributes])
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
  margin: 5px 0 5px 0;
}
td {
  padding: 5px 10px;
}
      CSS
      style.gsub(/\s\s+|\n/, ' ')
    end
  end
end
