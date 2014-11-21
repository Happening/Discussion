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
		require('markdown').render text if text=story.get('text')||''
		renderComments story, [storyId]

renderComments = (base,path,margin=0) !->
	Dom.img !->
		Dom.prop src: Plugin.resourceUri 'reply.png'
		Dom.style
			width: '24px'
			height: '18px'
			marginLeft: margin+'px'
		Dom.onTap  !->
			Modal.prompt tr('Your thoughtful reply:'), (reply) !->
				log reply
				if reply then Server.sync 'reply', path, reply, !->
					base.set 'c', 1+(0|Db.shared.peek('stories',path[0])),
						text: reply
						user: Plugin.userId()
	
	up = Db.personal.ref('up')
	base.iterate 'c', (comment) ->
		Dom.div !->
			npath = path.concat([0|comment.key()])
			Dom.div !->
				Dom.text '▲'
				already = up.get.apply up, npath
				color = if already then Plugin.colors().highlight else '#666'
				Dom.style
					color: color
					fontSize: '24px'
					marginRight: '5px'
					display: 'inline-block'
				Dom.onTap !->
					Server.sync 'up', npath, !->
						up.set.apply up, npath.concat([!already])
			Dom.style
				margin: '5px 0 5px 15px'
			Dom.b Plugin.userName(comment.get('user'))+': '
			Dom.text comment.get('text')
			renderComments comment, npath, 8
	, (comment) ->
		[-(0|comment.peek('votes')), 0|comment.key()]

exports.render = ->

	if storyId = 0|Page.state.get(0)
		return renderStory storyId

	Db.shared.iterate 'stories', (story) !->
		Dom.section !->
			Dom.style Box: "middle"
			Dom.div !->
				Dom.text '▲'
				already = Db.personal.get('up',story.key())
				color = Plugin.colors().highlight
				color = '#666' unless already
				Dom.style
					color: color
					fontSize: '24px'
					marginRight: '5px'
					display: 'inline-block'
				Dom.onTap !->
					Server.sync 'up', [story.key()], !->
						Db.personal.set 'up', story.key(), !already
			Form.vSep()
			Dom.div !->
				Dom.style Flex: 1, marginLeft: '8px'
				Dom.text story.get('title')
			Dom.div !->
				Dom.style
					color: 'white'
					fontSize: '12px'
					paddingLeft: '6px'
					width: '21px'
					height: '19px'
					marginLeft: '5px'
					textAlign: 'center'
					lineHeight: '19px'
					backgroundImage: 'url('+Plugin.resourceUri('comment.png')+')'
					backgroundSize: 'cover'
				Dom.text story.get('comments')||0
			Dom.onTap !-> Page.nav story.key()
	, (story) -> - story.key()*3 - (0|story.peek('votes'))*4

	Dom.section !->
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

