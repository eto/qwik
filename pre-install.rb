# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

FILETYPES[3] = 'share'
FILETYPES[4] = 'etc'
alias install_dir_share install_dir_data
alias install_dir_etc install_dir_conf
@config['datadir'] += '/qwik'
@config['sysconfdir'] += '/qwik'
