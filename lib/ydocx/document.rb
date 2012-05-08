#!/usr/bin/env ruby
# encoding: utf-8

require 'pathname'
require 'zip/zip'
begin
  require 'RMagick'
rescue LoadError
  warn "Couldn't load RMagick: .wmf conversion off"
end
require 'ydocx/parser'
require 'ydocx/builder'

module YDocx
  class Document
    attr_reader :contents, :indecies, :images
    def self.open(file, options={})
      self.new(file, options)
    end
    def initialize(file, options={})
      @contents = nil
      @indecies = nil
      @images = []
      @options = options
      @path = nil
      @files = nil
      @zip = nil
      init
      read(file)
    end
    def init
    end
    def to_html(file='', options={})
      html = ''
      options = @options.merge(options)
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
        create_files if has_image?
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
      options = @options.merge(options)
      Builder.new(@contents) do |builder|
        builder.block = options.has_key?(:block) ? options[:block] : :chapter
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
    def create_files
      FileUtils.mkdir @files unless @files.exist?
      @zip = Zip::ZipFile.open(@path.realpath)
      @images.each do |image|
        origin_path = Pathname.new image[:origin] # media/filename.ext
        source_path = Pathname.new image[:source] # images/filename.ext
        dir = @files.join source_path.dirname
        FileUtils.mkdir dir unless dir.exist?
        organize_image(origin_path, source_path)
      end
      @zip.close
    end
    def organize_image(origin_path, source_path)
      binary = @zip.find_entry("word/#{origin_path}").get_input_stream
      if source_path.extname != origin_path.extname # convert
        if defined? Magick::Image
          image = Magick::Image.from_blob(binary.read).first
          image.format = source_path.extname[1..-1].upcase
          @files.join(source_path).open('wb') do |f|
            f.puts image.to_blob
          end
        else # copy original image
          @files.join(dir, origin_path.basename).open('wb') do |f|
            f.puts binary.read
          end
        end
      else
        @files.join(source_path).open('wb') do |f|
          f.puts binary.read
        end
      end
    end
    def has_image?
      !@images.empty?
    end
    def read(file)
      @path = Pathname.new file
      @zip = Zip::ZipFile.open(@path.realpath)
      doc = @zip.find_entry('word/document.xml').get_input_stream
      rel = @zip.find_entry('word/_rels/document.xml.rels').get_input_stream
      Parser.new(doc, rel) do |parser|
        @contents = parser.parse
        @indecies = parser.indecies
        @images = parser.images
      end
      @zip.close
    end
  end
end
