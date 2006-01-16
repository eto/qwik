// -*- c++ -*-
//
// Copyright (C) 2003-2005 Kouichirou Eto
//     All rights reserved.
//     This is free software with ABSOLUTELY NO WARRANTY.
//
// You can redistribute it and/or modify it under the terms of 
// the GNU General Public License version 2.
//

// reference: http://nais.to/~yto/tools/contenteditablewiki/

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

// ==================== class
function WEditor() {
}

WEditor.prototype = {
  init : function(pagename, ext) {
    this.pagename = pagename;
    this.ext = ext;

    this.wtext   = document.getElementById("wtext");
    this.weditor = document.getElementById("weditor");
    this.wform   = document.getElementById("wform");

    this.initial_content = this.weditor.innerHTML;

    this.alerted = null;

    this.count = 0
    this.count_start_content = null;

    this.xmlhttp = null;
  },

  check : function() {
    if (typeof(this.pagename) == "undef") return;

    var interval = 1000;

    var cur_content = this.weditor.innerHTML;

    if (cur_content != this.initial_content) {
      if (this.count == 0) {
	this.count_start_content = cur_content;
      }
      this.count += 1;

      if (this.count_start_content != cur_content) {
	this.count = 0;
      }

      if (3 < this.count) {
	if (! this.alerted) {
	  //alert("Do save!");
	  this.alerted = true;
	}
      }
    }

    setTimeout('g_weditor.check();', interval);
  },

  save : function() {
    this.wtext.value = this.weditor.innerHTML;
    this.wform.submit();

    var xh = createXmlHttp();
    this.xmlhttp = xh;

    var url = this.pagename+".wysiwyg";

    xh.open("POST", url, true);
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

  }

}

var g_weditor;
if (typeof g_weditor == 'undefined') {
  g_weditor = new WEditor();
}

// ==================== function
function wysiwyg_save() {
  var wtext   = document.getElementById("wtext");
  var weditor = document.getElementById("weditor");
  var wform   = document.getElementById("wform");
  wtext.value = weditor.innerHTML;
  wform.submit();
}

function wysiwyg_command(com) {
  document.execCommand(com);
}

function wysiwyg_markup(tag) {
  var range = document.selection.createRange();
  range.pasteHTML("<"+tag+">"+range.text+"</"+tag+">");
}

function wysiwyg_image() {
  document.execCommand("InsertImage", true);
}

function wysiwyg_deleteTags() {
  var range = document.selection.createRange();
  range.pasteHTML(range.text.replace("<[^>]+>", " "));
}

/* end */
