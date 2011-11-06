
# 
# Repub is a scraping and republishing tool for Node.JS. It allows you to 
# transform the textual result of CSS selectors on an arbitrary page into a data
# format. 
#

uniqueId = do ->
	count = 0
	-> "_repub_page_#{count++}"

class Page
	constructor: (@requestOptions) ->
		Page.pages[this._internalId = uniqueId()] = this

Page.pages = {}
Page.addPage = (pageName, page) ->
	Page.pages[pageName] = page

class PageCache
	constructor: (@id, @data) ->
		@timeCreated = Date.now()
	ageInSeconds: -> (Date.now() - @timeCreated) / 1000

PageCache.cache = {}
PageCache.maxAge = 10 #default maxAge 10 seconds.

# Add something to the cache - id to retrieve it by, and the data to store
PageCache.set = (id, data) -> PageCache.cache[id] = new PageCache id, data

# Get something from the cache. If nothing exists in the cache by the given 
# id, or the item has expired, nothing is returned
PageCache.get = (id) -> PageCache.cache[id].data if PageCache.exists id
	
# Check if something exists in the cache.
PageCache.exists = (id) ->
	return false if not PageCache.cache.hasOwnProperty id

	cache = PageCache.cache[id]
	if cache.ageInSeconds() > PageCache.maxAge
		PageCache.expire id
		return false
	return true


# Expire something in the cache
PageCache.expire = (id) -> delete PageCache.cache[id]

class Type
	constructor: (@structure, @scope) ->

Type.typeKeyword = '_type'
Type.scopeKeyword = '_scope'

class TypeRequest
	constructor: (@type, @page, @callback) ->
		@traverse @type
	
	# Recursive - takes a section of a type, decides what to do with it. If it is
	# a type itself, this will move on to readType which sets context. 
	traverse: (type, out = {}) ->
		# Check if this is a type - if so, we switch to that context and it will
		# continue the recursion by itself.
		return @readType type if @isType type

		# If this is a string then we've hit an endpoint and it's time to actually
		# fetch data from the doc. (Null is also valid).
		return @parseNode type if typeof type is 'string' or not type

		# Otherwise, we've got an object to iterate through.
		for key, value of type
			out[key] = @traverse value, out

		out

	# Returns true if 'obj' is a 'type'. This is qualified by it being truthy, and
	# owning both the 'Type.scopeKeyword' and 'Type.typeKeyword' keywords. By
	# default those are set to '_scope' and '_type' - but can be changed. 
	isType: (obj) ->
		obj and Type.scopeKeyword of obj and Type.typeKeyword of obj

		

request = (type, page, callback = ->) -> new TypeRequest type, page, callback

module.exports =
	Page: Page,
	Type: Type,
	PageCache: PageCache,
	addPage: Page.addPage,
	pages: Page.pages

