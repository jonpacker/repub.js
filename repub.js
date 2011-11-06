(function() {
  var Page, Type, uniqueId;
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
  Type = (function() {
    function Type(structure, scope) {
      this.structure = structure;
      this.scope = scope;
    }
    return Type;
  })();
  module.exports = {
    Page: Page,
    Type: Type,
    addPage: Page.addPage,
    pages: Page.pages
  };
}).call(this);
