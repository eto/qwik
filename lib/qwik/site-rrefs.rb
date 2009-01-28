# Copyright (C) 2009 AIST, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-pathname'
require 'qwik/page-rrefs'

module Qwik
  class Site
    def rrefs(k = 'FronPage')
      page = self[k]
      return nil if page.nil?
      page.rrefs = PageRRefs.new(@path.to_s, k) if page.rrefs.nil?
      return page.rrefs
    end
  end
end
