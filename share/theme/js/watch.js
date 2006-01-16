// -*- c++ -*-
// 
// Copyright (C) 2003-2005 Kouichirou Eto
//     All rights reserved.
//     This is free software with ABSOLUTELY NO WARRANTY.
// 
// You can redistribute it and/or modify it under the terms of 
// the GNU General Public License version 2.
// 

// ============================== xmlhttp
function createXmlHttp() {
  var x;
  try {
    return new ActiveXObject("Msxml2.XMLHTTP");
  } catch (e) {
    try {
      return new ActiveXObject("Microsoft.XMLHTTP");
    } catch (E) {
      try {
	if (typeof XMLHttpRequest != 'undefined') {
	  return new XMLHttpRequest();
	}
      } catch (E) {
	return false;
      }
    }
  }
  return false;
}

// ============================== watcher
function Watcher(pagename, ext) {
  this.pagename = pagename;
  this.ext = ext;
  this.xmlhttp = null;
}

Watcher.prototype = {
  toString : function() {
    return "Watcher("+this.pagename+")";
  },

  getting_p : function() {
    if (! this.xmlhttp) return;
    var s = this.xmlhttp.readyState;
    return (s != 4);
  },

  get : function() {
    var interval = 1000;

    var div = document.getElementById("watch");
    if (!div) return;

    var ele = document.getElementById("watch_md5");
    if (!ele) return;
    var cur_md5 = ele.value;

    var url = this.pagename+".md5";

    var update_html = "<div class='update'><a href='"+this.pagename+"."+this.ext+"'>Update!</a></div>";

    var xh = createXmlHttp();
    this.xmlhttp = xh;
    xh.open("GET", url, true);
    xh.onreadystatechange = function() {
      if (xh.readyState == 4 && xh.status == 200) {
	var new_md5 = xh.responseText;
	if (new_md5 != cur_md5) {
	  div.innerHTML = update_html;
	} else {
	  setTimeout('g_watcher_env.start();', interval);
	}
      }
    }
    xh.send(null);
  },
  dummy : function() {} // no "," here
}

// ==================== watcher env
function WatcherEnv() {
  this.watchers = [];
}

WatcherEnv.prototype = {
  add : function(pagename, ext) {
    var mon = new Watcher(pagename, ext);
    this.watchers.push(mon);
  },

  start : function() {
    for (var i=0; i < this.watchers.length; i++) {
      var mon = this.watchers[i];
      if (! mon.getting_p()) {
	mon.get();
      }
    }
  },
  dummy : function() {} // no "," here
}

var g_watcher_env;
if (typeof g_watcher_env == 'undefined') {
  g_watcher_env = new WatcherEnv();
}

// end
