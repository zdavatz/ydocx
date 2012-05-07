#!/usr/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'htmlentities'
require 'ydocx/markup_method'

module YDocx
  class Parser
    include MarkupMethod
    attr_accessor :indecies, :images, :result, :space
    def initialize(doc, rel)
      @doc = Nokogiri::XML.parse(doc)
      @rel = Nokogiri::XML.parse(rel)
      @coder = HTMLEntities.new
      @indecies = []
      @images = []
      @result = []
      @space = '&nbsp;'
      @image_path = 'images'
      init
      if block_given?
        yield self
      end
    end
    def init
    end
    def parse
      @doc.xpath('//w:document//w:body').children.map do |node|
        case node.node_name
        when 'text'
          @result << parse_paragraph(node)
        when 'tbl'
          @result << parse_table(node)
        when 'p'
          @result << parse_paragraph(node)
        else
          # skip
        end
      end
      @result
    end
    private
    def apply_fonts(rpr, text)
      symbol = false
      unless rpr.xpath('w:rFonts').empty?
        rpr.xpath('w:rFonts').each do |font|
          if font.values.include? 'Symbol'
            symbol = true
          end
          break if symbol
        end
      end
      if symbol
        _text = ''
        text.unpack('U*').each do |char|
          _text << optional_replace(char.to_s(16))
        end
        text = _text
      end
      text
    end
    def apply_align(rpr, text)
      unless rpr.xpath('w:vertAlign').empty?
        script = rpr.xpath('w:vertAlign').first['val'].to_sym
        if script == :subscript
          text = markup(:sub, text)
        elsif script == :superscript
          if text =~ /^[0-9]$/
            text = "&sup" + text + ";"
          else
            text = markup(:sup, text)
          end
        end
      end
      text
    end
    def optional_escape(text)
      text.force_encoding('utf-8')
      # NOTE
      # :named only for escape at Builder
      text = @coder.encode(text, :named)
      text
    end
    def optional_replace(code)
      code = '0x' + code
      # NOTE
      # replace with rsemble html character ref
      # Symbol Font to HTML Character named ref
      case code
      when '0xf020' # '61472'
        ""
      when '0xf025' # '61477'
        "%"
      when '0xf02b' # '61482'
        "*"
      when '0xf02b' # '61483'
        "+"
      when '0xf02d' # '61485'
        "-"
      when '0xf02f' # '61487'
        "/"
      when '0xf03c' # '61500'
        "&lt;"
      when '0xf03d' # '61501'
        "="
      when '0xf03e' # '61502'
        "&gt;"
      when '0xf040' # '61504'
        "&cong;"
      when '0xf068' # '61544'
        "&eta;"
      when '0xf071' # '61553'
        "&theta;"
      when '0xf06d' # '61549'
        "&mu;"
      when '0xf0a3' # '61603'
        "&le;"
      when '0xf0ab' # '61611'
        "&harr;"
      when '0xf0ac' # '61612'
        "&larr;"
      when '0xf0ad' # '61613'
        "&uarr;"
      when '0xf0ae' # '61614'
        "&rarr;"
      when '0xf0ad' # '61615'
        "&darr;"
      when '0xf0b1' # '61617'
        "&plusmn;"
      when '0xf0b2' # '61618'
        "&Prime;"
      when '0xf0b3' # '61619'
        "&ge;"
      when '0xf0b4' # '61620'
        "&times;"
      when '0xf0b7' # '61623'
        "&sdot;"
      else
        #p "code : " + ("&#%s;" % code)
        #p "hex  : " + code.hex.to_s
        #p "char : " + @coder.decode("&#%s;" % code.hex.to_s)
      end
    end
    def parse_block(node)
      nil # default no block element
    end
    def parse_image(r)
      id = nil
      additional_namespaces = {
        'xmlns:a'   => 'http://schemas.openxmlformats.org/drawingml/2006/main',
        'xmlns:pic' => 'http://schemas.openxmlformats.org/drawingml/2006/picture'
      }
      ns = r.namespaces.merge additional_namespaces
      paths = {
        :id    => '//w:pict//v:shape//v:imagedata',
        :embed => '//w:drawing//wp:anchor//a:graphic//a:graphicData//pic:pic//pic:blipFill//a:blip'
      }.each do |attr, path|
        if image = r.xpath(path, ns) and !image.empty?
          id = image.first[attr.to_s]
        end
      end
      if id
        @rel.xpath('/').children.each do |element|
          element.children.each do |rel|
            if rel['Id'] == id and rel['Target']
              target = rel['Target']
              source = @image_path + '/'
              if defined? Magick::Image and
                 ext = File.extname(target).match(/\.wmf$/).to_a[0]
                source << File.basename(target, ext) + '.png'
              else
                source << File.basename(target)
              end
              @images << {
                :origin => target,
                :source => source
              }
              return markup :img, [], {:src => source}
            end
          end
        end
      end
      nil
    end
    def parse_paragraph(node)
      content = []
      if block = parse_block(node)
        content << block
      else # as p
        pos = 0
        node.xpath('w:r').each do |r|
          unless r.xpath('w:t').empty?
            content << parse_text(r, (pos == 0)) # rm indent
            pos += 1
          else
            unless r.xpath('w:tab').empty?
              if content.last != @space and pos != 0 # ignore tab at line head
                content << @space
                pos += 1
              end
            end
            unless r.xpath('w:sym').empty?
              code = r.xpath('w:sym').first['char'].downcase # w:char
              content << optional_replace(code)
              pos += 1
            end
            if !r.xpath('w:pict').empty? or !r.xpath('w:drawing').empty?
              content << parse_image(r)
            end
          end
        end
      end
      content.compact!
      unless content.empty?
        paragraph = content.select do |c|
          c.is_a?(Hash) and c[:tag].to_s =~ /^h[1-9]/u
        end.empty?
        if paragraph
          markup :p, content
        else
          content.first
        end
      else
        {}
      end
    end
    def parse_table(node)
      table = markup :table
      node.xpath('w:tr').each do |tr|
        cells = markup :tr
        tr.xpath('w:tc').each do |tc|
          attributes = {}
          tc.xpath('w:tcPr').each do |tcpr|
            if span = tcpr.xpath('w:gridSpan') and !span.empty?
              attributes[:colspan] = span.first['val'] # w:val
            end
          end
          cell = markup :td, [], attributes
          tc.xpath('w:p').each do |p|
            cell[:content] << parse_paragraph(p)
          end
          cells[:content] << cell
        end
        table[:content] << cells
      end
      table
    end
    def parse_text(r, lstrip=false)
      text = r.xpath('w:t').map(&:text).join('')
      text = optional_escape(text)
      text = text.lstrip if lstrip
      if rpr = r.xpath('w:rPr')
        text = apply_fonts(rpr, text)
        text = apply_align(rpr, text)
        unless rpr.xpath('w:u').empty?
          text = markup(:span, text, {:style => "text-decoration:underline;"})
        end
        unless rpr.xpath('w:i').empty?
          text = markup(:em, text)
        end
        unless rpr.xpath('w:b').empty?
          text = markup(:strong, text)
        end
      end
      text
    end
  end
end
