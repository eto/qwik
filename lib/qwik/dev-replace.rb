# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'pp'

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-pathname'

def dummy_replace_line(line)	# dummy
  return line
end

def replace_line(line)
  return line.gsub(/\$LOAD_PATH \<\< \'\.\.\'/) {
    "$LOAD_PATH.unshift '..'"
  }
end

def replace_content_by_line(content, dryrun)
  replace = false
  newcontent = ''
  content.each {|line|
    newline = replace_line(line)
    if newline != line
      yield
      puts "-#{line}"
      puts "+#{newline}"
      replace = true
    end
    newline = line if dryrun		# for debug
    newcontent << newline
  }
  return replace, newcontent, dryrun
end

def main
  #dryrun = false
  dryrun = true

  #Dir.glob('test-sub-*.rb') {|fname|

  last_fname = ''

  Dir.glob('*.rb') {|fname|
    next if fname == 'dev-replace.rb'
    content = open(fname, 'rb') {|f| f.read }

    replace, newcontent, dryrun = replace_content_by_line(content, dryrun) {
      if last_fname != fname
	puts "¡#{fname}"
	last_fname = fname
      end
    }

    if replace
      open("#{fname}.bak", 'wb') {|f|
	f.print content			# make backup
      }
      open(fname, 'wb') {|f|
	f.print newcontent		# make new content
      }
    end
  }
end
main

=begin

OLD_BANNER = <<"EOS"
#
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#
EOS

NEW_BANNER = <<"EOS"
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.
EOS

def replace_line(line)
  return line.gsub(OLD_BANNER) {
    NEW_BANNER
  }
end

def nureplace_line(line)
  return line.gsub(%r|2003-2005|) {
    "2003-2006"
  }
end

def nu2replace_line(line)
  return line.gsub(%r|c_relative_to_absolute|) {
    "c_relative_to_root"
  }
end

def nu3replace_line(line)
  return line.gsub(%r|c_relative_to_full|) {
    "c_relative_to_absolute"
  }
end

def replace_line(line)
  return line.gsub(%r|\$LOAD_PATH \<\< '\.\.' unless \$LOAD_PATH\.include\?\('\.\.'\)|) {
    "$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'"
  }
end

def replace_line(line)
  return line.gsub(%r|\$LOAD_PATH\.unshift 'compat' unless \$LOAD_PATH\.include\? 'compat'|) {
    "$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'"
  }
end

def nu3_replace_line(line)
  return line.gsub(%r|\$LOAD_PATH\.unshift\('\.\.\/\.\.\/compat'\) unless \$LOAD_PATH\.include\?\('\.\.\/\.\.\/compat'\)|) {
    "$LOAD_PATH.unshift 'compat' unless $LOAD_PATH.include? 'compat'"
  }
end

def nu2_replace_line(line)
  str = "\$LOAD_PATH << '..' unless \$LOAD_PATH.include?('..')"
  restr = Regexp.escape(str)
  #puts restr
  # \$LOAD_PATH\ <<\ '\.\.'\ unless\ \$LOAD_PATH\.include\?\('\.\.'\)
  re = Regexp.compile(restr)
  out = "\$LOAD_PATH << '..' unless \$LOAD_PATH.include? '..'"
  return line.gsub(re) {
    out
  }
end

def nu_replace_line(line)
  return line.gsub(%r|\$LOAD_PATH << \'\.\./\.\./lib\' unless \$LOAD_PATH\.include\?\('\.\./\.\./lib'|) {
    "\$LOAD_PATH << '..' unless \$LOAD_PATH.include?('..'"
  }
end


# ============================== souko
def nu_replace_line(line)
  return line.gsub(/require \"t\/test\"/) {
    "require \"qwik\/test-common\""
  }
end

def nu2replace_line(line)
  return line.gsub(/class TC\_/) {
    'class Test'
  }
end

def nu3replace_line(line)
  return line.gsub(/if \$debug/) {
    'if defined?($debug) && $debug'
  }
end

def nu4replace_line(line)
  return line.gsub(/assert_wiki/) {
    'ok_wi'
  }
end

def nu5replace_line(line)
  return line.gsub(/assert_in\(/) {
    'ok_in('
  }
end

def nu6replace_line(line)
  return line.gsub(/assert_xpath/) {
    'ok_xp'
  }
end

def nu7replace_line(line)
  return line.gsub(/assert_equal/) {
    'ok_eq'
  }
end

def nu8replace_line(line)
  return line.gsub(/require \"test\/unit\"/) {
    "require \"qwik\/testunit\""
  }
end

def nu9replace_line(line)
  return line.gsub(/assert_xml/) {
    'ok_in'
  }
end

def nu10replace_line(line)
  return line.gsub(/require \"qwik\/memory\"/) {
    "require \"qwik\/server-memory\""
  }
end

def nu11replace_line(line)
  return line.gsub(/include TestQuickMLModule/) {
    'include TestModuleML'
  }
end

def nu12replace_line(line)
  return line.gsub(/include TestMLSessionModule/) {
    'include TestModuleML'
  }
end

def nu13replace_line(line)
  return line.gsub(/require \"qwik\/test-module-ms\"/) {
    "require \"qwik/test-module-ml\""
  }
end

def nu14replace_line(line)
  return line.gsub(/user@e.com/) {
    'bob@example.net'
  }
end

def nu15replace_line(line)
  return line.gsub(/Mail\.send_mail/) {
    'Sendmail.send_mail'
  }
end

def nu16replace_line(line)
  return line.gsub(/class QuickML$/) {
    'class Group'
  }
end

def nu17replace_line(line)
  return line.gsub(/QuickML::QuickML/) {
    'QuickML::Group'
  }
end

def nu18replace_line(line)
  return line.gsub(/QuickML\./) {
    "Group\."
  }
end

def nu19replace_line(line)
  return line.gsub(/require "qwik\/util-path"/) {
    'require "qwik/util-pathname'
  }
end

def nu20replace_line(line)
  return line.gsub(/require "qwik\/util-pathname$/) {
    'require "qwik\/util-pathname"'
  }
end

def nu21replace_line(line)
  return line.gsub(/require "qwik\\\/util-pathname"/) {
    'require "qwik/util-pathname"'
  }
end

def nu22replace_line(line)
  return line.gsub(/Qwik::Config.new\(true\)/) {
    'Qwik::Config.new(:debug=>true)'
  }
end

def nu23replace_line(line)
  if /\$debug/ =~ line
    pp line
  end
  return line
end

def nu24replace_line(line)
  return line.gsub(/\$debug/) {
    '$test'
  }
end

def nu25replace_line(line)
# return line.gsub(/charset='([\w]+)'/) {
#  return line.gsub(/charset='([\w-]+)'/) {
  #a = 'charset'
  #a = 'filename'
  #a = 'boundary'
  #return line.gsub(/#{a}='([\w\.-]+)'/) {

  return line.gsub(/; ([A-Za-z]+)='([\w \.-]+)'/) {
    k = $1
    v = $2
    "; #{k}=\"#{v}\""
  }
end

def nu27replace_line(line)
  return line.gsub(%r|"../../lib"|) {
    "'../../lib'"
  }
end

def nu28replace_line(line)
  return line if line.include?("\\")
  return line.gsub(%r|""|) {
    "''"
  }
end

def nu29replace_line(line)
  return line if line.include?("\\")
  return line if line.include?('<')
  return line if line.include?('>')

  line =  line.gsub(/\"(.*?)\"/) {
    str = $1
    ignore = %w(ascii section EOT)
    if ignore.include?(str)
      "\"#{str}\""
#   elsif /\A[A-Za-z0-9\:\.\/_ |-]+\z/ =~ str
#   elsif /\A[A-Za-z0-9\:\._ |-]+\z/ =~ str
#   elsif /\A[A-Za-z0-9\@\:\._ |-]+\z/ =~ str
#   elsif /\A[A-Za-z0-9\%\*\/\@\:\._ |-]+\z/ =~ str
#   elsif /\A[A-Za-z0-9\%\*\/\@\:\._ |-]+\z/ =~ str
    elsif /\A[A-Za-z0-9\,\%\*\/\@\:\._ \|-]+\z/ =~ str
      "'#{str}'"
    else
      "\"#{str}\""
    end
  }

  return line
end

def replace_line(line)
  return line.gsub(%r|assert_text\(\'(.+)\', \'title\'\)|) {
    "ok_title('#{$1}')"
  }
end

=end
