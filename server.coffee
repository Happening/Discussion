Db = require 'db'
Plugin = require 'plugin'

exports.client_new = (d) !->
	id = Db.shared.incr 'storyId'
	Db.shared.set 'stories', id,
		text: d.text
		title: d.title
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
	up = Db.personal().createRef 'up'
	args = path.concat([(v) -> !v])
	value = up.modify.apply up, args
	
	args = makePath path
	args.push 'votes', if value then 1 else -1
	
	stories = Db.shared.ref 'stories'
	stories.incr.apply stories, args

exports.client_reply = (path, text) !->
	checkPath path
	stories = Db.shared.ref 'stories'
	commentId = stories.incr(path[0], 'comments')
	args = makePath path
	args.push 'c', commentId,
		text: text
		user: Plugin.userId()

	stories.set.apply stories, args

