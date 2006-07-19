// -*- c++ -*-
// Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
// This is free software with ABSOLUTELY NO WARRANTY.
// You can redistribute it and/or modify it under the terms of the GNU GPL 2.

// Thanks to Mr. Kan Fushihara for his first implementation.

// ============================== Point class
function Point(x, y) {
  if (typeof(x) == "number") {
    this.x = x;
    this.y = y;
    return;
  }
  if (typeof(x) == "string") {
    var xx = parseInt(x.replace("px", ""));
    var yy = parseInt(y.replace("px", ""));
    this.x = xx;
    this.y = yy;
    return;
  }
  this.x = 0;
  this.y = 0;
}

Point.prototype = {
  toString : function() {
    return "Point(" + this.x + ", " + this.y + ")";
  },

  plus : function(b) {
    return new Point(this.x + b.x, this.y + b.y);
  },

  minus : function(b) {
    return new Point(this.x - b.x, this.y - b.y);
  }
}

// ============================== XP (cross platform) class
function XP() {
  this.checkBrowser();
}

XP.prototype = {
  // Check browser type.  Only for test.
  checkBrowser : function() { 
    this.GK = 0;
    this.IE = 0;
    if (document.all) {
      this.IE = 1;
    } else if (document.getElementById) {
      this.GK = 1;
    }
  },

  ////////////////////////////// get
  getDivList : function() {
    if (document.getElementsByTagName) {
      return document.getElementsByTagName("div");
    }
    return null;
  },

  getDivListByClass : function(cn) {
    var div = document.getElementsByTagName("div");
    var n = [];
    for (var i=0; i < div.length; i++) {
      if (div[i].className == cn) {
	n.push(div[i]);
      }
    }
    return n;
  },

  ////////////////////////////// div control methods
  nu_setZIndex : function(e, z) {
    e.style.zIndex = z;
  },

  getPos : function(o) {
    if (!o) return;
    var s = o.style;
    var l = s.left;
    var t = s.top;
    if (!l || !t || l == "" || t == "") return new Point(0, 0); // no position
    var x = parseInt(l.replace("px", ""));
    var y = parseInt(t.replace("px", ""));
    return new Point(x, y);
  },

  setPos : function(o, p) {
    if (!o) return;
    o.style.left = p.x+"px";
    o.style.top  = p.y+"px";
  },

  getSize : function(o) {
    return new Point(o.offsetWidth, o.offsetHeight);
  },

  getCenter : function(o) {
    var p = this.getPos(o);
    var s = this.getSize(o);
    var cx = Math.floor(p.x + s.x / 2);
    var cy = Math.floor(p.y + s.y / 2);
    return new Point(cx, cy);
  },

  ////////////////////////////// event capture
  setMouseDown : function(e, ev) {
    e.onmousedown = ev;
  },

  setMouseUpMove : function(e, ev1, ev2) {
    e.onmouseup   = ev1;
    e.onmousemove = ev2;
  },

  ////////////////////////////// get event information
  getOffset : function(e, o) {
    var mp = this.getMousePos(e);
    if (this.GK) {
      var op = this.getPos(o);
    } else { // IE
      var op = new Point(o.style.posLeft, o.style.posTop);
    }
    return mp.minus(op);
  },

  getMousePos : function(e) {
    if (this.GK) {
      return new Point(e.pageX, e.pageY);
    } else { // IE, window.event is global.
      var x = window.event.clientX + document.body.scrollLeft;
      var y = window.event.clientY + document.body.scrollTop;
      return new Point(x, y);
    }
  },

  ////////////////////////////// for test
  showAllProperty : function(o) {
    var str = "";
    for (n in o) {
      str += (""+n+" is "+o[n]+"\t");
    }
    alert(str);
  }
}

// ============================== WEMA Editor
function WemaEditor(env) {
  this.env  = env;
  this.xp   = this.env.xp;
  this.id   = "editor";
  this.win  = document.getElementById(this.id);
  this.form = document.getElementById("frm");
  this.hide();
}

WemaEditor.prototype = {
  getMode : function() {
    if (this.win == null) return "hidden";
    return this.win.style.visibility;
  },

  _show : function() {
    this.env.showWindow("editor");
  },

  hide : function() {
    this.env.hideWindow("editor");
  },

  _clear : function() {
    this.form.id.value   = ""
    this.form.ln.value   = ""
    this.form.body.value = ""
  },

  _setPos : function(p) {
    var x = p.x;
    var y = p.y;
    if (x<0) x = 0;
    if (y<0) y = 0;
    this.form.l.value    = x+"px";
    this.form.t.value    = y+"px";
    this.win.style.left  = x+"px";
    this.win.style.top   = y+"px";
  },

  _setMousePos : function() {
    this._setPos(this.env.mouse);
  },

  createNewWema : function() {
    this._clear();
    this._setMousePos();
    this._show();
  },

  _setWemaPosition : function(id) {
    var w = this.env.wemas.get(id);
    if (!w) return; // get from wema
    this._setPos(w.getPos());
  },

  setPos : function(id) {
    this._setWemaPosition(id);
    this.form.id.value   = id;
    this.form.mode.value = "setpos";
    this.form.submit();
  },

  _setWemaValue : function(id) {
    var w = this.env.wemas.get(id);
    if (!w) return; // get from wema
    this.form.body.value = w.text;
    this.form.ln.value   = w.lineid;
    this.form.tc.value   = w.color;
    this.form.bg.value   = w.background;
  },

  editWema : function(id) {
    this._setWemaPosition(id);
    this.form.id.value   = id;
    this.form.mode.value = "edit";
    this._setWemaValue(id);
    this._show();
  },

  createNewLinkedWema : function(id) {
    this.createNewWema();
    this._setWemaPosition(id);
    this.form.ln.value   = id;
  },

  setColor : function(id, color) {
    var o = document.getElementById(id);
    if (!o) return;
    o.value = color;
  }
}

// ============================== WEMA Line
function WemaLine(wema) {
  this.wema = wema;
  this.xp   = this.wema.xp;
  this.lineColor = "#000";
  this.divmode = 1;
  if (this.xp.IE) this.divmode = false;
}

WemaLine.prototype = {
  toString : function() {
    return "<WemaLine("+this.wema.id+")>";
  },

  create : function() {
    if (this.divmode) {
      this._createDiv();
    } else {
      this._createVml();
    }
  },

  _createDiv : function() {
    this.obj = document.createElement("div");
    document.body.appendChild(this.obj);
    this.obj.className = "wema_line";
    this.line1 = document.createElement("div");
    this.line2 = document.createElement("div");
    this.obj.appendChild(this.line1);
    this.obj.appendChild(this.line2);
  },

  _createVml : function() {
    this.vline = document.createElement("v:line");
    this.vline.id = this.wema.id+"vl";
    document.body.appendChild(this.vline);
    var o = this.vline;
    o.style.visibility = "hidden";
    o.setAttribute("strokeweight", "1");
    o.setAttribute("strokecolor",   "#000");
    o.style.position = "absolute";
    o.style.left = "0px";
    o.style.top  = "0px";
  },

  hide : function() {
    if (this.divmode) {
      this.line1.style.visibility = "hidden";
      this.line2.style.visibility = "hidden";
    } else {
      this.vline.style.visibility = "hidden";
    }
  },

  draw : function(to) {
    var from = this.wema.id;
    //var f = this.xp.getById(from);
    var f = document.getElementById(from);
    if (!f) return;
    var t = document.getElementById(to);
    if (!t) return;
    var p1 = this.xp.getCenter(f);
    var p2 = this.xp.getCenter(t);
    if (this.divmode) {
      this._relocateDiv(this.line1, p1.x, p1.y, p1.x, p2.y);
      this._relocateDiv(this.line2, p1.x, p2.y, p2.x, p2.y);
    } else {
      this._relocateVml(p1, p2);
    }
  },

  _relocateDiv : function(o, x1, y1, x2, y2) {
    var s = o.style;
    s.visibility = "visible";
    s.backgroundColor = this.lineColor;
    s.position = "absolute";
    s.overflow = "hidden";
    s.left     = Math.min(x1,x2)+"px";
    s.top      = Math.min(y1,y2)+"px";
    s.width    = Math.abs(x2-x1+1)+"px";
    s.height   = Math.abs(y2-y1+1)+"px";
    s.zIndex   = "0";
  },

  _relocateVml : function(p1, p2) {
    var o = this.vline;
    o.style.visibility = "hidden";
    o.setAttribute("from", ""+p1.x+","+p1.y);
    o.setAttribute("to",   ""+p2.x+","+p2.y);
    o.style.visibility = "visible";
  }
}

// ============================== WEMA
function Wema(wemas, id) {
  this.wemas = wemas;
  this.xp    = this.wemas.xp;
  this.id    = id;
  this.obj   = document.getElementById(this.id);
  this._getAttr();
}

Wema.prototype = {
  _getAttr : function() {
    this.text   = this.obj.getAttribute("wema_d");
    this.lineid = this.obj.getAttribute("wema_ln");
    this.color  = this.obj.getAttribute("wema_tc");
    this.background = this.obj.getAttribute("wema_bg");
  },

  toString : function() {
    return "<Wema("+this.id+")>";
  },

  setPos : function(p) {
    this.xp.setPos(this.obj, p);
  },

  getPos : function() {
    return new Point(this.obj.style.left, this.obj.style.top);
  },

  setZIndex : function(z) {
    this.obj.style.zIndex = z;
  },

  getZIndex : function(z) {
    return parseInt(this.obj.style.zIndex);
  },

  createLine : function() {
    this.line  = new WemaLine(this);
    this.line.create();
  },

  drawLine : function() {
    var to = this.lineid;
    if (!to || to == "") {
      this.line.hide();
      return;
    }
    this.line.draw(to);
  }
}

// ============================== WEMA Set
function WemaSet(env) {
  this.env = env;
  this.xp  = env.xp;
  this.wlist = this._getWemaList();
  this.clearDragging();
}
WemaSet.prototype = {
  get : function(id) {
    return this.wlist[id];
  },

  clearDragging : function() {
    this.dragging = null;
  },

  getCurDragging : function() {
    return this.dragging; // current dragging wema object
  },

  startDragging : function(id) {
    this.dragging = this.get(id);
  },

  _getWemaList : function() {
    var wlist = this.xp.getDivListByClass("wema")
    var h = {}; // Hash
    for (var i=0; i < wlist.length; i++) {
      var id = wlist[i].id;
      if (id) {
	h[id] = new Wema(this, id); // set to Hash
      }
    }
    return h;
  },

  setZIndex : function(z) {
    for (id in this.wlist) {
      this.wlist[id].setZIndex(z);
    }
  },

  setMouseEvent : function() { // no test yet
    var ar = this.xp.getDivListByClass("menubar");
    for (var i=0; i < ar.length; i++) {
      this.xp.setMouseDown(ar[i], wema_mouse_down);
    }
    this.xp.setMouseUpMove(document, wema_mouse_up, wema_mouse_move);
  },

  createLines : function() {
    for (id in this.wlist)
    this.wlist[id].createLine();
  },

  drawLines : function() {
    for (id in this.wlist)
    this.wlist[id].drawLine();
  }
}

// ============================== WEMA Environment
function WemaEnvironment(xp) {
  this.xp = xp;
  this.wemas  = null;
  this.editor = null;
  this.offset = new Point(0, 0);
  this.mouse  = new Point(0, 0);
}
WemaEnvironment.prototype = {
  init : function() { // called from onLoad event
    this.wemas  = new WemaSet(this);
    this.editor = new WemaEditor(this);

    this.wemas.setMouseEvent();
    this.wemas.createLines();
    this.wemas.drawLines();

    var bodys = document.getElementsByTagName("body");
    var body = bodys.firstChild;
    if (!body) return;
    return body.setAttribute("ondblclick", "wema_dblClick;");
  },

  mouseDown : function(e, o) {
    while(1) {
      if (o.className == "wema") break;
      o = o.parentNode; // DOM
      if (!o) return;
    }

    if (this.editor.getMode() == "visible") {
      if (o.id != "editor") return;
    } else { // wema mode
      if (o.id == "editor") return;
    }

    this.offset = this.xp.getOffset(e, o);
    this.wemas.startDragging(o.id);
    this.wemas.setZIndex(1);
    this.wemas.getCurDragging().setZIndex(2);
    return false;
  },

  setCurMousePos : function(e) {
    this.mouse = this.xp.getMousePos(e);
  },

  mouseMove : function(e) {
    var w = this.wemas.getCurDragging();
    if (!w) return;
    this.setCurMousePos(e);
    var p = this.mouse.minus(this.offset);
    w.setPos(p);
    this.wemas.drawLines();
    if (typeof qwik_onmousemove != 'undefined') {
      qwik_onmousemove(p);
    }
    return false;
  },

  mouseUp : function(e) {
    this.wemas.clearDragging();
  },

  dblClick : function(e) {
    if (this.editor.getMode() != "visible") {
      this.setCurMousePos(e);
      this.editor.createNewWema();
    }
  },

  showHelp : function() {
    this.showWindow("help");
  },

  hideHelp : function() {
    this.hideWindow("help");
  },

  showWindow : function(id) {
    var o = document.getElementById(id);
    if (!o) return;
    o.style.visibility = "visible";
    o.style.zIndex = 2;
    this.wemas.clearDragging();
  },

  hideWindow : function(id) {
    var o = document.getElementById(id);
    if (!o) return;
    o.style.visibility = "hidden";
    o.style.zIndex = 0;
    this.wemas.clearDragging();
  }
}

// ============================== WemaHelp
function wema_create_help_window() {
  var str = '<div id="help" class="wema"><div class="menubar"><span class="handle">help</span><span class="close"><a href="javascript:wema_help_hide()">X</a></span></div><div class="cont"><h2>付箋機能ヘルプ</h2><h3>メニュー</h3><table><tr><td>new</td><td>新規付箋を作成</td></tr><tr><td>help</td><td>このウィンドウを表示</td></tr></table><p>右上の×をクリックして閉じます</p><h3>付箋コントロール</h3><table><tr><td>set</td><td>付箋を画面上で動かしてから<br/>「set」を押して，その場所に固定</td></tr><tr><td>edit</td><td>付箋の内容を編集</td></tr><tr><td>link</td><td>その付箋に線で繋がった新規付箋を作成</td></tr></table><h3>編集画面</h3><p>テキストエリアに付箋の文字列を入力し，<br/>「書き込み」ボタンを押してください．</p><p>付箋を消去するには，テキストエリアを<br/>全部消去してから保存してください．</p></div></div>';
  document.write(str);
}

// ============================== global
g_xp = new XP(); // global XP, used from test case
g_env = new WemaEnvironment(g_xp); // global Wema Environment

function wema_init() {
  g_env.init();
}

//onload = wema_init;
function wema_mouse_down(e) { return g_env.mouseDown(e, this); }
function wema_mouse_move(e) { return g_env.mouseMove(e); }
function wema_mouse_up(e)   { return g_env.mouseUp(e); }
function wema_setpos(a)     { g_env.editor.setPos(a); }
function wema_edit(a)       { g_env.editor.editWema(a); }
function wema_link(a)       { g_env.editor.createNewLinkedWema(a); }
function wema_set_color(a,b){ g_env.editor.setColor(a, b); }
function wema_editor_show() { g_env.editor.createNewWema();}
function wema_editor_hide() { g_env.editor.hide(); }
function wema_dblClick(e)   { g_env.dblClick(e);}

ondblclick = wema_dblClick;
function wema_help_show() { g_env.showHelp(); }
function wema_help_hide() { g_env.hideHelp(); }

//wema_init();
//wema_create_help_window();

// end
