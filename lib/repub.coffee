
# 
# Repub is a scraping and republishing tool for Node.JS. It allows you to 
# transform the textual result of CSS selectors on an arbitrary page into a data
# format. 
#

http = require 'http'
jsdom = require 'jsdom'
fs = require 'fs'

options = 
	elementSelector: 'jquery'

uniqueId = do ->
	count = 0
	-> "_repub_page_#{count++}"

class Page
	constructor: (@requestOptions) ->
		Page.pages[@_internalId = uniqueId()] = this
	request: (callback) ->
		callback null, PageCache.get @_internalId if PageCache.exists @_internalId

		scriptsToUse = ElementSelector.current().scripts
		http.request @requestOptions, ->
			data = ''
			res.setEncoding 'binary'
			res.on 'data', (chunk) -> data += chunk
			res.on 'end', -> jsdom.env
				html: data
				scripts: scriptsToUse
				features:
					# going to have to do something about this when native impl is used - can't
					# just include a script like other ElementSelectors. Or can we? todo: look up
					# polyfills.
					QuerySelector: false 
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
		nodes = querySelectorAll @context, element, type[Type.scopeKeyword]

		return [] if not nodes? or nodes.length is 0

		subtype = type[Type.typeKeyword]
		results = []

		results.push @traverse subtype, node for node in nodes

		return results

	parseNode: (selector, element) ->
		# If !selector, return all text content of the current element
		return element?.textContent?.trim() if not selector?
		node = querySelector @context, element, selector
		return node?.textContent?.trim()

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

# An ElementSelector has one method of interest, it takes a jsdom context (window),
# an element as context (element), and a selector to find child elements by. This is
# needed because of a bug (#364) in jsdom that fails when selecting descendant elements.
#
# The ElementSelector class allows us to create multiple implementations of element
# filtering, so we can insert jQuery in here.
#
# Obviously if you want to use jQuery you need to include it, and that's what the (scripts)
# var is all about. It will be joined onto any other scrips repub decides to use and 
# assimilated with all doms, so it will be there to use in your window context
class ElementSelector
	constructor: (@querySelectorAll, @scripts...) ->

	# Maybe some performance improvements to make here?
	querySelector: (window, element, selector) ->
		result = @querySelectorAll window, element, selector 
		return undefined if not result or not result?.length
		result[0]

ElementSelector.all = do ->
	jqueryCode = fs.readFileSync './vendor/jquery-1.6.4.js', 'utf8'
	jquerySelect = (window, element, selector) -> 
		window?.$?(element)?.find?(selector)?.get?()

	jqueryElementSelector = new ElementSelector jquerySelect, jqueryCode
	jqueryElementSelector.querySelector = (window, element, selector) ->
		window?.$?(element)?.find?(selector)?.first?()?.get?() #minor opt

	# native implementation, for when jsdom bug is fixed. DO NOT USE YET.
	nativeSelect = (window, element, selector) -> element?.querySelectorAll?(selector)
	nativeElementSelector = new ElementSelector nativeSelect
	nativeElementSelector.querySelector = (window, element, selector) ->
		element?.querySelector?(selector)

	return jquery: jqueryElementSelector, native: nativeElementSelector

# Returns the selector currently specified in options
ElementSelector.current = -> ElementSelector.all[options.elementSelector]

# Local namespace convenience methods
querySelectorAll = (window, element, selector) ->
	ElementSelector.current().querySelectorAll window, element, selector
querySelector = (window, element, selector) ->
	ElementSelector.current().querySelector window, element, selector

request = (type, page, callback = ->) -> new TypeRequest type, page, callback

module.exports =
	Page: Page,
	Type: Type,
	PageCache: PageCache,
	addPage: Page.addPage,
	pages: Page.pages,
	request: request,
	options: options,
	ElementSelector: ElementSelector


