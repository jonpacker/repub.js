repub = require '../repub.js'
fs = require 'fs'
jsdom = require 'jsdom'

testPageFile = './test/testpage.html'
testTypeFile = './test/testpage_repub.json'

# Mock a page request by creating a dummy page and jamming our own stuff in the
# cache with the ID of the dummy. May also look at spoofing the cache time later
# so it never runs out.
loadData = (assert, callback) ->
	# Dummy page
	page = new repub.Page host: 'www.google.com', port: 80

	# No reason not to do these synchronously in a test. May optimize later and
	# cache them ?
	data = fs.readFileSync(testPageFile).toString()
	type = fs.readFileSync(testTypeFile).toString()
	assert.ok data, "Couldn't read test page data from file: #{testPageFile}"
	assert.ok type, "Couldn't read test type data from file: #{testTypeFile}"

	# Dump it into the cache spoofing itself as the dummy page we made
	# repub.PageCache.set page._internalId, data

	# Create our type
	type = new repub.Type JSON.parse type


	# Load up the DOM
	jsdom.env 
		html: data
		scripts: repub.ElementSelector.current().scripts
		features:
				QuerySelector: true
		done: (err, window) ->
			repub.PageCache.set page._internalId, window
			callback type, page


tests =
	'TypeRequest Calls Back': (beforeExit, assert) ->
		repubFinished = no
		loadData assert, (type, page) ->
			repub.request type, page, (err, result) ->
				repubFinished = yes
		
		beforeExit -> assert.ok repubFinished, "Callback was never called"

	'TypeRequest Basic Parsing': (beforeExit, assert) ->
		loadData assert, (type, page) ->
			repub.request type, page, (err, result) ->
				assert.isNull err, 'Request error was not null'
				assert.length result, 2

 	'TypeRequest Parsing a Page (exact)': (beforeExit, assert) ->
		loadData assert, (type, page) ->
			repub.request type, page, (err, result) ->
				assert.isNull err, 'Request error was not null'
				assert.length result, 2
			
				expectedStructure = [{
						title: 'testTitle1',
						items: ['testSubItem1', 'testSubItem2', 'testSubItem3'],
						possible_items: [{ title: 'seSubTitle1', detail: 'seSubDetail1' },
														 { title: 'seSubTitle2', detail: 'seSubDetail2' }]
					}, {
						title: 'testTitle2',
						items: ['subTestSubItem1', 'subTestSubItem2', 'subTestSubItem3'],
						possible_items: null
					}]

				console.log expectedStructure
				assert.eql result, expectedStructure
		
module.exports = tests
