#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require "./_plugins/post_filters"

class String
  han = '\p{Han}|[，。？；：‘’“”、！……（）]'
  @@hh = /(#{han}) *\n *(#{han})/m
  @@he = /(#{han}) *\n *(\w)/m
  @@eh = /(\w) *\n *(#{han})/m
  def join_chinese!
    if m = match(@@hh)
      gsub!(@@hh,  "#{m[1]}#{m[2]}")
    end

    if m = match(@@he)
      gsub!(@@he,  "#{m[1]}#{m[2]}")
    end

    if m = match(@@eh)
      gsub!(@@eh, "#{m[1]}#{m[2]}")
    end
    self
  end
end

module Jekyll
  class JoinChineseFilter < PostFilter
    def pre_render(post)
      post.content.join_chinese!
    end
  end

  module TemplateJoinChineseFilter
    def join_chinese(input)
      input.join_chinese!
    end
  end
end

Liquid::Template.register_filter(Jekyll::TemplateJoinChineseFilter)
