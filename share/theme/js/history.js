// -*- c++ -*-
// 
// history.js - Show edit history by moving time line.
// 
// Copyright (C) 2003-2005 Kouichirou Eto
//     All rights reserved.
//     This is free software with ABSOLUTELY NO WARRANTY.
// 
// You can redistribute it and/or modify it under the terms of 
// the GNU General Public License version 2.
// 

function History(xp) {
  this.xp = xp;
  this.windowWidth = this._getWidth();
  this.divlist = document.getDivListByClass("era");
  this.indicator = document.getElementById("indicator");
  this.eraWidth = this._calcEraWidth();
  this.lastdiv = null;
  this.lines = null;
  this.displayMode = false;
  this._drawRuler();
}

History.prototype = {
  _getWidth : function() {
    var cursorsize = 200;
    var minsize = 100;
    var w = 500; // adhoc
    if (document.body.clientWidth)
    w = document.body.clientWidth; // IE
    else if (window.innerWidth)
    w = window.innerWidth; // GK
    w = w - cursorsize;
    if (w < minsize) w = minsize;
    return w;
  },

  _moveDivs : function() {
    var o = document.getElementById("eratable");
    var left = o.style.offsetLeft;
    var top  = o.style.offsetTop;
    for (var i=0; i < this.divlist.length; i++) {
      var o = this.divlist[i];
      o.style.left = left;
      o.style.top  = top;
    }
  },

  _calcEraWidth : function() {
    return Math.floor(this.windowWidth / this.divlist.length);
  },

  _drawRuler : function() {
    var divlines = document.getElementById("lines");
    var ar = [];
    for (var i=0; i < this.divlist.length; i++) {
      var x = this.eraWidth * i;
      var div = this.divlist[i];
      var lineid = "vl"+div.id;
      var line = this._drawLine(lineid, divlines, x, 40, x, 48);
      ar.push(line);
    }
    this.lines = ar;
  },

  _drawLine : function(lineid, parent, x1, y1, x2, y2) {
    var o = document.createElement("v:line");
    o.id = lineid;
    parent.appendChild(o);
    o.style.visibility = "visible";
    o.setAttribute("strokeweight", "1");
    o.setAttribute("strokecolor",   "#009");
    o.style.position = "absolute";
    o.style.left = "0px";
    o.style.top  = "0px";
    var from = ""+x1+","+y1
    var to   = ""+x2+","+y2
    o.setAttribute("from", from);
    o.setAttribute("to",   to);
    return o
  },

  onMouseMove : function(p) {
    var i = Math.floor(p.x / this.eraWidth);
    var div = this.divlist[i];
    if (div == null) return;
    if (this.lastdiv) {
      if (this.lastdiv == div) return; // do nothing
      if (this.displayMode) this.lastdiv.style.display = "none";
      else this.lastdiv.style.visibility = "hidden";
    }
    this.lastdiv = div;

    if (this.displayMode) this.lastdiv.style.display = "block"; // show it
    else this.lastdiv.style.visibility = "visible";

    var date = new Date((div.id-0)*1000);
    this.indicator.innerHTML = date.toLocaleString();
  }
}

function qwik_onmousemove(p) {
  g_history.onMouseMove(p);
}

// global
if (typeof g_history == 'undefined') {
  var g_history = new History();
}
