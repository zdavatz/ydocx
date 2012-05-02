#!/usr/bin/env ruby
# encoding: utf-8

module YDocx
  module MarkupMethod
    def markup(tag, content = [], attributes = {})
      tag_hash = {
        :tag        => tag,
        :content    => content,
        :attributes => attributes
      }
      tag_hash
    end
  end
end
