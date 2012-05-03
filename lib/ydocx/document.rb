#!/usr/bin/env ruby
# encoding: utf-8

require 'pathname'
require 'zip/zip'
require 'ydocx/parser'
require 'ydocx/builder'

module YDocx
  class Document
    attr_reader :contents, :indecies, :pictures
    def self.open(file)
      self.new(file)
    end
    def initialize(file)
      @contents = nil
      @indecies = nil
      @pictures = []
      @path = nil
      @files = nil
      @zip = nil
      read(file)
    end
    def to_html(file='', options={})
      html = ''
      @files = @path.dirname.join(@path.basename('.docx').to_s + '_files')
      Builder.new(@contents) do |builder|
        builder.title = @path.basename
        builder.files = @files
        builder.style = options[:style] if options.has_key?(:style)
        if @indecies
          builder.indecies = @indecies
        end
        html = builder.build_html
      end
      unless file.empty?
        create_files if has_picture?
        html_file = @path.sub_ext('.html')
        File.open(html_file, 'w:utf-8') do |f|
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
        xml_file = @path.sub_ext('.xml')
        File.open(xml_file, 'w:utf-8') do |f|
          f.puts xml
        end
      else
        xml
      end
    end
    private
    def has_picture?
      !@pictures.empty?
    end
    def create_files
      FileUtils.mkdir @files unless @files.exist?
      @zip = Zip::ZipFile.open(@path.realpath)
      @pictures.each do |pic|
        pic_path = Pathname.new pic # id/filename.ext
        pic_dir = @files.join pic_path.dirname
        FileUtils.mkdir pic_dir unless pic_dir.exist?
        binary = @zip.find_entry("word/media/#{pic_path.basename}").get_input_stream
        @files.join(pic_path).open('w') do |f|
          f.puts binary.read
        end
      end
      @zip.close
    end
    def read(file)
      @path = Pathname.new file
      @zip = Zip::ZipFile.open(@path.realpath)
      doc = @zip.find_entry('word/document.xml').get_input_stream
      ref = @zip.find_entry('word/_rels/document.xml.rels').get_input_stream
      Parser.new(doc, ref) do |parser|
        @contents = parser.parse
        @indecies = parser.indecies
        @pictures = parser.pictures
      end
      @zip.close
    end
  end
end
