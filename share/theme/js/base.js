// -*- c++ -*-
//
// Copyright (C) 2003-2006 Kouichirou Eto
//     All rights reserved.
//     This is free software with ABSOLUTELY NO WARRANTY.
//
// You can redistribute it and/or modify it under the terms of 
// the GNU General Public License version 2.
//

// ============================== common
function getById(id) {
  if (document.getElementById) {
    elem = document.getElementById(id);
    return elem;
  }
  if (document.all) return document.all(id);
  return null;
}

function getByName(name) {
  if (document.getElementsByTagName)
  return document.getElementsByTagName(name);
  if (document.all) return document.all.tags(name);
  return null;
}

function qwik_onload() {
  if (typeof wema_init != 'undefined') {
    //g_debug.pa("wema_init");
    wema_init();
  }

  if (typeof g_toc == 'undefined') {
    g_toc = new TOC();
    g_toc.init();
  }

  if (typeof g_niftypp != 'undefined') {
    g_niftypp.applyAll();
  }

  if (typeof g_focus != 'undefined') {
    g_focus.apply();
  }

  /*
  if (typeof g_menu == 'undefined') {
    g_menu = new Menu();
    g_menu.init();
  }
  */
}

// ============================== table edit
function show_new_col() {
  ns = document.getElementsByClass("*", "new_col");
  for (var i=0; i < ns.length; i++) {
    ns[i].style.display = "block";
  }

  ns = document.getElementsByClass("*", "new_col_button");
  for (var i=0; i < ns.length; i++) {
    ns[i].style.display = "none";
  }
}

function show_new_row() {
  ns = document.getElementsByClass("*", "new_row");
  for (var i=0; i < ns.length; i++) {
    ns[i].style.display = "block";
  }

  ns = document.getElementsByClass("*", "new_row_button");
  for (var i=0; i < ns.length; i++) {
    ns[i].style.display = "none";
  }
}

// ============================== common
document.getElements = function(tagname) {
  if (document.getElementsByTagName) {
    return document.getElementsByTagName(tagname);
  }
  if (document.all) {
    return document.all.tags(tagname);
  }
  if (document.layers) {
    return document.layers;
  }
  return null;
}

document.getElementsByClass = function(tagname, classname) {
  var elements = document.getElements(tagname);
  var newelements = [];
  for (var i=0; i < elements.length; i++)
    if (elements[i].className == classname) {
      newelements.push(elements[i]);
    }
  return newelements;
}

document.getDivList = function() {
  if (document.getElementsByTagName) {
    return document.getElementsByTagName("div");
  }
  if (document.all) {
    return document.all.tags("div");
  }
  if (document.layers) {
    return document.layers;
  }
  return null;
}

document.getDivListByClass = function(cn) {
  var div = document.getDivList();
  var n = [];
  for (var i=0; i < div.length; i++)
    if (div[i].className == cn) n.push(div[i]);
  return n;
}

// ============================== focus
function Focus() {
}

Focus.prototype = {
  apply: function() {
    ar = document.getElementsByTagName("input");
    this.findFocus(ar);
    ar = document.getElementsByTagName("textarea");
    this.findFocus(ar);
  },

  findFocus: function(ar) {
    for (var i=0; i < ar.length; i++) {
      var e = ar[i];
      if (e.className == "focus") {
	e.focus();
      }
    }
  }
}

var g_focus = new Focus();

// ============================== toc
var g_toc;

function TOC() {
  this.init = function() {
    var t = getById("toc");
    if (!t) return;
    var h = t.firstChild;
    if (!h) return;
    if (h.nodeName != "H5") return;
    h.onmousedown = this.toggle;
    this.toggle();
  }

  this.toggle = function() {
    var t = getById("toc");
    if (!t) return;
    var i = getById("tocinside");
    if (!i) return;
    if (i.style.display == "none"){
      i.style.display = "block";
    }else{
      var w = t.clientWidth;
      i.style.display = "none";
      t.style.width = w+"px";
    }
  }
}
