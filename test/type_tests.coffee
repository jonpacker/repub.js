repub = require '../repub.js'

tests = 
	'test Type#constructor': (beforeExit, assert) ->
		typeStructure =
			testItem: 'div'

		type = new repub.Type typeStructure

		assert.eql type.structure, typeStructure
	'test Type#constructor with scope': (beforeExit, assert) ->
		typeStructure = testItem: 'div'
		type = new repub.Type typeStructure, 'div'

		assert.eql type.structure, typeStructure
		assert.equal type.scope, 'div'
	'test Type#constructure with null scope': (beforeExit, assert) ->
		typeStructure = testItem: 'div'
		type = new repub.Type typeStructure

		assert.ok !type.scope

module.exports = tests


