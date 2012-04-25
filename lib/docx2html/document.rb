#!/usr/bin/env ruby
# encoding: utf-8

require 'pathname'
require 'zip/zip'
require 'docx2html/parser'
require 'docx2html/builder'

module Docx2html
  class Document
    attr_reader :contents
    def self.open(file)
      self.new(file)
    end
    def initialize(file)
      @path = File.expand_path(file)
      @zip = Zip::ZipFile.open(@path)
      stream = @zip.find_entry('word/document.xml').get_input_stream
      Parser.new(stream) do |parser|
        @contents = parser.parse
      end
      @zip.close
    end
    def to_html(file='')
      html = ''
      Builder.new(@contents) do |builder|
        builder.title = @path
        html = builder.build
      end
      unless file.empty?
        path = Pathname.new(file).realpath.sub_ext('.html')
        File.open(path, 'w') do |f|
          f.puts html
        end
      else
        html
      end
    end
  end
end
