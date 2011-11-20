repub = require '../repub.js'
fs = require 'fs'
jsdom = require 'jsdom'
http = require 'http'
jQuerySrc = fs.readFileSync('./vendor/jquery-1.6.4.js').toString()

testPageFile = './test/testpage.html'
testTypeFile = './test/testpage_repub.json'
data = fs.readFileSync(testPageFile).toString()
type = JSON.parse fs.readFileSync(testTypeFile).toString()

page = new repub.Page { host: '127.0.0.1' }

server = do ->
	serverCallback = (req, res) ->
		res.writeHead 200, 'Content-Type': 'text/html'
		res.end data
	portbase = 10080
	servers = []

	setup: -> 
		newServer = http.createServer serverCallback
		port = portbase + servers.length
		newServer.listen port, '127.0.0.1'
		servers.push newServer
		port
	teardown: (port) ->
		theServer = servers[port-portbase]
		theServer.close()
		delete theServer

tests =
	'TypeRequest Calls Back': (beforeExit, assert) ->
		sd = server.setup()
		repubFinished = no
		beforeExit -> 
			assert.ok repubFinished, "Callback was never called"
			server.teardown sd if not repubFinished

		page.requestOptions.port = sd
		repub.request type, page, (err, result) ->
			repubFinished = yes
			server.teardown sd
		
	'TypeRequest Basic Parsing': (beforeExit, assert) ->
		sd = server.setup()

		page.requestOptions.port = sd
		repub.request type, page, (err, result) ->
			assert.isNull err, 'Request error was not null'
			assert.equal result.length, 2
			server.teardown sd

	'TypeRequest Parsing a Page (exact)': (beforeExit, assert) -> 
		sd = server.setup()

		page.requestOptions.port = sd
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
			server.teardown sd
	
module.exports = tests
