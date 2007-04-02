# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-charset'

module Modulobe
  module Sample
    MODEL1 =
'<?xml version="1.0" encoding="utf-8"?>
<modulobe version="1.1" generator="Modulobe ver 0.2.1">
<world><speed>0</speed></world>

<model>
<info>
<name>test model</name>

<author>test author</author>

<comment>test comment.
</comment>
</info>

<core ref="m0"><angle><x>0</x><y>0</y><z>0</z></angle></core>

<body><module id="m0"><tie dir="0"><angle><x>0</x><y>0</y><z>180</z></angle></tie>
<tie ref="m1" dir="1"><angle><x>0</x><y>0</y><z>0</z></angle></tie>
<tie dir="2"><angle><x>0</x><y>0</y><z>-90</z></angle></tie>
<tie dir="3"><angle><x>0</x><y>0</y><z>90</z></angle></tie>
</module><module id="m1"><tie ref="m0" dir="0"><angle><x>0</x><y>0</y><z>180</z></angle></tie>
<tie ref="m2" dir="1"><angle><x>0</x><y>0</y><z>0</z></angle></tie>
<tie dir="2"><angle><x>0</x><y>0</y><z>-90</z></angle></tie>
<tie dir="3"><angle><x>0</x><y>0</y><z>90</z></angle></tie>
</module><module id="m2"><tie ref="m1" dir="0"><angle><x>0</x><y>0</y><z>180</z></angle></tie>
<tie ref="m3" dir="1"><angle><x>0</x><y>0</y><z>0</z></angle></tie>
<link type="8" cycle="1"><cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="90" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
</link>
</module><module id="m3"><tie ref="m2" dir="0"><angle><x>0</x><y>0</y><z>180</z></angle></tie>
<tie dir="1"><angle><x>0</x><y>0</y><z>0</z></angle></tie>
<tie dir="2"><angle><x>0</x><y>0</y><z>-90</z></angle></tie>
<tie dir="3"><angle><x>0</x><y>0</y><z>90</z></angle></tie>
</module></body>
</model>

<view>
<camera><angle><x>15</x><y>0</y><z>0</z></angle><distance>18.000000</distance></camera>

<focus ref="m2"/>
</view>
</modulobe>
'

    MODULOBE_TEST_MODEL =
'<?xml version="1.0" encoding="utf-8"?>
<modulobe version="0">
<world><speed>0</speed></world>

<model>
<core ref="m0">
<angle><x>0</x><y>0</y><z>0</z></angle>
</core>

<body><module id="m0"><tie dir="0">
<angle><x>0</x><y>0</y><z>180</z></angle>
</tie>
<tie ref="m1" dir="1">
<angle><x>0</x><y>0</y><z>0</z></angle>
</tie>
<tie dir="2">
<angle><x>0</x><y>0</y><z>-90</z></angle>
</tie>
<tie dir="3">
<angle><x>0</x><y>0</y><z>90</z></angle>
</tie>
</module><module id="m1"><tie ref="m0" dir="0">
<angle><x>0</x><y>0</y><z>180</z></angle>
</tie>
<tie ref="m2" dir="1">
<angle><x>0</x><y>0</y><z>0</z></angle>
</tie>
<tie dir="2">
<angle><x>0</x><y>0</y><z>-90</z></angle>
</tie>
<tie dir="3">
<angle><x>0</x><y>0</y><z>90</z></angle>
</tie>
</module><module id="m2"><tie ref="m1" dir="0">
<angle><x>0</x><y>0</y><z>180</z></angle>
</tie>
<tie ref="m3" dir="1">
<angle><x>0</x><y>0</y><z>0</z></angle>
</tie>
<link type="8" cycle="1"><cycle angle="0" power="1"/>
<cycle angle="90" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
</link>
</module><module id="m3"><tie ref="m2" dir="0">
<angle><x>0</x><y>0</y><z>180</z></angle>
</tie>
<tie dir="1">
<angle><x>0</x><y>0</y><z>0</z></angle>
</tie>
<tie dir="2">
<angle><x>0</x><y>0</y><z>-90</z></angle>
</tie>
<tie dir="3">
<angle><x>0</x><y>0</y><z>90</z></angle>
</tie>
</module></body>
</model>
</modulobe>'

    MODULOBE_TEST_MODEL1 =
'<?xml version="1.0" encoding="utf-8"?>
<modulobe version="0">
<world><speed>0</speed></world>
<model>
<info>
<name>t1 model</name>
<author>Alice</author>
<comment>This is a comment.
</comment>
</info>
<core ref="m0"><angle><x>0</x><y>0</y><z>0</z></angle></core>
<body><module id="m0"><tie dir="0"><angle><x>0</x><y>0</y><z>180</z></angle></tie>
<tie dir="1"><angle><x>0</x><y>0</y><z>0</z></angle></tie>
<tie dir="2"><angle><x>0</x><y>0</y><z>-90</z></angle></tie>
<tie dir="3"><angle><x>0</x><y>0</y><z>90</z></angle></tie>
</module></body>
</model>
</modulobe>'

    MODULOBE_TEST_MODEL2 =
'<?xml version="1.0" encoding="utf-8"?>
<modulobe version="0">
<world><speed>0</speed></world>
<model>
<info>
<name>t2 model</name>
<author>Bob</author>
<comment>This is a comment, too.
</comment>
</info>
<core ref="m0"><angle><x>0</x><y>0</y><z>0</z></angle></core>
<body><module id="m0"><tie dir="0"><angle><x>0</x><y>0</y><z>180</z></angle></tie>
<tie ref="m1" dir="1"><angle><x>0</x><y>0</y><z>0</z></angle></tie>
<tie dir="2"><angle><x>0</x><y>0</y><z>-90</z></angle></tie>
<tie dir="3"><angle><x>0</x><y>0</y><z>90</z></angle></tie>
</module><module id="m1"><tie ref="m0" dir="0"><angle><x>0</x><y>0</y><z>180</z></angle></tie>
<tie ref="m2" dir="1"><angle><x>0</x><y>0</y><z>0</z></angle></tie>
<link type="8" cycle="1"><cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="90" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
<cycle angle="0" power="1"/>
</link>
</module><module id="m2"><tie ref="m1" dir="0"><angle><x>0</x><y>0</y><z>180</z></angle></tie>
<tie dir="1"><angle><x>0</x><y>0</y><z>0</z></angle></tie>
<tie dir="2"><angle><x>0</x><y>0</y><z>-90</z></angle></tie>
<tie dir="3"><angle><x>0</x><y>0</y><z>90</z></angle></tie>
</module></body>
</model>
</modulobe>'

    RSS_IN_UTF8 =
'<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:creativeCommons="http://backend.userland.com/creativeCommonsRssModule">
<channel>
     <title>Modulobe Collection</title>
     <link>http://www.modulobe.com/model.html</link>
     <description>modulobe.comにアップロードされたmodelのリストです。</description>
     <language>ja</language>
     <managingEditor>modulobe@qwik.jp</managingEditor>
     <webMaster>modulobe@qwik.jp</webMaster>
     <lastBuildDate>*Sat, 9 Jul 2005 13:09:31 GMT*</lastBuildDate>
     <ttl>60</ttl>
     <item>
          <title>蛇、長すぎる</title>
          <link>http://www.modulobe.com/model.files/hebi-nagasugiru.mdlb</link>
          <description>長すぎます。</description>
          <author>Kouichirou Eto</author>
          <pubDate>Sat, 9 Jul 2005 12:56:44 GMT</pubDate>
          <enclosure url="http://www.modulobe.com/model.files/hebi-nagasugiru.mdlb" length="87928" type="application/xml"/>
          <creativeCommons:license>http://creativecommons.org/licenses/by/2.1/jp/</creativeCommons:license>
     </item>
     <item>
          <title>*name*</title>
          <link>http://www.modulobe.com/model.files/*filename.mdlb*</link>
          <description>*comment*</description>
          <author>*author*</author>
          <pubDate>*Sun, 3 Jul 2005 14:29:26 GMT*</pubDate>
          <enclosure url="http://www.modulobe.com/model.files/*filename.mdlb*" length="*11922960*" type="application/xml"/>
          <creativeCommons:license>http://creativecommons.org/licenses/by/2.1/jp/</creativeCommons:license>
     </item>
</channel>
</rss>'.set_sourcecode_charset.to_xml_charset

    # ============================== Simple models
    MODEL_CORE = 
'<?xml version="1.0" encoding="utf-8"?>
<modulobe version="1.1" generator="Modulobe ver 0.2.1">
<world><speed>0</speed></world>

<model>
<info>
<name></name>

<author></author>

<comment></comment>
</info>

<core ref="m0"><angle><x>0</x><y>0</y><z>0</z></angle></core>

<body><module id="m0"><tie dir="0"><angle><x>0</x><y>0</y><z>180</z></angle></tie>
<tie dir="1"><angle><x>0</x><y>0</y><z>0</z></angle></tie>
<tie dir="2"><angle><x>0</x><y>0</y><z>-90</z></angle></tie>
<tie dir="3"><angle><x>0</x><y>0</y><z>90</z></angle></tie>
</module></body>
</model>

<view>
<camera><angle><x>15</x><y>0</y><z>0</z></angle><distance>18.000000</distance></camera>

<focus ref="m0"/>
</view>
</modulobe>
'

    MODEL_WITH_NAME =
'<?xml version="1.0" encoding="utf-8"?>
<modulobe version="1.1" generator="Modulobe ver 0.2.1">
<world><speed>0</speed></world>

<model>
<info>
<name>n</name>

<author>a</author>

<comment>c
</comment>
</info>

<core ref="m0"><angle><x>0</x><y>0</y><z>0</z></angle></core>

<body><module id="m0"><tie dir="0"><angle><x>0</x><y>0</y><z>180</z></angle></tie>
<tie dir="1"><angle><x>0</x><y>0</y><z>0</z></angle></tie>
<tie dir="2"><angle><x>0</x><y>0</y><z>-90</z></angle></tie>
<tie dir="3"><angle><x>0</x><y>0</y><z>90</z></angle></tie>
</module></body>
</model>

<view>
<camera><angle><x>15</x><y>0</y><z>0</z></angle><distance>18.000000</distance></camera>

<focus ref="m0"/>
</view>
</modulobe>
'

    MODEL_WITH_JNAME =
'<?xml version="1.0" encoding="utf-8"?>
<modulobe version="1.1" generator="Modulobe ver 0.2.1">
<world><speed>0</speed></world>

<model>
<info>
<name>あ </name>

<author>い </author>

<comment>う
</comment>
</info>

<core ref="m0"><angle><x>0</x><y>0</y><z>0</z></angle></core>

<body><module id="m0"><tie dir="0"><angle><x>0</x><y>0</y><z>180</z></angle></tie>
<tie dir="1"><angle><x>0</x><y>0</y><z>0</z></angle></tie>
<tie dir="2"><angle><x>0</x><y>0</y><z>-90</z></angle></tie>
<tie dir="3"><angle><x>0</x><y>0</y><z>90</z></angle></tie>
</module></body>
</model>

<view>
<camera><angle><x>15</x><y>0</y><z>0</z></angle><distance>18.000000</distance></camera>

<focus ref="m0"/>
</view>
</modulobe>
'.set_sourcecode_charset.to_xml_charset


  end
end
