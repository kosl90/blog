#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require "./_plugins/post_filters"

class String
  han = '\p{Han}|[，。？；：‘’“”、！……（）]'
  @@hh = /(#{han}) *\n *(#{han})/m
  @@he = /(#{han}) *\n *(\p{Alpha})/m
  @@eh = /(\p{Alpha}) *\n *(#{han})/m
  def join_chinese!
    gsub!(@@hh, '\1\2')
    gsub!(@@he, '\1\2')
    gsub!(@@eh, '\1\2')
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
