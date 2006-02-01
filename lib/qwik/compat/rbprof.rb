require 'aspectr'
require 'trap_method_definitions'

class Profiler < AspectR::Aspect
  def initialize
    super
    @profiling_start_time = Time.now
    @methods_being_profiled, @from_class = Array.new, Array.new
    @profile_types, @do_profiling = Array.new, true

    # Data structs for statistics gathered during profiling
    # Method invocation stack with one entry for each invocation:
    #   Time at entry, Total time in subfunctions also being logged
    @invocation_stack = [[0,0,0]]
    @method_stats = Array.new # each method: NumCalls, TotalTime, SelfTime
    @call_sites = Array.new # each method: Hash with call site counts
    @call_times = Array.new # each method: Hash with total time in method for
                            # each caller
    @arguments = Array.new # each method: hash for arg statistics

    # The user has "called" the program and the code being run at the toplevel
    add_method("toplevel".intern, :TOP)

    start
  end

  TimesClass = RUBY_VERSION < "1.7" ? Time : Process

  # Different types of profiling:
  METHOD_TIME         = (1<<1) # Time in each method
  LINE_PROFILING      = (1<<2) # Time spent on each line in method
  CALL_SITES          = (1<<3) # Count call sites
  UNIQUE_ARGUMENTS    = (1<<4) # Count number of unique arguments
  UNIQUE_ARG_INSPECTS = (1<<5) # Count number of unique argument inspects
  NORMAL = METHOD_TIME | CALL_SITES
  
  def profile?
    @do_profiling
  end

  def no_profiling
    begin
      old = @do_profiling
      @do_profiling = false
      res = yield
    ensure
      @do_profiling = old
    end
    res
  end

  def being_profiled?(methodId, classId)
    i = index_to_method(methodId, classId)
    i ? @profile_types[i] : nil
  end
  
  def index_to_method(methodId, classId)
    @methods_being_profiled.each_with_index do |m,i|
      return i if m == methodId and @from_class[i] == classId
    end
    nil
  end

  def currently_wrapping?
    @wrapping
  end

  def wrap_method(methodId, klass, profileType = NORMAL)
    no_profiling {
#     return if @wrapping or not wrappable?(methodId)
      return if (defined?(@wrapping) && @wrapping) or not wrappable?(methodId)
      begin
	@wrapping = true # Not thread safe! Use mutex...
	unless profileType == being_profiled?(methodId, klass)
	  i = add_method(methodId, klass, profileType)
	  pre_code, post_code = profiling_source_code(i, profileType)
	  wrap_with_code(klass, pre_code, post_code, methodId)
	  print "wrapped ", klass.inspect, "#", methodId.to_s, " ", @invocation_stack.length.inspect, " ", "index = #{i}\n" if $DEBUG
	end
      ensure
	@wrapping = false
      end
    }
  end
  alias profile_method wrap_method

  undef_method :wrap
  undef_method :unwrap

  def start(timeLimitInMinutes = nil)
    clear_profile
    if timeLimitInMinutes
      @time_limit_killer = Thread.new do
	sleep timeLimitInMinutes * 60
	self.stop
	STDERR.puts "Profiling ended prematurely: Reached time limit (#{timeLimitInMinutes.inspect} minutes)"
	self.unwind_invocation_stack
	STDERR.puts self.report
	exit(-1)
      end
    end
    @start_tick = TimesClass.times.utime
    enter(0) # Fake call to top level
  end

  def clear_profile
    @methods_being_profiled.length.times do |i|
      init_statistics_datastructures(i)
    end
  end

  class DummyProfiler
    def profile?; false; end
    def enter(index); end
    def enter_cs(index); end
    def enter_ua(index, *args); end
    def enter_cs_ua(index, *args); end
    def leave(index); end
    def leave_cs(index); end
  end

  def stop
#    return if @stop_tick
    return if defined?(@stop_tick) && @stop_tick
    @stop_tick = TimesClass.times.utime
    leave(0)
    $profiler = DummyProfiler.new # No more profiling even though the calls are made
    post_profiling_calculations
    self
  end

  def post_profiling_calculations
    post_calculate_arguments
  end

  def post_calculate_arguments
    @profile_types.each_with_index do |pt, i|
      if pt & UNIQUE_ARG_INSPECTS > 0
	@arguments[i] = apply_inspect_to_argument_hash(@arguments[i])
      end
    end
  end

  def apply_inspect_to_argument_hash(argHash)
    new_arg_hash = Hash.new(0)
    argHash.each do |args, count|
      new_arg_hash[args.inspect] += count
    end
    new_arg_hash
  end

  def method_name(index)
    mn, klass = @methods_being_profiled[index].id2name, @from_class[index]
    return "TOPLEVEL" if klass == :TOP
    methods = klass.public_instance_methods + 
      klass.protected_instance_methods + klass.private_instance_methods
    if methods.include?(mn)
      klass.inspect + "#" + mn
    else
      klass + "." + mn
    end
  end

  def summarize
    stop
    @total_elapsed = @stop_tick - @start_tick
    @total_logged = @invocation_stack.last[1]
    @time_in_nonprofiled = @total_elapsed - @total_logged
    if @total_logged == 0 then @total_logged = 0.001 end
    @method_stats[0][1] = @total_logged
    data = Array.new
    @method_stats.each_with_index {|t,i| data.push [method_name(i), t, i]}
    data.sort! {|a,b| b[1][2] <=> a[1][2]}
    sum = 0
    @profile = Array.new
    for d in data
      method, stat, index = d
      next if stat[0] == 0
      sum += stat[2]
      profile_entry = Array.new
      profile_entry.push index                       # 0: method index
      profile_entry.push stat[2]/@total_logged*100.0 # 1: percentage of time
      profile_entry.push sum                         # 2: cumulative seconds
      profile_entry.push stat[2]                     # 3: self seconds
      profile_entry.push stat[0]                     # 4: number of calls
      profile_entry.push stat[2]*1000/stat[0]        # 5: self msec per call
      profile_entry.push stat[1]*1000/stat[0]        # 6: total msec per call
      profile_entry.push @call_sites[index]          # 7: call sites hash
      acd, num_previous_seen = summarize_call_arguments(index)
      profile_entry.push acd                         # 8: arg count distr.
      profile_entry.push num_previous_seen           # 9: num prev. seen args
      only_empty_args = @arguments[index].keys == ["[]"]
      profile_entry.push only_empty_args             # 10: only empty args
      profile_entry.push @call_times[index]          # 11: call times hash
      profile_entry.push method                      # last: method name
      @profile.push profile_entry
    end
    @method_stats.clear
    @arguments.clear
  end

  def logged_methods
    logged_methods = Array.new
    @methods_being_profiled.length.times do |i| 
      logged_methods.push method_name(i)
    end
    logged_methods
  end

  def summarize_call_arguments(index)
    unless @profile_types[index] & UNIQUE_ARG_INSPECTS > 0 or
	@profile_types[index] & UNIQUE_ARGUMENTS > 0
      return nil, 0
    end
    counts, num_prev_seen = Hash.new(0), 0
    @arguments[index].to_a.sort {|a,b| b[1] <=> a[1]}.each do |args, cnt|
      counts[cnt] += cnt
      num_prev_seen += cnt if cnt > 1
    end
    return counts, num_prev_seen
  end

  def interleave_arrays(a, b)
    i = -1
    a.map {|e| [e, b[i+=1]]}
  end

  def inspect
    self.type.inspect + 
      (interleave_arrays(@from_class, @methods_being_profiled)).inspect
  end

  def report
    summarize
    str =  "Profiling summary\n"
    str += "*****************\n"
    str += "for profile taken: " + @profiling_start_time.inspect + "\n"
    str += "for program #{$0} with args '#{ARGV.join(' ')}'\n"
    str += "Total elapsed time: #{@total_elapsed} seconds\n"
    str += "Time spent in non-profiled methods: #{@time_in_nonprofiled} sec (#{@time_in_nonprofiled.to_f*100.0/@total_elapsed}%)\n" if @time_in_nonprofiled > 0.0
    str += "Time in profiled methods:\n"
    str += "  %%   cumulative   self       #      self    total\n"
    str += " time   seconds   seconds    calls  ms/call  ms/call  name\n"
    str += " ---------------------------------------------------------\n"
    @profile.each do |pe|
      str += "%6.2f %8.2f  %8.2f %8d " % [pe[1], pe[2], pe[3], pe[4]]
      str += "%8.2f %8.2f  %s\n" % [pe[5], pe[6], method_name(pe[0])]
      str += (call_site_str = inspect_call_sites(pe[7], pe[11]))
      str += (args_str = inspect_arguments(pe[8], pe[9], pe[10], pe[4]))
      #str += "\n" if (call_site_str != "") or (args_str != "")
    end
    return str
  end

  def inspect_call_sites(callSiteHash, callTimesHash)
    return "" if callSiteHash.length == 0
    total_time = 0.0
    callTimesHash.each do |i, time| 
      total_time += time
    end
    str = "    Call sites:\n"
    callTimesHash.to_a.sort{|a,b| b[1]<=>a[1]}.each do |cs, time|
      str += "     " + "#{callSiteHash[cs]} ".rjust(8) 
      if total_time > 0.0
	str += ("%.1f%% " % (time/total_time*100.0)).rjust(7)
      end
      str += method_name(cs) + "\n"
    end
    str
  end

  def inspect_arguments(argCountDistribution, numPrevSeen, onlyEmptyArgs,
			numCalls)
    return "" if numCalls <= 1 or onlyEmptyArgs or argCountDistribution == nil
    str = "    Arguments:\n"
    proportion_prev_seen = numPrevSeen*100.0/numCalls
    proportion_unique = 100.0 - proportion_prev_seen
    str += "     %3.2f%% (#{numCalls - numPrevSeen}) of calls with unique args" % proportion_unique
    if proportion_unique != 100.0
      str += ", and\n"
      str += "     %3.2f%% (#{numPrevSeen}) of calls with args that were used several times\n" % proportion_prev_seen
      str += "      distr: #{argCountDistribution.inspect}"
    end
    str + "\n"
  end

  def enter(index)
    @do_profiling = false
    @invocation_stack.push [TimesClass.times.utime, 0.0, index]
    @do_profiling = true
  end

  def enter_cs(index)
    @do_profiling = false
    @invocation_stack.push [TimesClass.times.utime, 0.0, index]
    @call_sites[index][@invocation_stack[-2].last] += 1
    @do_profiling = true
  end
  
  def enter_cs_ua(index, *args)
    @do_profiling = false
    @invocation_stack.push [TimesClass.times.utime, 0.0, index]
    @call_sites[index][@invocation_stack[-2].last] += 1
    @arguments[index][args] += 1
    @do_profiling = true
  end

  def enter_ua(index, *args)
    @do_profiling = false
    @invocation_stack.push [TimesClass.times.utime, 0.0, index]
    @arguments[index][args] += 1
    @do_profiling = true    
  end

  def leave(index)
    @do_profiling = false
    start, time_in_callees = @invocation_stack.pop
    time_stats = @method_stats[index]
    time_stats[0] += 1                                  # Call count
    stop = TimesClass.times.utime
    time_in_method = stop - start
    @invocation_stack.last[1] += time_in_method # Add to callee t. for caller
    time_stats[1] += time_in_method                     # Total time
    time_stats[2] += (time_in_method - time_in_callees) # Self time
    @do_profiling = true
  end

  def leave_cs(index)
    @do_profiling = false
    start, time_in_callees = @invocation_stack.pop
    time_stats = @method_stats[index]
    time_stats[0] += 1                                  # Call count
    stop = TimesClass.times.utime
    time_in_method = stop - start
    @invocation_stack.last[1] += time_in_method # Add to callee t. for caller
    time_stats[1] += time_in_method                     # Total time
    self_time = time_in_method - time_in_callees
    time_stats[2] += self_time
    @call_times[index][@invocation_stack.last[2]] += self_time
    @do_profiling = true
  end

  def start_line_profiling(index)
    # Not yet implemented
  end

  def stop_line_profiling(index)
    # Not yet implemented
  end

  def report_differences_to(other)
    str = "Compared to profile taken " + other.profiling_start_time.inspect
    str << "\n" + ("*" * str.length) + "\n"
    str << "".ljust(30) + "New".center(10) + "Old".center(10)
    str << "Diff".center(10) + "\n"
    str << report_difference("Total elapsed time", 
			     @total_elapsed, other.total_elapsed) + "\n\n"
    str << report_method_differences(other)
  end

  def report_method_differences(other)
    our_methods, other_methods = self.logged_methods, other.logged_methods
    new_methods = our_methods - other_methods
    deleted_methods = other_methods - our_methods
    still_there = our_methods - new_methods - deleted_methods
    str = method_time_differences(still_there, our_methods, other_methods,
				  other)
    str << "\n"
    if deleted_methods.length > 0
      str << "Deleted methods: #{deleted_methods.map{|m| m.inspect}.join(', ')}\n"
    end
    if new_methods.length > 0
      str << "New methods: #{new_methods.map{|m| m.inspect}.join(', ')}\n"
    end
    str
  end

  def method_time_differences(methodsInBoth, ourMethods, otherMethods, other)
    diffs = Array.new
    methodsInBoth.each do |method|
      our_index, other_index = ourMethods.index(method), otherMethods.index(method)
      our_data, other_data = profile_data(method), other.profile_data(method)
      unless other_data == nil or our_data == nil
	diff = our_data[3] - other_data[3]
	diffs.push [method, our_data[3], other_data[3], diff]
      end
    end
    diffs.sort!{|a,b| b[2] <=> a[2]}
    str = ""
    diffs.each do |method, new, old, diff|
      str << report_difference(method, new, old) + "\n"
    end
    str
  end

  def profile_data(method)
    @profile.detect{|d| d.last == method}
  end

  def report_difference(message, new, old)
    message.ljust(30) + "#{new}".center(10) + "#{old}".center(10) +
      "#{percent_diff(new, old)}".center(10)
  end

  def percent_diff(new, old)
    return "" if old < 0.02
    "%.2f%%" % ((new - old).to_f/old*100)
  end

  protected

  attr_reader :total_elapsed, :profiling_start_time, :profile

  def init_statistics_datastructures(index)
    @method_stats[index] = [0, 0.0, 0.0]
    @call_sites[index] = Hash.new(0)
    @call_times[index] = Hash.new(0)
    @arguments[index] = Hash.new(0)
  end

  def add_method(methodId, classId, profileType = NORMAL)
    index = index_to_method(methodId, classId)
    unless index
      index = @methods_being_profiled.length
      @methods_being_profiled.push methodId
      @from_class.push classId
      @profile_types.push profileType
      init_statistics_datastructures(index)
    end
    index
  end

  def profiling_source_code(index, profileType)
    method_suffix, args = "", false
    method_suffix += "_cs" if profileType & CALL_SITES > 0
    if profileType & UNIQUE_ARGUMENTS > 0 or
	profileType & UNIQUE_ARG_INSPECTS > 0
      method_suffix += "_ua"
      args = true
    end
    pre = ["if $profiler.profile?", 
      "$profiler.enter#{method_suffix}(#{index}"]
    post = ["if $profiler.profile?"]
    if profileType & CALL_SITES > 0
      post.push "$profiler.leave_cs(#{index})"
    else
      post.push "$profiler.leave(#{index})"
    end
    pre[-1] += 'INSERT_ARGS' if args
    pre[-1] += ')'
    if profileType & LINE_PROFILING > 0
      pre << "$profiler.start_line_profiling(#{index})"
      post[1,0] = "$profiler.stop_line_profiling(#{index})"
    end
    return pre.push("end").join("\n"), post.push("end").join("\n")
  end

  # Go through the invocation stack and leave all methods.
  def unwind_invocation_stack
    while @invocation_stack.length > 1
      leave(@invocation_stack.pop[2])
    end
  end
end

def profile_filename(programName)
  programName + ".profile"
end

def write_profile_to_file(profiler, programName)
  begin
    str = Marshal.dump(profiler)
  rescue
    return
  end
  File.open(profile_filename(programName), "w") do |f|
    f.write str
  end
end

def compare_to_previous_profile(profiler, programName)
  str = ""
  if test(?f, profile_filename(programName))
    #File.open(profile_filename(programName), "r") do |f|
    cont = File.open(profile_filename(programName), "r") {|f| f.read }
    begin
      previous_profiler = Marshal.load(cont)
    rescue
      return ""
    end
    str << "\n" << profiler.report_differences_to(previous_profiler)
  end
  str
end

#Logger.new.wrap(Profiler, :log_enter, :log_exit, /profile_method/) 

$profiler = Profiler.new
trap_method_definitions proc{|methodId, klass|
  $profiler.profile_method(methodId, klass)
}

END {
  profiler = $profiler
  STDERR.puts profiler.report
  program_name = File.basename($0, ".rb")
  STDERR.puts compare_to_previous_profile(profiler, program_name)
  write_profile_to_file(profiler, program_name)
}

#############################################################################
# Simple test
#############################################################################
if __FILE__ == $0
  class ComplexTest
    attr_reader :real, :imaginary
    def initialize(real, imaginary)
      @real, @imaginary = real, imaginary
    end
    def add(other)
      real_add(other)
    end
    def real_add(other)
      @real += other.real
      @imaginary += other.imaginary
    end
    def inspect
      "#{real} + i*#{imaginary}"
    end
  end

  10.times do
    c = ComplexTest.new(rand, rand)
    100.times do
      c.add(ComplexTest.new(rand, rand))
    end
  end
  c = ComplexTest.new(1,1)
  c = ComplexTest.new(1,1)
  c.add ComplexTest.new(1,1)
  c.add ComplexTest.new(1,1)
end
