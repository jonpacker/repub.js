(function() {
  var Page, PageCache, Type, TypeRequest, fs, http, jQuerySrc, jsdom, request, uniqueId;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  http = require('http');
  jsdom = require('jsdom');
  fs = require('fs');
  jQuerySrc = fs.readFileSync('./vendor/jquery-1.6.4.js').toString();
  uniqueId = (function() {
    var count;
    count = 0;
    return function() {
      return "_repub_page_" + (count++);
    };
  })();
  Page = (function() {
    function Page(requestOptions) {
      this.requestOptions = requestOptions;
      Page.pages[this._internalId = uniqueId()] = this;
    }
    Page.prototype.request = function(callback) {
      var req;
      if (PageCache.exists(this._internalId)) {
        callback(null, PageCache.get(this._internalId));
      }
      req = http.request(this.requestOptions, function(res) {
        var data;
        data = '';
        res.setEncoding('binary');
        res.on('data', function(chunk) {
          return data += chunk;
        });
        return res.on('end', function() {
          return jsdom.env({
            html: data,
            src: [jQuerySrc],
            done: function(err, window) {
              if (err != null) {
                callback(err, null);
              }
              console.log(window.$);
              PageCache.set(this._internalId, window);
              return callback(null, window);
            }
          });
        });
      });
      return req.end();
    };
    return Page;
  })();
  Page.pages = {};
  Page.addPage = function(pageName, page) {
    return Page.pages[pageName] = page;
  };
  PageCache = (function() {
    function PageCache(id, data) {
      this.id = id;
      this.data = data;
      this.timeCreated = Date.now();
    }
    PageCache.prototype.ageInSeconds = function() {
      return (Date.now() - this.timeCreated) / 1000;
    };
    return PageCache;
  })();
  PageCache.cache = {};
  PageCache.maxAge = 10;
  PageCache.set = function(id, data) {
    return PageCache.cache[id] = new PageCache(id, data);
  };
  PageCache.get = function(id) {
    if (PageCache.exists(id)) {
      return PageCache.cache[id].data;
    }
  };
  PageCache.exists = function(id) {
    var cache;
    if (!PageCache.cache.hasOwnProperty(id)) {
      return false;
    }
    cache = PageCache.cache[id];
    if (cache.ageInSeconds() > PageCache.maxAge) {
      PageCache.expire(id);
      return false;
    }
    return true;
  };
  PageCache.expire = function(id) {
    return delete PageCache.cache[id];
  };
  Type = (function() {
    function Type(structure, scope) {
      this.structure = structure;
      this.scope = scope;
    }
    return Type;
  })();
  Type.typeKeyword = '_type';
  Type.scopeKeyword = '_scope';
  TypeRequest = (function() {
    function TypeRequest(type, page, callback) {
      var self;
      this.type = type;
      this.page = page;
      this.callback = callback;
      self = this;
      if (this.type instanceof Type) {
        this.type = this.type.structure;
      }
      this.page.request(__bind(function(err, window) {
        var result;
        if (err != null) {
          this.callback(err, null);
        }
        this.context = window;
        result = this.traverse(this.type, window.document);
        return this.callback(null, result);
      }, this));
    }
    TypeRequest.prototype.readType = function(type, element) {
      var node, nodes, results, subtype, _i, _len;
      nodes = this.context.$(element).find(type[Type.scopeKeyword]).get();
      if (!(nodes != null) || nodes.length === 0) {
        return [];
      }
      subtype = type[Type.typeKeyword];
      results = [];
      for (_i = 0, _len = nodes.length; _i < _len; _i++) {
        node = nodes[_i];
        results.push(this.traverse(subtype, node));
      }
      return results;
    };
    TypeRequest.prototype.parseNode = function(selector, element) {
      if (!selector) {
        return this.context.$(element).text().trim();
      }
      return this.context.$(element).find(selector).first().text().trim();
    };
    TypeRequest.prototype.traverse = function(type, element) {
      var key, out, value;
      if (this.isType(type)) {
        return this.readType(type, element);
      }
      if (typeof type === 'string' || !(type != null)) {
        return this.parseNode(type, element);
      }
      out = {};
      for (key in type) {
        value = type[key];
        out[key] = this.traverse(value, element);
      }
      return out;
    };
    TypeRequest.prototype.isType = function(obj) {
      return (obj != null) && typeof obj === 'object' && Type.scopeKeyword in obj && Type.typeKeyword in obj;
    };
    return TypeRequest;
  })();
  request = function(type, page, callback) {
    if (callback == null) {
      callback = function() {};
    }
    return new TypeRequest(type, page, callback);
  };
  module.exports = {
    Page: Page,
    Type: Type,
    PageCache: PageCache,
    addPage: Page.addPage,
    pages: Page.pages,
    request: request
  };
}).call(this);
