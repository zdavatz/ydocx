#!/usr/bin/env ruby
# encoding: utf-8

require 'nokogiri'

module Docx2html
  class Parser
    def initialize(stream)
      @xml = Nokogiri::XML(stream)
      if block_given?
        yield self
      end
    end
    def parse
      result = []
      @xml.xpath('//w:document//w:body').children.map do |node|
        case node.node_name
        when 'text'
          result << parse_paragraph(node)
        when 'tbl'
          result << parse_table(node)
        when 'image'
          # pending
        when 'p'
          result << parse_paragraph(node)
        else
          # skip
        end
      end
      result
    end
    private
    def tag(tag, content = [], attributes = {})
      tag_hash = {
        :tag        => tag,
        :content    => content,
        :attributes => attributes
      }
      tag_hash
    end
    def parse_text(r)
      text = r.xpath('w:t').map(&:text).join('')
      if rpr = r.xpath('w:rPr')
        unless rpr.xpath('w:i').empty?
          text = tag(:em, text) 
        end
        unless rpr.xpath('w:b').empty?
          text = tag(:strong, text)
        end
      end
      text
    end
    def parse_paragraph(node)
      paragraph = tag :p
      node.xpath('w:r').each do |r|
        paragraph[:content] << parse_text(r)
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
              attributes[:colspan] = span.first['val'] # x w:val
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
    def parse_image
      # pending
    end
  end
end
