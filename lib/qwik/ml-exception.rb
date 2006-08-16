#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

module QuickML
  class QuickMLException < StandardError; end
  class TooManyMembers < QuickMLException; end
  class InvalidMLName < QuickMLException; end
end
