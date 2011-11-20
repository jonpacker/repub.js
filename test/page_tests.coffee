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

		assert.notEqual page0.id, page1.id
		assert.notEqual page0.id, page2.id

module.exports = tests
