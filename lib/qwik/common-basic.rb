$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-time'
require 'qwik/parse-plugin'

module Qwik
  # ============================== exception
  class QwikError < StandardError; end
  class RequireLogin < QwikError; end
  class RequirePost < QwikError; end
  class PageNotFound < QwikError; end
  class RequireNoPathArgs < QwikError; end
  class RequireMember < QwikError; end
  class InvalidUserError < QwikError; end
  class BaseIsNotSitename < QwikError; end
  class NoCorrespondingPlugin < QwikError; end	# plugin

  class Action
    # ============================== date
    def self.date_parse(tag)
      if /\A(\d\d\d\d)-(\d\d)-(\d\d)\z/ =~ tag
	return Time.local($1.to_i, $2.to_i, $3.to_i)
      end
      return nil
    end

    def self.date_abbr(now, date)
      year  = date.year
      month = date.month
      mday  = date.mday
      return date.ymd if now.year != date.year
      return date.md
    end

    def self.date_emphasis(now, date, title)
      diff = date - now
      day = 60*60*24
      if diff < -day	# past
	return [:span, {:class=>'past'}, title]
      elsif diff < day*7	# This week.
	return [:strong, title]
      elsif diff < day*30	# This month.
	return [:em, title]
      else
	return [:span, {:class=>'future'}, title]
      end
    end

    # ============================== response
    def c_set_status(status=200)
      @res.status = status
    end

    def c_set_contenttype(contenttype="text/html; charset=Shift_JIS")
      @res['Content-Type'] = contenttype
    end
    alias c_set_html c_set_contenttype

    def c_set_no_cache(pragma='no-cache', control='no-cache')
      @res['Pragma'] = pragma
      @res['Cache-Control'] = control
    end

    def c_set_body(body)
      @res.body = body
    end

    # ============================== rewrite plugin
    def plugin_edit(plugin_name, plugin_num)
      # Get the original page.
      page = @site[@req.base]
      str = page.load
      md5 = str.md5hex

      # Split the page into paragraphs.
      paragraphs = Plugin.split(str)

      # Replace the content of the plugin.
      written = false
      new_paras = Plugin.rewrite(paragraphs, plugin_name, plugin_num) {|plugin|
	plugin_org_content = plugin[2] || ''
	plugin_altered_content = yield(plugin_org_content)
	plugin[2] = plugin_altered_content	# Destructive.
	written = true
	plugin
      }

      raise NoCorrespondingPlugin if ! written

      # Reconstruct the page from the lines.
      new_page_str = Plugin.join(new_paras)

      page.put_with_md5(new_page_str, md5)

      return nil
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestCommon < Test::Unit::TestCase
    include TestSession

    def test_date
      # test_date_parse
      time = Qwik::Action.date_parse('1970-01-01')
      assert_equal -32400, time.to_i

      # test_date_abbr
      now = Time.local(1970, 1, 1)
      t2 = Time.local(1970, 1, 2)
      abbr = Qwik::Action.date_abbr(now, t2)
      assert_equal '01-02', abbr

      t2 = Time.local(1971, 1, 1)
      abbr = Qwik::Action.date_abbr(now, t2)
      assert_equal '1971-01-01', abbr

      # test_date_emphasis
      now = Time.local(1970, 2, 1)
      past = Time.local(1970, 1, 30)
      span = Qwik::Action.date_emphasis(now, past, 't')
      assert_equal [:span, {:class=>'past'}, 't'], span

      tomorrow = Time.local(1970, 2, 2)
      span = Qwik::Action.date_emphasis(now, tomorrow, 't')
      assert_equal [:strong, 't'], span

      nextweek = Time.local(1970, 2, 9)
      span = Qwik::Action.date_emphasis(now, nextweek, 't')
      assert_equal [:em, 't'], span

      nextmonth = Time.local(1970, 3, 3)
      span = Qwik::Action.date_emphasis(now, nextmonth, 't')
      assert_equal [:span, {:class=>'future'}, 't'], span
    end

    def test_response
      res = session

      # test_c_set_status
      @action.c_set_status(7743)
      ok_eq(7743, res.status)

      # test_c_set_contenttype
      @action.c_set_contenttype
      ok_eq("text/html; charset=Shift_JIS", res['Content-Type'])

      # test_c_set_no_cache
      @action.c_set_no_cache
      ok_eq('no-cache', res['Pragma'])
      ok_eq('no-cache', res['Cache-Control'])

      # test_c_set_body
      @action.c_set_body('body')
      ok_eq('body', res.body)
    end

    def nu_test_rewrite_plugin
      # This is tested in act-table.rb
    end
  end
end
