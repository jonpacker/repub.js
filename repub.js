(function() {
  var Page, PageCache, Type, TypeRequest, request, uniqueId;
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
      this.type = type;
      this.page = page;
      this.callback = callback;
      this.traverse(this.type);
    }
    TypeRequest.prototype.traverse = function(type, out) {
      var key, value;
      if (out == null) {
        out = {};
      }
      if (this.isType(type)) {
        return this.readType(type);
      }
      if (typeof type === 'string' || !type) {
        return this.parseNode(type);
      }
      for (key in type) {
        value = type[key];
        out[key] = this.traverse(value, out);
      }
      return out;
    };
    TypeRequest.prototype.isType = function(obj) {
      return obj && Type.scopeKeyword in obj && Type.typeKeyword in obj;
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
    pages: Page.pages
  };
}).call(this);
