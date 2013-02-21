Couch = require '../couch'
class Exhibit extends Couch
	constructor: (nano) ->
		@design = 'exhibit'
		super 'akds', nano

module.exports = (nano) ->
	Exhibit.views 'akds', 'exhibit', [
		Exhibit.field('resources','exhibit')
		Exhibit.field('exhibitName','exhibit')
		Exhibit.field('exhibitUrl','exhibit')
	], nano
	return new Exhibit(nano)
