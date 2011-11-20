repub = require '../repub.js'
fs = require 'fs'
jsdom = require 'jsdom'
http = require 'http'
jQuerySrc = fs.readFileSync('./vendor/jquery-1.6.4.js').toString()

testPageFile = './test/testpage.html'
testTypeFile = './test/testpage_repub.json'
data = fs.readFileSync(testPageFile).toString()
type = JSON.parse fs.readFileSync(testTypeFile).toString()

page = new repub.Page { host: '127.0.0.1', port: 8080 }

serverCallback = (req, res) ->
	res.writeHead 200, 'Content-Type': 'text/html'
	res.end data

server = http.createServer serverCallback
server.listen 8080, '127.0.0.1'

testCount = 0
testStart = (cb) -> 
	return cb() if testCount++ > 0
	server.listen 8080, '127.0.0.1', cb
testFinished = -> 
	if --testCount <= 0
		server.close();
	

tests =
	'TypeRequest Calls Back': (beforeExit, assert) ->
		testStart ->
			repubFinished = no
			beforeExit -> 
				assert.ok repubFinished, "Callback was never called"
				testFinished()
			repub.request type, page, (err, result) ->
				repubFinished = yes
		
	'TypeRequest Basic Parsing': (beforeExit, assert) ->
		testStart ->
			beforeExit -> testFinished()
			repub.request type, page, (err, result) ->
				assert.isNull err, 'Request error was not null'
				assert.equal result.length, 2

	'TypeRequest Parsing a Page (exact)': (beforeExit, assert) -> 
		testStart ->
			beforeExit -> testFinished()
			repub.request type, page, (err, result) ->
				assert.isNull err, 'Request error was not null'
				assert.equal result.length, 2
			
				expectedStructure = [{
						title: 'testTitle1',
						items: ['testSubItem1', 'testSubItem2', 'testSubItem3'],
						possible_items: [{ title: 'seSubTitle1', detail: 'seSubDetail1' },
														 { title: 'seSubTitle2', detail: 'seSubDetail2' }]
					}, {
						title: 'testTitle2',
						items: ['subTestSubItem1', 'subTestSubItem2', 'subTestSubItem3'],
						possible_items: []
					}]

				assert.eql result, expectedStructure
	
module.exports = tests
