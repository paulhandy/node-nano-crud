request = require 'request'
class Model
	constructor: (@database, @nano) ->
		@connect()
	connect: ->
		@db = @nano.use @database
	@customview: (name,fn) ->
		view = {}
		view["#{name}"] = map:fn.toString()
		view
	@combine: (names) ->
		view = {}
		map = "function(doc){if(doc && doc.type === '#{type}'){emit([#{"doc.#{name}" for name in names}],doc)}}"
		view["#{names.join('and')}"]= map:map
		view
	@field: (name,type, settings) ->
		view = {}
		if settings
			for val in settings
				view["by#{val}"] = map:"function (doc) { if (doc.#{name}.#{val} && doc.type === '#{type}'){emit(doc.#{name}.#{val},doc)}}"
		else
			view["by#{name}"] = map:"function (doc) { if (doc.#{name}&& doc.type === '#{type}'){emit(doc.#{name},doc)}}"
		view
	@views: (db,na,args,nano)->
		view = {}
		for field in args
			for key in Object.keys field
				view[key] = field[key]
		view.all = map: "function(doc){if(doc && doc.type === '#{na}'){emit(doc._id,doc)}}"
		mydb = nano.use db
		callback = (err,body) ->
			if err
				console.log 'could not update: ',err.reason, err
			else
				console.log "created views for #{na}"
		doc = {views:view, language:'javascript'}
		mydb.get "_design/#{na}",  (err, body) ->
			if err and err.reason is "no_db_file"
				nano.db.create db, (err,body) ->
					if err
						console.log err.reason
					else
						mydb = nano.use db
						mydb.insert doc, "_design/#{na}", callback
			else if err and err.reason is "missing"
				mydb.insert doc, "_design/#{na}", callback
			else
				if body and not compare body.views, view
					body.views = view
					console.log body
					console.log 'trying to update'
					mydb.insert  body, "_design/#{na}", callback
				else if not body
					mydb.insert doc, "_design/#{na}", callback
		return args

	find: (key, options, call) => @db.view "#{@design}",(if typeof key is 'string' then "by#{key}" else "#{key.join '_'}"), options, (error,response) -> if error then call error,null else call null, (if response.total_rows > 0 then obj.value for obj in response.rows else [])
	list: (call)=> @db.view "#{@design}","all", (error,response) -> if error then call error,null else call null, (if response.total_rows > 0 then obj.value for obj in response.rows else [])
	get: (keys, call) => @db.get(keys,{revs_info:true}, call)
	save: (doc, id, callback) => @db.insert doc,id, callback
	new: (doc, callback) => @db.insert doc,callback
	revert: (opt) => if opt.rev then @db.remove opt.id,opt.rev,opt.callback else @db.remove opt.id, opt.callback
	remove: (id, call) => @get id, (err,res) => if not err then @revert {id:res._id,rev:res._rev,callback: @remove res._id,call} else call err,res

	update: (doc,key, call) => @db.insert doc,key,call
	
	compare = (a,b) ->
		ak = Object.keys a
		bk = Object.keys b
		res = false
		if a is b
			res = true
		else if ak.length isnt bk.length
			res = false
		else if JSON.stringify(a) is JSON.stringify(b)
			res = true
		else if ak.length isnt bk.length
			res = false
		else
			k = 0
			if key isnt bk[k++] for key in ak
				res = false
			else
				console.log bk[k-1],key
				res = true
		res

module.exports = Model
