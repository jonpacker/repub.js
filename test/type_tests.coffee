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
	'test Type#constructor with null scope': (beforeExit, assert) ->
		typeStructure = testItem: 'div'
		type = new repub.Type typeStructure

		assert.ok !type.scope
	'test Type#read Raw Type': (be, assert) ->
		rawType = 
			_scope: '#something'
			_type: 
				aKey: 'aVal'
		
		type = new repub.Type rawType

		assert.eql type.structure, rawType._type, "Structure matches raw type"
		assert.equal type.scope, rawType._scope, "Scope matches raw type"
	'test Type#read nested Raw Type': (be, assert) ->
		rawType = 
			_scope: '#something'
			_type: 
				aKey: 'aValue'
				nestedType: 
					_scope: '#somethingElse'
					_type: 
						aNestedKey: 'aNestedValue'
						anotherNestedType: 
							_scope: '#yetSomethingElse',
							_type: 
								aNestedNested: 'aNestedNestedValue'
		
		type = new repub.Type rawType

		ntype = type.structure.nestedType

		assert.ok ntype, "Nested type exists"
		assert.ok ntype instanceof repub.Type, "Nested type is instance of Type"
		assert.ok 'aNestedKey' of ntype.structure, "Nested type inherited structure"

		nntype = ntype.structure.anotherNestedType;

		assert.ok nntype, "Sub-nested type exists"
		assert.ok nntype instanceof repub.Type, "Sub-nested type is instance of Type"
		assert.ok 'aNestedNested' of nntype.structure, "Sub-nested type inherited structure"
	'test Type#read Type obj': (be, assert) ->
		typeStructure = testItem: 'div'
		type = new repub.Type typeStructure, 'div'

		duplicateType = new repub.Type type

		assert.equal duplicateType.scope, type.scope
		assert.eql duplicateType.structure, type.structure
	'test Type#nested Types': (be, assert) ->
		typeStructure = testItem: 'div'
		type = new repub.Type typeStructure, 'div'

		type0Structure = 
			baseTestItem: 'div'
			nestedType: type
		type0 = new repub.Type type0Structure, 'div'

		type1Structure = 
			baserTestItem: 'div'
			baseNestedType: type0
		type1 = new repub.type type1Structure, 'div'

		assert.eql type1.structure, type1Structure
		
		ntype = type1.structure.baseNestedType

		assert.ok ntype
		assert.eql ntype.structure, type0Structure

		nntype = ntype.structure.nestedType

		assert.ok nntype
		assert.eql nntype.structure, typeStructure
		


module.exports = tests


