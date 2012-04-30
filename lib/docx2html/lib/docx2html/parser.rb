#!/usr/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'htmlentities'

module Docx2html
  class Parser
    def initialize(stream)
      @xml = Nokogiri::XML.parse(stream)
      @coder = HTMLEntities.new
      @container = nil
      @result = []
      init
      if block_given?
        yield self
      end
    end
    def init
    end
    def parse
      @xml.xpath('//w:document//w:body').children.map do |node|
        case node.node_name
        when 'text'
          @result << parse_paragraph(node)
        when 'tbl'
          @result << parse_table(node)
        when 'image'
          # pending
        when 'p'
          @result << parse_paragraph(node)
        else
          # skip
        end
      end
      # TODO
      #   builder?
      if @container
        @container[:content] = @result
        @result = [@container]
      end
      if before_content = build_before_content
        @result.unshift before_content
      end
      if after_content = build_after_content
        @result.push after_content
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
          text = tag(:sub, text)
        elsif script == :superscript
          text = tag(:sup, text)
        end
      end
      text
    end
    def build_after_content
      nil
    end
    def build_before_content
      nil
    end
    def build_block(r, text)
      nil #default no block element
    end
    def optional_escape(text)
      return text = '&nbsp;' if text.empty?
      text.force_encoding('utf-8')
      #NOTE
      #  :named only for escape at Builder
      text = @coder.encode(text, :named)
      text
    end
    def optional_replace(code)
      code = '0x' + code
      #NOTE
      #  replace with rsemble html character ref
      #  Symbol Font to HTML Character named ref
      case code
      when '0xf06d' # '61549'
        "&mu;"
      when '0xf0b1' # '61617'
        "&plusmn;"
      when '0xf0b2' # '61618'
        "&le";
      when '0xf0b3' # '61619'
        "&ge;"
      when '0xf0b7' # '61623'
        "&sdot;"
      else
        #p "code : " + ("&#%s;" % code)
        #p "hex  : " + code.hex.to_s
        #p "char : " + @coder.decode("&#%s;" % code)
        @coder.decode("&#%s;" % code.hex.to_s)
      end
    end
    def parse_image
      # pending
    end
    def parse_paragraph(node)
      paragraph = tag :p
      node.xpath('w:r').each do |r|
        unless r.xpath('w:t').empty?
          paragraph[:content] << parse_text(r)
        else
          unless r.xpath('w:tab').empty?
            if paragraph[:content].last != '&nbsp;' # as a space
              paragraph[:content] << optional_escape('')
            end
          end
          unless r.xpath('w:sym').empty?
            code = r.xpath('w:sym').first['char'].downcase # w:char
            paragraph[:content] << optional_replace(code)
          end
        end
      end
      paragraph
    end
    def parse_table(node)
      table = tag :table
      node.xpath('w:tr').each do |tr|
        cells = tag :tr
        tr.xpath('w:tc').each do |tc|
          attributes = {}
          tc.xpath('w:tcPr').each do |tcpr|
            if span = tcpr.xpath('w:gridSpan') and !span.empty?
              attributes[:colspan] = span.first['val'] # w:val
            end
          end
          cell = tag :td, [], attributes
          tc.xpath('w:p').each do |p|
            cell[:content] << parse_paragraph(p)
          end
          cells[:content] << cell
        end
        table[:content] << cells
      end
      table
    end
    def parse_text(r)
      text = r.xpath('w:t').map(&:text).join('')
      text = optional_escape(text)
      if rpr = r.xpath('w:rPr')
        text = apply_fonts(rpr, text)
        if block = build_block(r, text)
          block
        else
          text = apply_align(rpr, text)
          # inline tag
          unless rpr.xpath('w:u').empty?
            text = tag(:span, text, {:style => "text-decoration:underline;"})
          end
          unless rpr.xpath('w:i').empty?
            text = tag(:em, text) 
          end
          unless rpr.xpath('w:b').empty?
            text = tag(:strong, text)
          end
          text
        end
      else
        text
      end
    end
    def push
    end
    def unshift
    end
    def tag(tag, content = [], attributes = {})
      tag_hash = {
        :tag        => tag,
        :content    => content,
        :attributes => attributes
      }
      tag_hash
    end
  end
end
