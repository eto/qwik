// -*- c++ -*-
// 
// Copyright (C) 2003-2005 Kouichirou Eto
//     All rights reserved.
//     This is free software with ABSOLUTELY NO WARRANTY.
// 
// You can redistribute it and/or modify it under the terms of 
// the GNU General Public License version 2.
// 

// ============================== document getter
// copied from nifty.js
document.getElementsBySelector = function(selector) {
  var s = [];
  var selid = "";
  var selclass = "";
  var tag = selector;
  var objlist = [];

  //descendant selector like "tag#id tag"
  if (selector.indexOf(" ") > 0) {
    s = selector.split(" ");
    var fs = s[0].split("#");
    if (fs.length == 1) return (objlist);
    return (document.getElementById(fs[1]).getElementsByTagName(s[1]));
  }

  //id selector like "tag#id"
  if (selector.indexOf("#") > 0) {
    s = selector.split("#");
    tag = s[0];
    selid = s[1];
  }
  if (selid != "") {
    objlist.push(document.getElementById(selid));
    return (objlist);
  }

  if (selector.indexOf(".") == 0) { // no tag
    tag = "*";
    selclass = selector.slice(1, selector.length);
  } else if (selector.indexOf(".") > 0) {
    //class selector like "tag.class"
    s = selector.split(".");
    tag = s[0];
    selclass = s[1];
  }

  // tag selector like "tag"
  var v = document.getElementsByTagName(tag);
  if (selclass == "") return (v);
  for (var i=0; i < v.length; i++) {
    if (v[i].className == selclass) {
      objlist.push(v[i]);
    }
  }
  return (objlist);
};

document.getElementsByClassName = function(klass) {
  var all = document.getElementsByTagName("*");
  var ar = [];
  for (var i = 0; i < all.length; i++) {
    if (all[i].className == klass)
      ar.push(all[i]);
  }
  return ar;
};

document.getCssRules = function() {
  var ar = [];
  var sheets = document.styleSheets;
  for (var i=0; i < sheets.length; i++) {
    var rules = document.styleSheets[i].rules;
    if (!rules) rules = document.styleSheets[i].cssRules;
    for (var j=0; j < rules.length; j++) {
      if(rules[j].type == rules[j].STYLE_RULE) {
	ar.push(rules[j]);
      }
    }
  }
  return ar;
};

// ============================== NiftyCornerRule
function NiftyCornerRule(position, selector, background, border, radius) {
  this.position = position;
  this.selector = selector;
  this.background = background;
  this.border = border;
  this.radius = radius; // not used for now.

  this.makeLine = function(margin, height, bg) {
    var x = document.createElement("span");
    x.style.display = "block";
    x.style.height = ""+height+"px";
    x.style.margin = "0 "+margin+"px";
    x.style.overflow = "hidden";
    x.style.backgroundColor = bg;
    return x;
  };

  this.makeContainer = function(border) {
    var d = document.createElement("span");
    d.style.display = "block";
    d.style.backgroundColor = border;
    return d;
  };

  this.makeTop = function(bg, border) {
    var d = this.makeContainer(border);
    d.appendChild(this.makeLine(5, 1, bg));
    d.appendChild(this.makeLine(3, 1, bg));
    d.appendChild(this.makeLine(2, 1, bg));
    d.appendChild(this.makeLine(1, 2, bg));
    return d;
  };

  this.makeBottom = function(bg, border) {
    var d = this.makeContainer(border);
    d.appendChild(this.makeLine(1, 2, bg));
    d.appendChild(this.makeLine(2, 1, bg));
    d.appendChild(this.makeLine(3, 1, bg));
    d.appendChild(this.makeLine(5, 1, bg));
    return d;
  };

  this.applyToElement = function(el) {
    var bg     = this.background;
    var border = this.border;
    if (this.position == "both" || this.position == "top")
    el.insertBefore(this.makeTop(bg, border), el.firstChild);
    if (this.position == "both" || this.position == "bottom")
    el.appendChild(this.makeBottom(bg, border), el.firstChild);
  };

  this.apply = function() {
    var sel = this.selector;
    var els = document.getElementsBySelector(sel);
    if (!els) return;
    for (var i=0; i < els.length; i++) {
      var el = els[i];
      this.applyToElement(el);
    }
  };
}

// ==============================
function NiftyPP() {
}

NiftyPP.prototype = {
  init : function() {
    this.applyAll();
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

  applyAll : function() {
    var ncs = this.getNiftyCornerRules();
    for (var i=0; i < ncs.length; i++) {
      var nc = ncs[i];
      nc.apply();
    }
    return false;
  },

  check : function() { // copied from nifty.js
    if (!document.getElementById || !document.createElement)
    return (false);
    var b = navigator.userAgent.toLowerCase();
    if (b.indexOf("msie 5") > 0 && b.indexOf("opera") == -1)
    return (false);
    return (true);
  },

  getNiftyCornerRules : function() {
    var ar = [];
    var rules = document.getCssRules();
    //    if (0 < rules.length) {	// Thanks to puggy
    for (var i=0; i < rules.length; i++) {
      var rule   = rules[i];
      var selt   = rule.selectorText;
      var sel    = String(selt).toLowerCase();

      var style  = rule.style;
      var bg     = style.backgroundColor;

      var nc;
      var done = false;

      // for IE
      nc = style["moz-border-radius"];
      if (nc) {
	var border = style.borderColor;
	var obj = new NiftyCornerRule("both", sel, bg, border, nc);
	ar.push(obj);
	done = true;
      }

      if (!done) {
	nc = style["moz-border-radius-topleft"];
	if (nc) {
	  var border = style.borderTopColor;
	  var obj = new NiftyCornerRule("top", sel, bg, border, nc);
	  ar.push(obj);
	  done = true;
	}
      }

      if (!done) {
	nc = style["moz-border-radius-bottomleft"];
	if (nc) {
	  var border = style.borderBottomColor;
	  var obj = new NiftyCornerRule("bottom", sel, bg, border, nc);
	  ar.push(obj);
	  done = true;
	}
      }

      // for FireFox
      if (!done) {
	nc = style.MozBorderRadiusTopleft;
	if (nc) {
	  var border = style.borderTopColor;
	  var obj = new NiftyCornerRule("top", sel, bg, border, nc);
	  ar.push(obj);
	}

	nc = style.MozBorderRadiusBottomleft;
	if (nc) {
	  var border = style.borderBottomColor;
	  var obj = new NiftyCornerRule("bottom", sel, bg, border, nc);
	  ar.push(obj);
	}
      }
    }
    //}
    return ar;
  }
}

if (typeof g_niftypp == 'undefined') {
  var g_niftypp = new NiftyPP();
  var proc = function() {
    g_niftypp.init();
  }
  window.onload = proc;
  //g_niftypp.addEventListener(window, 'load', proc);
}

// end.
