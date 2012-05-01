#!/usr/bin/env ruby
# encoding: utf-8

module Docx2html
  module HtmlMethods
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
