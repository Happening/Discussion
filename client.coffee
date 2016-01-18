Db = require 'db'
Dom = require 'dom'
Event = require 'event'
Form = require 'form'
Modal = require 'modal'
Obs = require 'obs'
Plugin = require 'plugin'
Page = require 'page'
Server = require 'server'
Time = require 'time'
Ui = require 'ui'
{tr} = require 'i18n'

renderStory = (storyId) ->
	story = Db.shared.ref 'stories', storyId
	Event.showStar story.get('title') if !Db.shared.get('single')
	Ui.top !->
		Dom.style margin: 0
		Ui.avatar Plugin.userAvatar(story.get('user')), style: float: 'right'
		Dom.h2 !->
			Dom.userText story.get('title'), {br:false}
		Dom.div !->
			Dom.userText text if text=story.get('text')
	renderComments story, [storyId]

renderUpvoter = (path, votesObs, size = 50) ->
	if path not instanceof Array
		path = [path]

	up = Db.personal.ref('up')

	Dom.div !->
		Dom.style Box: 'middle center', textAlign: 'center', width: size+'px', minHeight: size+'px'
		already = up.get.apply up, path.concat('voted')
		Dom.div !->
			color = Plugin.colors().highlight
			color = '#666' unless already
			Dom.div !->
				Dom.style display: 'inline-block', border: '8px solid transparent', borderBottom: '12px solid '+color, marginTop: '-6px'
			Dom.div !->
				Dom.style fontSize: '11px', marginTop: '2px', color: color
				Dom.text votesObs.get('votes')||0

		Dom.onTap !->
			Server.sync 'up', path, !->
				up.set.apply up, path.concat([!already])

###
Dom.css
	".form-text-wrap":
		padding: 0
###

reply = (path) !->

	Page.nav !->
		base = parent = Db.shared.ref 'stories', path[0]
		for i in [1...path.length]
			parent = parent.ref 'c', path[i]
		Dom.cls 'reply'

		Ui.top !->
			Ui.avatar Plugin.userAvatar(parent.get('user')), style: float: 'right'
			Dom.h2 !->
				Dom.userText parent.get('title'), {br:false}
			Dom.div !->
				Dom.userText text if text=parent.get('text')

		Form.text name: 'reply', text: tr("Your reply")

		Form.setPageSubmit (data) !->
			Server.sync 'reply', path, data.reply, !->
				parent.set 'c', 1+(0|base.peek('comments')),
					text: data.reply
					user: Plugin.userId()
			Page.back()

renderComments = (base,path,margin=0,hide=false) !->
	if path.length is 1
		Dom.div !->
			Dom.style color: Plugin.colors().highlight, fontSize: '85%', padding: '12px', margin: '0', display: 'inline-block'
			Dom.text tr("Reply")
			Dom.onTap  !->
				reply path

	up = Db.personal.ref('up')
	base.iterate 'c', (comment) ->
		Dom.div !->
			Dom.style Box: 'top', margin: '5px 0 5px '+(if path.length is 1 then '0px' else '15px'), display: (if hide then 'none' else '')

			collapsed = Obs.create(false)
			Dom.div !->
				Dom.style Flex: 1

				npath = path.concat([0|comment.key()])
				Dom.div !->
					Dom.style Box: 'middle', marginBottom: '6px'
					renderUpvoter npath, comment, 35

					Dom.div !->
						deleted = comment.get('deleted')
						Dom.style Flex: 1, minHeight: '30px', color: (if deleted then '#aaa' else 'inherit')
						Dom.userText (if deleted then tr("[deleted]") else comment.get('text'))

						Dom.div !->
							Dom.style marginTop: '2px', fontSize: '70%', color: '#aaa'
							Dom.span !->
								Dom.text Plugin.userName(comment.get('user'))
								if time = comment.get('time')
									Dom.text " • "
									Time.deltaText time

							if !deleted
								Dom.span " • "
								Dom.span !->
									Dom.style color: Plugin.colors().highlight, padding: '3px 2px'
									Dom.text tr("Reply")
									Dom.onTap !->
										reply npath

							if Plugin.userIsAdmin() or Plugin.userId() is comment.get('user')
								Dom.span " • "
								Dom.span !->
									Dom.style color: Plugin.colors().highlight, padding: '3px 2px'
									Dom.text (if deleted then tr("Undelete") else tr("Delete"))
									Dom.onTap !->
										Server.sync 'delete', npath, deleted
											# todo: predict

							if comment.get('c')
								Dom.span " • "
								Dom.span !->
									Dom.style color: Plugin.colors().highlight, padding: '3px 2px'
									Dom.text (if collapsed.get() then '[ + ]' else '[ - ]')
									Dom.onTap !->
										collapsed.modify (v) -> !v


				renderComments comment, npath, 8, collapsed.get()
	, (comment) ->
		[-(0|comment.peek('votes')), 0|comment.key()]

exports.render = ->
	storyId = 1 if Db.shared.get('single')
	if storyId = (storyId || +Page.state.get(0))
		return renderStory storyId

	Page.setCardBackground()
	Ui.list !->
		Db.shared.iterate 'stories', (story) !->
			Ui.item !->
				Dom.style Box: "middle", padding: 0, minHeight: '50px'
				renderUpvoter story.key(), story

				Form.vSep()
				Dom.div !->
					Dom.style Box: 'middle', Flex: 1, minHeight: '50px'
					Dom.div !->
						Dom.style Flex: 1, margin: '5px 0 5px 8px', color: (if Event.isNew(story.get('time')) then '#5b0' else 'inherit')
						Dom.userText story.get('title'), {br:false}
					Event.renderBubble story.key()
					Dom.div !->
						Dom.style
							color: 'white'
							fontSize: '12px'
							paddingLeft: '6px'
							width: '21px'
							height: '19px'
							margin: '0 8px 0 8px'
							textAlign: 'center'
							lineHeight: '19px'
							backgroundImage: 'url('+Plugin.resourceUri('comment.png')+')'
							backgroundSize: 'cover'
						Dom.text story.get('comments')||0
					Dom.onTap !-> Page.nav story.key()
		, (story) -> - story.key()*3 - (0|story.peek('votes'))*4

		Ui.item !->
			Dom.style color: Plugin.colors().highlight
			Dom.text tr '+ Add topic'
			Dom.onTap !->
				Page.nav !->
					Page.setTitle("New topic")
					Form.input
						name: 'title'
						text: tr 'Title'
					Form.text
						name: 'text'
						text: tr 'Info, details, your opinion, etc...'
					Form.setPageSubmit (d) !->
						if d.title
							Server.call 'new', d
							Page.back()

exports.renderSettings = !->
	if !Db.shared or Db.shared.get('single')
		Dom.div !->
			Dom.style fontSize: '85%', color: '#aaa', margin: '8px 0'
			Dom.text tr("Leave title and text empty to allow members to start multiple discussion topics")

		Form.input
			name: 'title'
			text: tr 'Title'
			value: Db.shared.func('stories', 1, 'title') if Db.shared

		Form.text
			name: 'text'
			text: tr 'Text'
			autogrow: true
			value: Db.shared.func('stories', 1, 'text') if Db.shared
			rows: 1
			inScope: !-> Dom.prop 'rows', 1
	else
		Ui.emptyText tr("Only available when adding the plugin")
