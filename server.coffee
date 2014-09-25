Db = require 'db'
Plugin = require 'plugin'

exports.client_new = (d) !->
	id = Db.shared.incr 'storyId'
	Db.shared.set 'stories', id,
		text: d.text
		title: d.title
		etime: 0|Plugin.time()
		comments: 0
		user: Plugin.userId()

checkPath = (path) !->
	for x in path
		if ''+(0|x) != ''+x
			throw new Error("invalid path term: "+x)

makePath = (path) ->
	res = []
	for x,n in path
		res.push 'c' if n
		res.push x
	res

exports.client_up = (path) !->
	checkPath path
	value = Db.personal().modify 'up', path.join(' '), (v) -> !v
	
	args = makePath path
	args.push 'etime', if value then 900 else -900
	
	stories = Db.shared.ref 'stories'
	stories.incr.apply stories, args

exports.client_reply = (path, text) !->
	checkPath path
	stories = Db.shared.ref 'stories'
	commentId = stories.incr(path[0], 'comments')
	args = makePath path
	args.push 'c', commentId,
		text: text
		etime: 0|Plugin.time()
		user: Plugin.userId()

	stories.set.apply stories, args

