// -*- c++ -*-
//
// debugwindow.js - Show debug information using small debug window.
//
// Copyright (C) 2005 Kouichirou Eto, 
//     All rights reserved.
//     This is free software with ABSOLUTELY NO WARRANTY.
//
// You can redistribute it and/or modify it under the terms of 
// the GNU General Public License version 2.
//

//
// * Usage
// init() : called from onload.
// open() : open window.
// print(str) : print message.
// puts(str) : print message with new line.
// clear() : clear window.
// p(obj) : print the result of inspecting the object.
// inspect(obj) : inspect object.
//

//
// * Interface for the debug window
// [x] - close window.
// [v] - make console bigger.
// [-] - close console.
// [+] - open console.
//

//
// * History
//
// ** 2005-04-05 DebugWindow 0.5
// - Do not open window by default.
//
// ** 2005-03-31 DebugWindow 0.4
// - Set default position to right top corner.
// - Set default to close console.
//
// ** 2005-03-30 DebugWindow 0.3
// - Add a lines button and a close button.
// - Add a test case.
//
// ** 2005-03-30 DebugWindow 0.2
// - Now works in IE same as Firefox.
//
// ** 2005-03-29 DebugWindow 0.1
// - The initial release.
//

//
// * Special Thanks to
// 
// - debug.js
// -- http://homepage1.nifty.com/kuraman/js/debug.html
// 
// - wema
// -- http://wema.sourceforge.jp/
// 
// - ArekorePopup.js
// -- http://www.remus.dti.ne.jp/~a-satomi/bunsyorou/ArekorePopup.html
// 
// - bobchin
// -- http://d.hatena.ne.jp/bobchin/20050304
// 

function DebugWindow() {
  // setting.
  this.showConsole = true;
//this.showConsole = false;
  this.width  = "320px";
  this.height = "240px";	// height unit must be "px".

  // variables.
  this.win = null;
  this.toggleButton = null;
  this.console = null;
  this.buffer = "";
  this.dragging = false;
}

DebugWindow.prototype = {
  init : function() {
    this.open();
  },

  open : function() {
    var obj = document.getElementById("debugwindow");
    if (obj) return;	// already opened.

    // create window
    var w = document.createElement("div");
    w.setAttribute("id", "debugwindow");
    with(w.style) {
      zIndex = "1";
      position = "absolute";
      right = "0px";
      top = "0px";
      width = this.width;
      margin = "0";
      padding = "0";
      border = "2px outset";
      fontFamily = "Verdana,Arial,sans-serif";
      fontSize = "small";
    }
    w.show = function() {
      this.style.display = "block";
    };
    w.hide = function() {
      this.style.display = "none";
    };
    document.body.appendChild(w);
    this.win = w;

    // titlebar
    var titlebar = document.createElement("div");
    titlebar.setAttribute("id", "debugwindowtitlebar");
    with(titlebar.style) {
      margin = "0";
      padding = "0";
      borderBottom = "1px solid #ccc";
      background = "#999";
      color = "#fff";
    }
    w.appendChild(titlebar);

    // console
    var console = document.createElement("div");
    console.setAttribute("id", "debugwindowconsole");
    console.contentEditable = "true"; // contentEditable only works in IE.
    with(console.style) {
      height = this.height;
      overflow = "scroll";
      margin = "0";
      padding = "0";
      border = "1px inset";
      background = "#eee";
      color = "#000";
      fontFamily = "Verdana,Arial,sans-serif";
      fontSize = "small";
    }
    console.makeBigger = function() {
      var s = this.style;
      var h = parseInt(s.height.replace("px", ""));
      h += 24;
      s.height = h+"px";
    };
    console.show = function() {
      this.style.display = "block";
    };
    console.hide = function() {
      this.style.display = "none";
    };
    console.visible = function() {
      return this.style.display == "block";
    };
    console.show(); // console is visible.
    w.appendChild(console);
    this.console = console;

    // title
    var span = document.createElement("span");
    with(span.style) {
      display = "block";
      margin = "0";
      padding = "0 0 0 10px";
      fontSize = "xx-small";
    }
    span.innerHTML = "debug window";
    span.onmousedown = function(e) { // onmousedown
      g_debug.startDragging(e);
    };
    span.ondblclick = function() {
      g_debug.consoleToggle();
    };
    titlebar.appendChild(span);

    // close button
    var span = this.createButton("debugwindowclosebutton");
    span.setPos(0, 0);
    span.innerHTML = "x";
    span.onmousedown = function() {
      g_debug.win.hide();
    };
    titlebar.appendChild(span);

    // make bigger button
    var span = this.createButton("debugwindowbiggerbutton");
    span.setPos(18, 0);
    span.innerHTML = "v";
    var proc = function() {
      g_debug.console.makeBigger();
    };
    span.onclick = proc;
    span.ondblclick = proc;
    titlebar.appendChild(span);

    // console toggle button
    var span = this.createButton("debugwindowtogglebutton");
    span.setPos(32, 0);
    var proc = function() {
      g_debug.consoleToggle();
    };
    span.onclick = proc;
    span.ondblclick = proc;
    titlebar.appendChild(span);
    this.toggleButton = span;

    // set document event
    document.onmousemove = function(e) {
      g_debug.nowDragging(e);
    };
    document.onmouseup = function(e) {
      g_debug.endDragging();
    }

    if (! this.showConsole) {
      this.consoleToggle(); // hide at the first.
    }
  },

  createButton : function(id) { // private
    var span = document.createElement("span");
    span.setAttribute("id", id);
    with(span.style) {
      width = "12px";
      height = "10px";
      margin = "0";
      padding = "0";
      background = "#ccc";
      color = "#000";
      fontSize = "xx-small";
      fontWeight = "bold";
      textAlign = "center";
      display = "block";
      border = "1px outset";
    }
    span.setPos = function(x, y) {
      with(this.style) {
	position = "absolute";
	right = x+"px";
	top = y+"px";
      }
    }
    return span;
  },

  consoleToggle : function(e) {
    var con = this.console;
    var but = this.toggleButton;
    if (con.visible()) {
      con.hide();
      but.innerHTML = "+";
    } else {
      con.show();
      but.innerHTML = "-";
    }
  },

  startDragging : function(e) {
    if (typeof e == "undefined") {
      e = window.event;
    }
    var w = this.win;
    if (!w) return;
    var pos = this.getMousePos(e);
    var divpos = this.getDivPos(w);
    var x = pos.mouseX - divpos.x;
    var y = pos.mouseY - divpos.y
    this.offset = {
      x : x,
      y : y
    };
    this.dragging = true;
  },

  nowDragging : function(e) {
    if (typeof e == "undefined") {
      e = window.event;
    }
    if (!this.alerted) {
      //g_debug.p(e);
      this.alerted = true;
    }
    var w = this.win;
    if (!w) return;
    if (!this.dragging) return;
    var pos = this.getMousePos(e);
    var offset = this.offset;
    var x = pos.mouseX - offset.x;
    var y = pos.mouseY - offset.y;
    w.style.left = x+"px";
    w.style.top  = y+"px";
  },

  endDragging : function() {
    g_debug.dragging = false;
  },

  // ref. ArekorePopup.js
  getMousePos : function(e) {
    var d = document.documentElement;
    var body = document.body;
    var isSafari = navigator.userAgent.match('AppleWebKit');
    var scrollX = (window.scrollX) ? window.scrollX : (d.scrollLeft) ? d.scrollLeft : body.scrollLeft;
    var scrollY = (window.scrollY) ? window.scrollY : (d.scrollTop)  ? d.scrollTop  : body.scrollTop;
    var windowW = (window.innerWidth)  ? window.innerWidth  : d.offsetWidth;
    var windowH = (window.innerHeight) ? window.innerHeight : d.offsetHeight;
    var windowX = e.clientX - (( isSafari) ? scrollX : 0);
    var windowY = e.clientY - (( isSafari) ? scrollY : 0);
    var mouseX  = e.clientX + ((!isSafari) ? scrollX : 0);
    var mouseY  = e.clientY + ((!isSafari) ? scrollY : 0);

    var pos = {
      scrollX : scrollX,
      scrollY : scrollY,
      windowW : windowW,
      windowH : windowH,
      windowX : windowX,
      windowY : windowY,
      mouseX : mouseX,
      mouseY : mouseY
    };
    return pos;
  },

  getDivPos : function(o) {
    var s = o.style;
    var x = (s.left) ? s.left : (s.posLeft) ? s.posLeft : o.offsetLeft+"px";
    var y = (s.top)  ? s.top  : (s.posTop)  ? s.posTop  : o.offsetTop+"px";
    divx = parseInt(x.replace("px", ""));
    divy = parseInt(y.replace("px", ""));
    if (divx == 0) divx = 1; // IE BUGFIX.
    if (divy == 0) divy = 1;
    var pos = {
      x : divx,
      y : divy
    };
    return pos;
  },

  // ref. ArekorePopup.js
  addEventListener : function(obj, type, listener) {
    if (obj.addEventListener) { // Std DOM Events
      obj.addEventListener(type, listener, false);
    } else if (obj.attachEvent) { // IE
      //g_debug.pa("addEvent hi");
      var e = {
	//type            : window.event.type,
	//target          : window.event.srcElement,
	//currentTarget   : obj,
	//clientX         : window.event.clientX,
	//clientY         : window.event.clientY,
	//pageY           : document.body.scrollTop + window.event.clientY,
	//shiftKey        : window.event.shiftKey,
	//stopPropagation : function() { window.event.cancelBubble = true }
      };
      //g_debug.pa(e);
      obj.attachEvent('on' + type,
		      function() { listener( e ) } );
    }
  },

  destroy : function() { // private
    var div = this.win;
    if (!div) return;
    document.body.removeChild(div);
    this.win = null;
  },

  bufferPrint : function(str) {
    str = this.escapeHTML(str);
    this.buffer += str;
  },

  bufferPrintTag : function(str) {
    this.buffer += str;
  },

  print : function(str) {
    this.bufferPrintTag("<tt>");
    this.bufferPrint(str)
    this.bufferPrintTag("</tt>");
  },

  puts : function(str) {
    this.print(str);
    this.bufferPrintTag("<br\n/>");
    this.flush();
  },

  clear : function() {
    this.buffer = "";
    this.flush();
  },

  p : function(obj) {
    var str = this.inspect(obj)
    this.puts(str);
  },

  flush : function() {
    if (!this.win) this.open();
    if (this.win.style.display == "none") {
      this.win.style.display = "block";
    }
    var div = this.console;
    if (!div) return; // error
    div.innerHTML = this.buffer;
  },

  pa : function(obj) { // to test DebugWindow.
    var str = this.inspect(obj)
    alert(str);
  },

  inspect : function(obj) {
    if (typeof obj == "number") {
      return ""+obj;
    } else if (typeof obj == "string") {
      return "\""+obj+"\"";
    } else if (typeof obj == "function") {
      return ""+obj;
    } else if (typeof obj == "object") {
      //var delimiter = ", <br>";
      var delimiter = ",\n";
      var str = "{";
      var added = false;
      for (key in obj) {
	var value = obj[key];
	if (value) {
	  if (added) str += delimiter;
	  added = true;
	  if (typeof value == "number") {
	    str += ""+key+"=>"+value+"";
	  } else if (typeof value == "string") {
	    str += ""+key+"=>\""+value+"\"";
	  } else if (typeof value == "function") {
	    str += ""+key+"()";
	  } else if (typeof value == "object") {
	    str += ""+key+"=>"+value+"";
	  } else {
	    str += ""+key+"=><"+(typeof value)+":"+value+">";
	  }
	}
      }
      return str+"}";
    } else {
      return "<"+(typeof obj)+":"+obj+">";
    }
  },

  escapeHTML : function(str) {
    str = str.replace(/&/g, "&amp;");
    str = str.replace(/</g, "&lt;");
    str = str.replace(/>/g, "&gt;");
    str = str.replace(/\"/g, "&quot;"); // "
    //str = str.replace(/\n/g, "<br\n/>");
    return str;
  },

  dummy : function() {
  } // no "," here
};

if (typeof g_debug == 'undefined') {
  var g_debug = new DebugWindow();

  //var proc = function() {
  //  g_debug.init();
  //}
  //window.onload = proc;
  //g_debug.addEventListener(window, "load", proc);
}
