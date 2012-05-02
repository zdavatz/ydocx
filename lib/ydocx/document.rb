#!/usr/bin/env ruby
# encoding: utf-8

require 'pathname'
require 'zip/zip'
require 'ydocx/parser'
require 'ydocx/builder'

module YDocx
  class Document
    attr_reader :contents, :indecies
    def self.open(file)
      self.new(file)
    end
    def initialize(file)
      @contents = nil
      @indecies = nil
      read(file)
    end
    def to_html(file='', options={})
      html = ''
      Builder.new(@contents) do |builder|
        builder.title = @path
        builder.style = options[:style] if options.has_key?(:style)
        if @indecies
          builder.indecies = @indecies
        end
        html = builder.build_html
      end
      unless file.empty?
        path = Pathname.new(file).realpath.sub_ext('.html')
        File.open(path, 'w:utf-8') do |f|
          f.puts html
        end
      else
        html
      end
    end
    def to_xml(file='', options={})
      xml = ''
      Builder.new(@contents) do |builder|
        xml = builder.build_xml
      end
      unless file.empty?
        path = Pathname.new(file).realpath.sub_ext('.xml')
        File.open(path, 'w:utf-8') do |f|
          f.puts xml
        end
      else
        xml
      end
    end
    private
    def read(file)
      @path = File.expand_path(file)
      @zip = Zip::ZipFile.open(@path)
      stream = @zip.find_entry('word/document.xml').get_input_stream
      Parser.new(stream) do |parser|
        @contents = parser.parse
        @indecies = parser.indecies
      end
      @zip.close
    end
  end
end
