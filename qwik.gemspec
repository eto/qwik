# -*- ruby -*-
$:.unshift '../lib'
require 'rubygems'

spec = Gem::Specification.new do |s|
  s.name = 'qwik'
  s.version = '0.7.3'
  s.author = 'Kouichirou Eto'
  s.rubyforge_project = 'qwik'
  s.homepage = 'http://qwik.jp/qwikWeb.html'
  s.platform = Gem::Platform::RUBY
  s.summary = 'qwikWeb is a communication system integrating mailing lists and WikiWikiWeb.'
  s.files = Dir.glob('{bin,compat,data,etc,ext,lib,share,test}/**/*').delete_if {|item| item.include?('CVS')}
  s.files.concat %w(ChangeLog Makefile NEWS README)
  s.require_path = 'lib'
  s.autorequire = 'qwik/qwik'
  s.required_ruby_version = '>= 1.8.2'

  s.bindir = 'bin'
  s.executables = %w(quickml-ctl quickml-server qwikweb-adduser qwikweb-ctl qwikweb-incgen qwikweb-makesite qwikweb-server qwikweb-showpassword qwikweb-watchlog)

  #s.has_rdoc = false
  #s.extra_rdoc_files = ['README', 'Changes.rdoc']

#  s.signing_key = '/Users/chadfowler/cvs/rubygems/gem-private_key.pem'
#  s.cert_chain  = ['/Users/chadfowler/cvs/rubygems/gem-public_cert.pem']
end

if $0==__FILE__
  Gem::manage_gems
  Gem::Builder.new(spec).build
end
