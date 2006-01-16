#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

module Qwik
  class QwikError < StandardError; end
  class RequireLogin < QwikError; end
  class RequirePost < QwikError; end
  class PageNotFound < QwikError; end

  class RequireNoPathArgs < QwikError; end

  class RequireMember < QwikError; end
  class InvalidUserError < QwikError; end
  class BaseIsNotSitename < QwikError; end

  # plugin
  class NoCorrespondingPlugin < QwikError; end
end
