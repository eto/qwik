/* 
 * XMLFormatter - a simple class for generating XML texts
 *
 * Copyright (C) 2004-2005 Keisuke Nishida <knishida@open-cobol.org>
 * Copyright (C) 2005 Kouichirou Eto <2005 at eto.com>
 *     All rights reserved.
 *     This is free software with ABSOLUTELY NO WARRANTY.
 * 
 * You can redistribute it and/or modify it under the terms of 
 * the GNU General Public License version 2.
 */

/* copied from gonzui-0.3 */
/* Extend some functions by Kouichirou Eto, 2005-02-11 */

#include <ruby.h>
#include <st.h>

#define BLOCK_SIZE	(128 * 1024)	/* 128 KB */

typedef struct gonzui_xmlformatter {
  char *data;
  size_t size;
  size_t max_size;
} gonzui_xmlformatter_t;

static gonzui_xmlformatter_t *xmlformatter_new(void)
{
  gonzui_xmlformatter_t *xf = malloc(sizeof(gonzui_xmlformatter_t));
  memset(xf, 0, sizeof(gonzui_xmlformatter_t));
  xf->max_size = BLOCK_SIZE;
  xf->size = 0;
  xf->data = malloc(xf->max_size);
  return xf;
}

static void xmlformatter_write(gonzui_xmlformatter_t *xf, char *data)
{
  long size = strlen(data);
  if (xf->size + size > xf->max_size) {
    xf->max_size += BLOCK_SIZE;
    xf->data = realloc(xf->data, xf->max_size);
  }
  memcpy(xf->data + xf->size, data, size);
  xf->size += size;
}

static void xmlformatter_write_str(gonzui_xmlformatter_t *xf, VALUE obj)
{
  char *data;  
  size_t size;

  struct RString *s = RSTRING(rb_obj_as_string(obj));
  data = s->ptr;
  size = s->len;

  if (xf->size + size * 6 > xf->max_size) { // Why * 6?
    xf->max_size += BLOCK_SIZE;
    xf->data = realloc(xf->data, xf->max_size);
  }
  memcpy(xf->data + xf->size, data, size);
  xf->size += size;
}

static void xmlformatter_write_obj(gonzui_xmlformatter_t *xf, VALUE obj)
{
  char *p;
  char *data;
  size_t size;
  if (SYMBOL_P(obj)) {
    data = rb_id2name(SYM2ID(obj));
    size = strlen(data);
  } else {
    struct RString *s = RSTRING(rb_obj_as_string(obj));
    data = s->ptr;
    size = s->len;
  }
  if (size == 0)
    return;

  if (xf->size + size * 6 > xf->max_size) {
    xf->max_size += BLOCK_SIZE;
    xf->data = realloc(xf->data, xf->max_size);
  }
  for (p = data; *p; p++) {
    int c = *p;
    if (c == '<') {
      memcpy(xf->data + xf->size, "&lt;", 4);
      xf->size += 4;
    } else if (c == '>') {
      memcpy(xf->data + xf->size, "&gt;", 4);
      xf->size += 4;
    } else if (c == '&') {
      memcpy(xf->data + xf->size, "&amp;", 5);
      xf->size += 5;
    } else if (c == '"') {
      memcpy(xf->data + xf->size, "&quot;", 6);
      xf->size += 6;
    } else {
      xf->data[xf->size++] = c;
    }
  }
}

static void xmlformatter_free(gonzui_xmlformatter_t *xf)
{
  if (xf == NULL)
    return;
  free(xf->data);
  free(xf);
}

static VALUE xmlformatter_s_allocate(VALUE klass)
{
  return Data_Wrap_Struct(klass, NULL, xmlformatter_free, NULL);
}

static VALUE xmlformatter_initialize(VALUE self)
{
  gonzui_xmlformatter_t *xf;
  Data_Get_Struct(self, gonzui_xmlformatter_t, xf);
  if (xf)
    rb_raise(rb_eArgError, "called twice");

  DATA_PTR(self) = xmlformatter_new();
  return self;
}

static VALUE xmlformatter_add_xml_declaration(VALUE self)
{
  gonzui_xmlformatter_t *xf;
  Data_Get_Struct(self, gonzui_xmlformatter_t, xf);
  if (xf)
    xmlformatter_write(xf, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
  return Qnil;
}

static VALUE xmlformatter_add_doctype(VALUE self)
{
  gonzui_xmlformatter_t *xf;
  Data_Get_Struct(self, gonzui_xmlformatter_t, xf);
  if (xf)
    xmlformatter_write(xf, "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n"
		       "    \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n");
  return Qnil;
}

static int format_hash(VALUE key, VALUE val, gonzui_xmlformatter_t *xf)
{
  xmlformatter_write(xf, " ");
  xmlformatter_write_obj(xf, key);
  xmlformatter_write(xf, "=\"");
  xmlformatter_write_obj(xf, val);
  xmlformatter_write(xf, "\"");
  return ST_CONTINUE;
}

static void format(gonzui_xmlformatter_t *xf, VALUE xml)
{
  if (rb_type(xml) == T_ARRAY) {
    /* array */
    long i = 0;
    long len = RARRAY(xml)->len;
    VALUE *a = RARRAY(xml)->ptr;
    VALUE tag;

    if (len == 0) {
      xmlformatter_write(xf, "");
      return;
    }

    /* start tag */
    tag = a[i++];

    if (SYMBOL_P(tag)) {

      /* XML Declatation */
      if (strncmp(rb_id2name(SYM2ID(tag)), "?xml", 4) == 0) {
	xmlformatter_write(xf, "<?xml");
	if (2 <= len) {
	  xmlformatter_write(xf, " version=\"");
	  xmlformatter_write_obj(xf, a[i++]);
	  xmlformatter_write(xf, "\"");
	}
	if (3 <= len) {
	  xmlformatter_write(xf, " encoding=\"");
	  xmlformatter_write_obj(xf, a[i++]);
	  xmlformatter_write(xf, "\"");
	}
	if (4 <= len) {
	  xmlformatter_write(xf, " standalone=\"");
	  xmlformatter_write_obj(xf, a[i++]);
	  xmlformatter_write(xf, "\"");
	}
	xmlformatter_write(xf, "?>");
	return;
      }

      /* doctype */
      if (strncmp(rb_id2name(SYM2ID(tag)), "!DOCTYPE", 8) == 0) {
	if (len != 5) {
	  rb_raise(rb_eArgError, "does not match argument number");
	}
	xmlformatter_write(xf, "<!DOCTYPE ");
	xmlformatter_write_obj(xf, a[i++]);
	xmlformatter_write(xf, " ");
	xmlformatter_write_obj(xf, a[i++]);
	xmlformatter_write(xf, " \"");
	xmlformatter_write_obj(xf, a[i++]);
	xmlformatter_write(xf, "\" \"");
	xmlformatter_write_obj(xf, a[i++]);
	xmlformatter_write(xf, "\">");
	return;
      }

      /* comment */
      if (strncmp(rb_id2name(SYM2ID(tag)), "!--", 3) == 0) {
	xmlformatter_write(xf, "<!--");
	xmlformatter_write_str(xf, a[i++]);
	xmlformatter_write(xf, "-->");
	return;
      }

      /* cdata */
      if (strncmp(rb_id2name(SYM2ID(tag)), "![CDATA[", 8) == 0) {
	xmlformatter_write(xf, "<![CDATA[");
	xmlformatter_write_str(xf, a[i++]);
	xmlformatter_write(xf, "]]>");
	return;
      }

      /* start tag */
      xmlformatter_write(xf, "<");
      xmlformatter_write_obj(xf, tag);

      /* attributes */
      if (i < len && rb_type(a[i]) == T_HASH) {
	st_foreach(RHASH(a[i++])->tbl, format_hash, (st_data_t)xf);
      }

      /* body, end tag */
      if (i >= len) {
	xmlformatter_write(xf, "\n/>");
      } else {
	xmlformatter_write(xf, "\n>");
	for (; i < len; i++) {
	  format(xf, a[i]);
	}
	xmlformatter_write(xf, "</");
	xmlformatter_write_obj(xf, tag);
	xmlformatter_write(xf, "\n>");
      }
    } else {
      for (i = 0; i < len; i++)
	format(xf, a[i]);
    }
  } else {
    /* other object */
    xmlformatter_write_obj(xf, xml);
  }
}

static VALUE xmlformatter_format(VALUE self, VALUE xml)
{
  gonzui_xmlformatter_t *xf;
  Data_Get_Struct(self, gonzui_xmlformatter_t, xf);
  if (xf == NULL)
    return Qnil;
  Check_Type(xml, T_ARRAY);
  format(xf, xml);
  return rb_str_new(xf->data, xf->size);
}

void Init_xmlformatter()
{
  VALUE Gonzui = rb_define_module("Gonzui");
  VALUE XMLFormatter = rb_define_class_under(Gonzui, "XMLFormatter", rb_cData);
  rb_define_alloc_func(XMLFormatter, xmlformatter_s_allocate);
  rb_define_method(XMLFormatter, "initialize", xmlformatter_initialize, 0);
  rb_define_method(XMLFormatter, "add_xml_declaration", xmlformatter_add_xml_declaration, 0);
  rb_define_method(XMLFormatter, "add_doctype", xmlformatter_add_doctype, 0);
  rb_define_method(XMLFormatter, "format", xmlformatter_format, 1);
}
