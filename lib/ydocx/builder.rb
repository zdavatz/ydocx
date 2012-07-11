#!/usr/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'pathname'
require 'ydocx/markup_method'

module YDocx
  class Builder
    include MarkupMethod
    attr_accessor :contents, :container, :indecies, :references,
                  :block, :files, :style, :title
    def initialize(contents)
      @contents = contents
      @container = {}
      @indecies = []
      @references = []
      @block = :div
      @block_class = nil
      @files = Pathname.new('.')
      @style = false
      @title = ''
      init
      if block_given?
        yield self
      end
    end
    def init
    end
    def build_html
      contents = @contents
      body = compile(contents, :html)
      if @container.has_key?(:content)
        body = build_tag(@container[:tag], body, @container[:attributes])
      end
      if before = build_before_content
        body = build_tag(before[:tag], before[:content], before[:attributes]) << body
      end
      if after = build_after_content
        body << build_tag(after[:tag], after[:content], after[:attributes])
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
    def build_xml
      paragraphs = compile(@contents, :xml)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.document {
          xml.paragraphs { xml << paragraphs }
        }
      end
      builder.to_xml(:indent => 0, :encoding => 'utf-8').gsub(/\n/, '')
    end
    private
    def compile(contents, mode)
      result = ''
      headings = 0
      block_start = (@block_class ? "<#{@block} class='#{@block_class}'>" : "<#{@block}>")
      block_close = "</#{@block}>"
      contents.each do |element|
        if element[:tag].to_s =~ /^h[1-9]$/ # block
          if headings == 0
            result << block_start
          else
            result << "#{block_close}#{block_start}"
          end
          headings += 1
        end
        result << build_tag(element[:tag], element[:content], element[:attributes], mode)
      end
      result << block_close
    end
    def build_after_content
      nil
    end
    def build_before_content
      nil
    end
    def build_tag(tag, content, attributes, mode=:html)
      if tag == :br and mode != :xml
        return "<br/>"
      elsif content.nil? or content.empty?
        return '' if attributes.nil? # without img
      end
      _content = ''
      if content.is_a? Array
        content.each do |c|
          next if c.nil? or c.empty?
          if c.is_a? Hash
            _content << build_tag(c[:tag], c[:content], c[:attributes], mode)
          elsif c.is_a? String
            _content << c.chomp.to_s
          end
        end
      elsif content.is_a? Hash
        _content = build_tag(content[:tag], content[:content], content[:attributes], mode)
      elsif content.is_a? String
        _content = content
      end
      _tag = tag.to_s
      _attributes = ''
      unless attributes.empty?
        attributes.each_pair do |key, value|
          next if mode == :xml and key.to_s =~ /(id|style|colspan)/u
          if tag == :img and key == :src
            _attributes << " src=\"#{resolve_path(value.to_s)}\""
          else
            _attributes << " #{key.to_s}=\"#{value.to_s}\""
          end
        end
      end
      if mode == :xml
        case _tag.to_sym
        when :span    then _tag = 'underline'
        when :strong  then _tag = 'bold'
        when :em      then _tag = 'italic'
        when :p       then _tag = 'paragraph'
        when :h2, :h3 then _tag = 'heading'
        when :sup     then _tag = 'superscript' # text
        when :sub     then _tag = 'subscript'   # text
        end
      end
      if tag == :img
        return "<#{_tag}#{_attributes}/>"
      else
        return "<#{_tag}#{_attributes}>#{_content}</#{_tag}>"
      end
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
    def resolve_path(path)
      @files.join path
    end
  end
end
