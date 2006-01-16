# AspectR - simple Aspect-Oriented Programming (AOP) in Ruby.
# Version 0.3.3, 2001-01-29. NOTE! API has changed somewhat from 0.2 so beware!
#
# Copyright (c) 2001 Avi Bryant (avi@beta4.com) and 
# Robert Feldt (feldt@ce.chalmers.se).
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
module AspectR
  class AspectRException < Exception; end

  class Aspect	
    PRE = :PRE
    POST = :POST

    def initialize(never_wrap = "^$ ")
      @never_wrap = /^__|^send$|^id$|^class$|#{never_wrap}/
    end

    def wrap(target, pre, post, *args)		
      get_methods(target, args).each do |method_to_wrap|
	add_advice(target, PRE, method_to_wrap, pre)
	add_advice(target, POST, method_to_wrap, post)
      end
    end

    def unwrap(target, pre, post, *args)
      get_methods(target, args).each do |method_to_unwrap|
	remove_advice(target, PRE, method_to_unwrap, pre)
	remove_advice(target, POST, method_to_unwrap , post)
      end
    end

    # Sticky and faster wrap (can't be unwrapped).
    def wrap_with_code(target, preCode, postCode, *args)
      prepare(target)
      get_methods(target, args).each do |method_to_wrap|
	target.__aop_wrap_with_code(method_to_wrap, preCode, postCode)
      end
    end
    
    def add_advice(target, joinpoint, method, advice)
      prepare(target)
      if advice
	target.__aop_install_dispatcher(method)
	target.__aop_add_advice(joinpoint, method, self, advice)
      end
    end
    
    def remove_advice(target, joinpoint, method, advice)
      target.__aop_remove_advice(joinpoint, method, self, advice) if advice
    end
    
    @@__aop_dispatch = true

    def Aspect.dispatch?
      @@__aop_dispatch
    end

    def disable_advice_dispatching
      begin
	@@__aop_dispatch = false
	yield
      ensure
	@@__aop_dispatch = true
      end
    end

    def get_methods(target, args)
      if args.first.is_a? Regexp
	if target.kind_of?(Class)
	  methods = target.instance_methods(true)
	else
	  methods = target.methods
	end
	methods = methods.grep(args.first).collect{|e| e.intern}
      else
	methods = args
      end
      methods.select {|method| wrappable?(method)}
    end

    def wrappable?(method)
      method.to_s !~ @never_wrap
    end

    def prepare(target)
      unless target.respond_to?("__aop_init")
	target.extend AspectSupport 
	target.__aop_init
      end
    end

    module AspectSupport

      def __aop_init
	if self.is_a? Class
	  extend ClassSupport
	else
	  extend InstanceSupport
	end
	@__aop_advice_methods = {}
      end
      
      def __aop_advice_list(joinpoint, method)
	method = method.to_s
	unless (method_hash = @__aop_advice_methods[joinpoint])
	  method_hash = @__aop_advice_methods[joinpoint] = {}
	end
	unless (advice_list = method_hash[method])
	  advice_list =  method_hash[method] = []
	end
	advice_list
      end

      def __aop_add_advice(joinpoint, method, aspect, advice)
	__aop_advice_list(joinpoint, method) << [aspect, advice]	
      end

      def __aop_remove_advice(joinpoint, method, aspect, advice)
	__aop_advice_list(joinpoint, method).delete_if do |asp, adv| 
	  asp == aspect && adv == advice
	end
	# Reinstall original method if there are no advices left for this meth!
	# - except that then we could have problems with singleton instances
	# of this class? see InstanceSupport#aop_alias... /AB
      end
      
      def __aop_call_advice(joinpoint, method, *args)
	__aop_advice_list(joinpoint, method).each do |aspect, advice|
	  begin
	    aspect.send(advice, method, *args)
	  rescue Exception
	    a = $!
	    raise AspectRException, "#{a.type} '#{a}' in advice #{advice}"
	  end
	end
      end

      def __aop_generate_args(method)
	arity = __aop_class.instance_method(method).arity
	if arity < 0
	  args = (0...(-1-arity)).to_a.collect{|i| "a#{i}"}.join(",")
	  args += "," if arity < -1
	  args + "*args,&block"
	elsif arity != 0
	  ((0...arity).to_a.collect{|i| "a#{i}"} + ["&block"]).join(",")
	else
	  "&block" # could be a yield in there...
	end
      end

      def __aop_generate_syntax(method)
	args = __aop_generate_args(method)
	mangled_method = __aop_mangle(method)
	call = "#{mangled_method}(#{args})"
	return args, call, mangled_method
      end
      
      def __aop_advice_call_syntax(joinpoint, method, args)
	"#{__aop_target}.__aop_call_advice(:#{joinpoint}, '#{method}', self, exit_status#{args.length>0 ? ',' + args : ''})"
      end

      def __aop_install_dispatcher(method)
	args, call, mangled_method = __aop_generate_syntax(method)      
	return if __aop_private_methods.include? mangled_method
	new_method = """
	  def #{method}(#{args})
	    return (#{call}) unless Aspect.dispatch?
	    begin
	     exit_status = nil
	     #{__aop_advice_call_syntax(PRE, method, args)}
	     exit_status = []
	     return (exit_status.push(#{call}).last)
	    rescue Exception
	     exit_status = true
	     raise
	    ensure
	     #{__aop_advice_call_syntax(POST, method, args)}
	    end
	  end
	"""	
	__aop_alias(mangled_method, method)
        __aop_eval(new_method)
      end

      def __aop_wrap_with_code(method, preCode, postCode)
	args, call, mangled_method = __aop_generate_syntax(method)      
	return if __aop_private_methods.include? mangled_method
	comma = args != "" ? ", " : ""
	preCode.gsub!('INSERT_ARGS', comma + args)
	postCode.gsub!('INSERT_ARGS', comma + args)
	new_method = """
	  def #{method}(#{args})
	    #{preCode}
	    begin
	      #{call}
	    ensure
	      #{postCode}
	    end
	  end
	"""
	__aop_alias(mangled_method, method)
        __aop_eval(new_method)
      end

    module ClassSupport
      def __aop_target
	"self.class"
      end
      
      def __aop_class
	self
      end
      
      def __aop_mangle(method)
	"__aop__#{self.object_id}_#{method.object_id}"
      end
      
      def __aop_alias(new, old, private = true)
	alias_method new, old
	private new if private
      end
      
      def __aop_private_methods
	private_instance_methods
      end
      
      def __aop_eval(text)
	begin
	class_eval text
	rescue Exception
	puts "class_eval '#{text}'"
      end
      end
    end
    
    module InstanceSupport
      def __aop_target
	"self"
      end
      
      def __aop_class
	self.class
	     end
	
	def __aop_mangle(method)
	  "__aop__singleton_#{method}"
	end
	
	def __aop_alias(new, old, private = true)
	  # Install in class since otherwise the non-dispatcher version of the class version of the method
	  # gets locked away, and  so if we wrap a singleton before wrapping its class,
	  # later wrapping the class has no effect on that singleton /AB 
	  # of course, this depends on exactly what behavior we want for inheritance... Decide for future release...
	  unless self.class.respond_to?("__aop_init")
	    self.class.extend AspectSupport 
	    self.class.__aop_init
	  end	
	  self.class.__aop_install_dispatcher(old)
	  eval "class << self; alias_method '#{new}', '#{old}'; end;"
	  eval "class << self; private '#{new}'; end" if private
	end
			       
	def __aop_private_methods
	  private_methods
	end
			       
	def __aop_eval(text)
	  instance_eval text
	end
      end
    end
  end

  # NOTE! Somewhat experimental so API will likely change on this method!
  def wrap_classes(aspect, pre, post, classes, *methods)
    classes = all_classes(classes) if classes.kind_of?(Regexp)
    classes.each {|klass| aspect.wrap(klass, pre, post, *methods)}
  end
  module_function :wrap_classes

  # TODO: Speed this up by recursing from Object.constants instead of sifting
  # through all object in the ObjectSpace (might be slow if many objects). 
  # Is there a still faster/better way?
  # NOTE! Somewhat experimental so API will likely change on this method!
  def all_classes(regexp = /^.+$/)
    classes = []
    ObjectSpace.each_object(Class) do |c|
      classes.push c if c.inspect =~ regexp
    end
    classes
  end  
end


