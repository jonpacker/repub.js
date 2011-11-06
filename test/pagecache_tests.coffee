repub = require '../repub.js'

tests =
	'PageCache#set': (beforeExit, assert) ->
		cachedPageData = 'this is some data 123 123'
		
		repub.PageCache.set 'test_page', cachedPageData

		assert.ok repub.PageCache.cache.hasOwnProperty 'test_page'
		assert.eql repub.PageCache.cache['test_page'].data, cachedPageData
		
	'PageCache#set - overwrite': (beforeExit, assert) ->
		cachedPageData1 = 'this is some data 123 123'
		cachedPageData2 = 'this is some data 456 456'

		repub.PageCache.set 'test_page', cachedPageData1
		repub.PageCache.set 'test_page', cachedPageData2

		assert.notEqual repub.PageCache.cache['test_page'].data, cachedPageData1
	
	'PageCache#get': (beforeExit, assert) ->
		cachedPageData = 'test data'
		repub.PageCache.set 'test_page', cachedPageData

		assert.equal (repub.PageCache.get 'test_page'), cachedPageData

	'PageCache#exists': (beforeExit, assert) ->
		cachedPageData = 'test data'
		repub.PageCache.set 'test_page', cachedPageData

		assert.ok repub.PageCache.exists 'test_page'

	'PageCache#expire': (beforeExit, assert) ->
		cachedPageData = 'test data'
		repub.PageCache.set 'test_page', cachedPageData
		repub.PageCache.expire 'test_page'

		assert.ok !repub.PageCache.exists 'test_page'
		assert.ok !repub.PageCache.get 'test_page'

	'PageCache#get after maxAge': (beforeExit, assert) ->
		cachedPageData = 'test data'
		repub.PageCache.set 'test_page', cachedPageData
		repub.PageCache.maxAge = 0.2

		setTimeout (-> assert.ok !assert.isUndefined repub.PageCache.get 'test_page'), 250

module.exports = tests
