
# 
# Repub is a scraping and republishing tool for Node.JS. It allows you to 
# transform the textual result of CSS selectors on an arbitrary page into a data
# format. 
#

http = require 'http'
jsdom = require 'jsdom'
fs = require 'fs'

jQuerySrc = fs.readFileSync('./vendor/jquery-1.6.4.js').toString()

uniqueId = do ->
	count = 0
	-> "_repub_page_#{count++}"

class Page
	constructor: (@requestOptions) ->
		Page.pages[@_internalId = uniqueId()] = this
	request: (callback) ->
		callback null, PageCache.get @_internalId if PageCache.exists @_internalId

		http.request @requestOptions, ->
			data = ''
			res.setEncoding 'binary'
			res.on 'data', (chunk) -> data += chunk
			res.on 'end', -> jsdom.env
				html: data
				src: [jQuerySrc]
				done: (err, window) ->
					callback err, null if err?
					PageCache.set @_internalId, window
					callback null, window

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
		self = this

		@type = @type.structure if @type instanceof Type

		@page.request (err, window) =>
			@callback err, null if err?
			@context = window
			result = @traverse @type, window.document
			@callback null, result
	
	readType: (type, element) ->
		nodes = @context.$(element).find(type[Type.scopeKeyword]).get()

		return [] if not nodes? or nodes.length is 0

		subtype = type[Type.typeKeyword]
		results = []

		results.push @traverse subtype, node for node in nodes

		return results

	parseNode: (selector, element) ->
		# If !selector, return all text content of the current element
		return @context.$(element).text().trim() if not selector
		@context.$(element).find(selector).first().text().trim()

	# Recursive - takes a section of a type, decides what to do with it. If it is
	# a type itself, this will move on to readType which sets context. 
	traverse: (type, element) ->
	
		# Check if this is a type - if so, we switch to that context and it will
		# continue the recursion by itself.
		return @readType type, element if @isType type

		# If this is a string then we've hit an endpoint and it's time to actually
		# fetch data from the doc. (Null is also valid).
		return @parseNode type, element if typeof type is 'string' or not type?

		# Otherwise, we've got an object to iterate through.
		out = {}
		for key, value of type
			out[key] = @traverse value, element
		out

	# Returns true if 'obj' is a 'type'. This is qualified by it being truthy, and
	# owning both the 'Type.scopeKeyword' and 'Type.typeKeyword' keywords. By
	# default those are set to '_scope' and '_type' - but can be changed. 
	isType: (obj) ->
		obj? and 
		typeof obj is 'object' and 
		Type.scopeKeyword of obj and 
		Type.typeKeyword of obj		

request = (type, page, callback = ->) -> new TypeRequest type, page, callback

module.exports =
	Page: Page,
	Type: Type,
	PageCache: PageCache,
	addPage: Page.addPage,
	pages: Page.pages,
	request: request


