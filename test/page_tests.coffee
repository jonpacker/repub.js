repub = require '../repub.js'

tests =
	# Test the init function of Page, which assigns requestOptions
	'test Page#init': (beforeExit, assert) ->
		requestOptions = 
			host: 'google.com'
			port: 80

			path: '/'
			method: 'GET'

		page = new repub.Page requestOptions
		assert.eql requestOptions, page.requestOptions

	# Test the _internalId of Page, which should always be unique.
	'test Page#_internalId': (beforeExit, assert) ->
		page0 = new repub.Page host: 'google.com', port: 80
		page1 = new repub.Page host: 'nrk.no', port: 80
		page2 = new repub.Page host: 'finn.no', port: 80

		assert.notEqual page0._internalId, page1._internalId
		assert.notEqual page0._internalId, page2._internalId

	# Test the addPage method which assigns a page to a given identifier.
	'test addPage': (beforeExit, assert) ->
		page = new repub.Page
			host: 'google.com'
			port: 80

		repub.addPage 'test_page', page
		assert.ok repub.pages.hasOwnProperty 'test_page'
		assert.eql repub.pages['test_page'], page

module.exports = tests
