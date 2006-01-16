# Trap all method definitions.
#
# Copyright (c) 2001, 2002 Robert Feldt, robert_feldt@computer.org
#
$method_def_handlers = Array.new

def trap_method_definitions(aProc)
  $method_def_handlers.push aProc unless $method_def_handlers.include?(aProc)
end

def untrap_method_definitions(aProc)
  $method_def_handlers.delete aProc
end

class Object
  def Object.method_added(id)
    $method_def_handlers.each do |p| 
      p.call(id, self)
    end
  end

  @@defining_method_added = false
  @@defining_singleton_method_added = false

  # deep magic so that we are reasonably sticky. We won't be notified
  # if Object.singleton_method_added is overridden though. I haven't
  # found away around that. Please mail me if you do!
  def Object.singleton_method_added(methodId)
    if methodId == :method_added
      if @@defining_method_added
	@@defining_method_added = false
      else
	@@defining_method_added = true
	self.instance_eval <<-'EOC'
	  alias new_method_added method_added
	  def method_added(id)
	    new_method_added(id)
	    $method_def_handlers.each do |p| 
	      p.call(id, self)
	    end
	  end
        EOC
      end
    end
  end
end

