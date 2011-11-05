repub = require '../repub.js'

tests =
	'test Page#init': (beforeExit, assert) ->
		requestOptions = 
			host: 'google.com'
			port: 80
			path: '/'
			method: 'GET'

		page = new repub.Page requestOptions
		assert.eql requestOptions, page.requestOptions
	'test addPage': (beforeExit, assert) ->
		page = new repub.Page
			host: 'google.com'
			port: 80

		repub.addPage 'test_page', page
		assert.includes repub.pages, 'test_page'
		assert.eql repub.pages['test_page'], page

module.exports = tests
