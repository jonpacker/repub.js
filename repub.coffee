
# 
# Repub is a scraping and republishing tool for Node.JS. It allows you to transform the textual result of CSS selectors
# on an arbitrary page into a data format. 
#
# First you'll need to create your pages. You can do that by using new repub.Page(<request object>). You will then pass
# these objects in your types so that repub knows which page to request data from. Alternatively, you can use
# repub.addPage(<name>, <page>) to assign a page to a string, which you can then use in your Type creation in place of
# the Page object itself.
#
# To create a type, make a new repub.Type(<structure>). The structure of a type should be similar to that following this
# paragraph. You can either use a selector to find some text verbatim (.textContent will be used to find the value, and 
# it will be trimmed first), or you can use a function which is passed the window object to do it yourself. 
#
#	{
#		'item': { 'page': page_or_page_id
#							'sel': selector_to_item },
#		'another_item': { 'page': page_or_page_id
#											'sel': function(window) { return document.querySelector('#test').textContent; } },
#		'array_of_items': [{ 'page': page_or_page_id,
#												 'sel': selector_to_items }] //a function here would take window AND the current index
#	}
#

