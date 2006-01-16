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

// ============================== monitor
function Monitor(pagename) {
  this.pagename = pagename;
  this.xmlhttp = null;

  this.toString = function() {
    return "Monitor("+this.pagename+")";
  }

  this.getting_p = function() {
    if (! this.xmlhttp) return;
    var s = this.xmlhttp.readyState;
    return (s != 4);
  }

  this.get = function() {
    //g_debug.p("start get "+this.pagename);
    var div = getById("body");
    if (!div) return;

    var url = this.pagename+".monitor";
    var xmlhttp = createXmlHttp();
    this.xmlhttp = xmlhttp;
    xmlhttp.open("GET", url, true);
    xmlhttp.onreadystatechange = function() {
      if (xmlhttp.readyState == 4) {
	if (xmlhttp.status == 200) {
	  div.innerHTML = xmlhttp.responseText;
	//g_debug.p("set html");
	  g_monitor_env.start();
	}
      }
    }
    xmlhttp.send(null);
  }
}

// ==================== monitor env
function MonitorEnv() {
  this.monitors = [];

  this.add = function(pagename) {
    var mon = new Monitor(pagename);
    this.monitors.push(mon);
  }

  this.start = function() {
    for (var i=0; i < this.monitors.length; i++) {
      var mon = this.monitors[i];
      if (!mon.getting_p()) {
	mon.get();
      }
    }
  }
}

var g_monitor_env;
if (typeof g_monitor_env == 'undefined') {
  g_monitor_env = new MonitorEnv();
}

// end
