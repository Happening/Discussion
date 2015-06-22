Db = require 'db'
Event = require 'event'
Plugin = require 'plugin'

exports.getTitle = ->
	if Db.shared.get('single')
		Db.shared.get 'stories', 1, 'title'

exports.onInstall = (config) !->
	if config?.title
		newStory
			title: config.title
			text: config.text||''
		, Plugin.ownerId()
		Db.shared.set 'single', true

exports.onConfig = (config) !->
	Db.shared.merge 'stories', 1,
		title: config?.title
		text: config?.text

exports.client_new = newStory = (d, userId = Plugin.userId()) !->
	id = Db.shared.incr 'storyId'
	Db.shared.set 'stories', id,
		text: d.text
		title: d.title
		time: 0|(new Date()/1000)
		comments: 0
		user: userId
	Event.create
		unit: "msg"
		text: "#{Plugin.userName(userId)}: #{if d.text then d.text else d.title}"
		read: [userId]

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

	args = path.concat(['voted', (v) -> !v])
	value = up.modify.apply up, args
	
	args = makePath path
	args.push 'votes', if value then 1 else -1
	
	stories = Db.shared.ref 'stories'
	stories.incr.apply stories, args

exports.client_delete = (path, undelete = false) !->
	checkPath path

	stories = Db.shared.ref 'stories'

	args = makePath path
	comment = stories.get.apply stories, args
	return if !Plugin.userIsAdmin() and +comment.user isnt Plugin.userId()

	args = args.concat(['deleted', (if undelete then null else true)])
	stories.set.apply stories, args

exports.client_reply = (path, text) !->
	checkPath path
	stories = Db.shared.ref 'stories'
	commentId = stories.incr(path[0], 'comments')

	userId = Plugin.userId()
	parentIds = []
	parentsSeen = {}
	parentsSeen[userId] = true
	args = []
	for x,n in path
		args.push 'c' if n
		args.push x

		args.push 'user'
		pId = stories.get.apply(stories,args)
		args.pop()
		unless parentsSeen[pId]
			parentIds.push pId
			parentsSeen[pId] = true

	args.push 'c', commentId,
		text: text
		time: 0|(new Date()/1000)
		user: userId

	stories.set.apply stories, args

	Event.create
		path: path
		text: "#{Plugin.userName()}: #{text}"
		sender: userId
	
