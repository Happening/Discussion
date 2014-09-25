Db = require 'db'
Dom = require 'dom'
Modal = require 'modal'
Obs = require 'obs'
Plugin = require 'plugin'
Page = require 'page'
Server = require 'server'
Ui = require 'ui'
Form = require 'form'
{tr} = require 'i18n'


renderStory = (storyId) ->
	story = Db.shared.ref 'stories', storyId
	Dom.section !->
		Ui.avatar Plugin.userAvatar(story.get('user')), !->
			Dom.style float: 'right'
		Dom.h2 story.get('title')
		Dom.text story.get('text')||''
		renderComments story, [storyId]

renderComments = (base,path) !->
	Dom.span !->
		Dom.style
			textDecoration: 'underline'
			marginLeft: '6px'
		Dom.text tr('reply')
		Dom.onTap  !->
			Modal.prompt tr('Your thoughtful reply:'), (reply) !->
				log reply
				if reply then Server.sync 'reply', path, reply, !->
					base.set 'c', 1+(0|Db.shared.peek('stories',path[0])),
						text: reply
						etime: 0|Plugin.time()
						user: Plugin.userId()
	
	base.iterate 'c', (comment) ->
		Dom.div !->
			Dom.style
				margin: '5px 0 5px 15px'
			Dom.b Plugin.userName(comment.get('user'))+': '
			Dom.text comment.get('text')
			renderComments comment, path.concat([comment.key()])
	, (comment) -> comment.key()

exports.render = ->

	if storyId = 0|Page.state.get(0)
		return renderStory storyId

	Ui.list !->
		Db.shared.iterate 'stories', (story) !->
			Ui.item !->
				Dom.style display: 'block'
				Dom.div !->
					Dom.text '▲'
					already = Db.personal.get('up',story.key())
					Dom.style
						color: if already then '#3f3' else '#7a7'
						fontSize: '30px'
						marginRight: '4px'
						display: 'inline-block'
					Dom.onTap !->
						Server.sync 'up', [story.key()], !->
							Db.personal.set 'up', story.key(), !already
				Dom.span !->
					Dom.text story.get('title')
					Dom.style fontWeight: 'bold'
				if text = story.get('text')
					Dom.text " - "+text
				Dom.span !->
					Dom.style
						marginLeft: '8px'
						textDecoration: 'underline'
						whiteSpace: 'nowrap'
					Dom.text tr("%1 comments", story.get('comments')||0)
					Dom.onTap !-> Page.nav story.key()
		, (story) -> -story.peek('etime')

		Ui.item !->
			Dom.text tr '<add>'
			Dom.onTap !->
				Page.nav !->
					Form.input
						name: 'title'
						text: tr 'title'
					Form.text
						name: 'text'
						text: tr 'text'
					Form.setPageSubmit (d) !->
						if d.title
							Server.call 'new', d
							Page.back()

