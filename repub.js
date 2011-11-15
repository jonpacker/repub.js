(function() {
  var Page, PageCache, Type, TypeRequest, fs, http, jsdom, request, sizzle, uniqueId;
  http = require('http');
  jsdom = require('jsdom');
  fs = require('fs');
  sizzle = fs.readFileSync('./vendor/sizzle.js').toString();
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
      if (PageCache.exists(this._internalId)) {
        callback(null, PageCache.get(this._internalId));
      }
      return http.request(this.requestOptions, function() {
        var data;
        data = '';
        res.setEncoding('binary');
        res.on('data', function(chunk) {
          return data += chunk;
        });
        return res.on('end', function() {
          return jsdom.env({
            html: data,
            features: {
              QuerySelector: true
            },
            done: function(err, window) {
              if (err != null) {
                callback(err, null);
              }
              PageCache.set(this._internalId, window);
              return callback(null, window);
            }
          });
        });
      });
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
      this.page.request(function(err, window) {
        var result;
        if (err != null) {
          self.callback(err, null);
        }
        result = self.traverse(self.type, window.document);
        return self.callback(null, result);
      });
    }
    TypeRequest.prototype.readType = function(type, element) {
      var node, nodes, results, subtype, _i, _len;
      nodes = element.querySelectorAll(type[Type.scopeKeyword]);
      console.log("######");
      console.log("PARENT- " + (element.toString()));
      console.log("CHILDREN- " + (nodes.toString()));
      if (nodes.length === 0) {
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
      var node, _ref, _ref2;
      if (!(selector != null)) {
        return element != null ? (_ref = element.textContent) != null ? _ref.trim() : void 0 : void 0;
      }
      node = element.querySelector(selector);
      return node != null ? (_ref2 = node.textContent) != null ? _ref2.trim() : void 0 : void 0;
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
