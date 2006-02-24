$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_plugin_monta = {
      :dt => 'Monta method plugin',
      :dd => 'You can hide a part of text by using JavaScript.',
      :dc => "* Example
 {{monta(\"This is an example.\")}}
{{monta(\"This is an example.\")}}

Click this black box and you see the text.
" }

    def plg_monta(*a)
      element = :span
      txt = a.shift
      if block_given?
	element = :div
	txt = yield
      end

      return if txt.nil?

      return [element, {:style=>'background-color:black;text:black;',
	  :onmouseup=>"this.style.backgroundColor='transparent';this.style.text='inherited';return true;"}, txt]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActMonta < Test::Unit::TestCase
    include TestSession

    def test_all
      ok_wi([], '{{monta}}')
      ok_wi([:span, {:style=>'background-color:black;text:black;',
		:onmouseup=>"this.style.backgroundColor='transparent';this.style.text='inherited';return true;"},
	      't'], '{{monta(t)}}')
      ok_wi([:div, {:style=>'background-color:black;text:black;',
		:onmouseup=>"this.style.backgroundColor='transparent';this.style.text='inherited';return true;"},
	      "t\n"], "{{monta\nt\n}}")
    end
  end
end
