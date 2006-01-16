// -*- c++ -*-
//
// Copyright (C) 2003-2005 Kouichirou Eto
//     All rights reserved.
//     This is free software with ABSOLUTELY NO WARRANTY.
//
// You can redistribute it and/or modify it under the terms of 
// the GNU General Public License version 2.
//

// ==================== xmlhttp
function createXmlHttp() {
  var x;
  try {
    x = new ActiveXObject("Msxml2.XMLHTTP");
    return x;
  } catch (e) {
    try {
      x = new ActiveXObject("Microsoft.XMLHTTP");
      return x;
    } catch (E) {
      try {
	if (typeof XMLHttpRequest != 'undefined') {
	  x = new XMLHttpRequest();
	  return x;
	}
      } catch (E) {
	return false;
      }
    }
  }
  return false;
}

// ==================== EWatcher
function EWatcher(url) {
  this.url = url;
  this.xmlhttp = null;
}

EWatcher.prototype = {
  toString : function() {
    return "EWatcher("+this.url+")";
  },

  getting_p : function() {
    if (! this.xmlhttp) return false;
    var s = this.xmlhttp.readyState;
    return (s != 4);
  },

  get : function() {
    var div = document.getElementById("event");
    if (!div) return;

    var url = this.url;
    var xmlhttp = createXmlHttp();
    this.xmlhttp = xmlhttp;
    xmlhttp.open("GET", url, true);
    xmlhttp.onreadystatechange = function() {
      if (xmlhttp.readyState == 4) {
	if (xmlhttp.status == 200) {
	  div.innerHTML = xmlhttp.responseText;
	}
      }
    }
    xmlhttp.send(null);
  },

  dummy : function() {
  } // no "," here
}

// ==================== Event watcher
function EventWatcher() {
  this.watchers = [];

  this.add = function(pagename) {
    var wat = new EWatcher(pagename);
    this.watchers.push(wat);
  }

  this.start = function() {
    for (var i=0; i < this.watchers.length; i++) {
      var wat = this.watchers[i];
      if (!wat.getting_p()) {
	wat.get();
      }
    }
  }
}

var g_eventwatcher;
if (typeof g_eventwatcher == 'undefined') {
  g_eventwatcher = new EventWatcher();
}

// end
