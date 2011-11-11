repub = require '../repub.js'
fs = require 'fs'

testPageFile = './test/testpage.html'
testTypeFile = './test/testpage_repub.json'

# Mock a page request by creating a dummy page and jamming our own stuff in the
# cache with the ID of the dummy. May also look at spoofing the cache time later
# so it never runs out.
loadData = (assert) ->
	# Dummy page
	page = new repub.Page host: 'www.google.com', port: 80

	# No reason not to do these synchronously in a test. May optimize later and
	# cache them ?
	data = fs.readFileSync testPageFile
	type = fs.readFileSync testTypeFile
	assert.ok data, "Couldn't read test page data from file: #{testPageFile}"
	assert.ok type, "Couldn't read test type data from file: #{testTypeFile}"

	# Dump it into the cache spoofing itself as the dummy page we made
	repub.PageCache.set page._internalId, data

	# Create our type
	type = new repub.Type JSON.parse type

	data: data, type: type, page: page, type: type


tests =
	'TypeRequest Basic Parsing': (beforeExit, assert) ->
		data = loadData assert
		
		repub.request data.type, data.page, (err, data) ->
			assert.isNull err, 'Request error was not null'
			assert.length data, 2

 'TypeRequest Parsing a Page (exact)': (beforeExit, assert) ->
		data = loadData assert
		repub.request data.type, data.page, (err, data) ->
			assert.isNull err, 'Request error was not null'
			assert.length data, 2
			
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

			assert.eql data, expectedStructure
		
module.exports = tests
