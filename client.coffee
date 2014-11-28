Db = require 'db'
Dom = require 'dom'
Modal = require 'modal'
Time = require 'time'
Obs = require 'obs'
Plugin = require 'plugin'
Page = require 'page'
Server = require 'server'
Ui = require 'ui'
Form = require 'form'
{tr} = require 'i18n'


renderStory = (storyId) ->
	story = Db.shared.ref 'stories', storyId
	Dom.div !->
		Dom.style margin: '-8px', background: '#fff', borderBottom: '2px solid #ccc', padding: '8px'
		Ui.avatar Plugin.userAvatar(story.get('user')), !->
			Dom.style float: 'right'
		Dom.h2 story.get('title')
		require('markdown').render text if text=story.get('text')||''
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

renderComments = (base,path,margin=0) !->
	if path.length is 1
		Dom.span !->
			Dom.style color: Plugin.colors().highlight, fontSize: '85%', position: 'relative', top: '-10px', padding: '3px 5px', left: '-5px'
			Dom.text tr("Reply")
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
			Dom.style Box: 'top', margin: '5px 0 5px '+(if path.length is 1 then '0px' else '15px')

			Dom.div !->
				Dom.style Flex: 1

				npath = path.concat([0|comment.key()])
				Dom.div !->
					Dom.style Box: 'middle', marginBottom: '6px'
					renderUpvoter npath, comment, 35

					Dom.div !->
						Dom.style Flex: 1, minHeight: '30px'
						Dom.text comment.get('text')

						Dom.div !->
							Dom.style marginTop: '2px'
							Dom.span !->
								Dom.style
									fontSize: '70%'
									color: '#aaa'
								Dom.text Plugin.userName(comment.get('user'))
								Dom.text " • "
								if time = comment.get('time')
									Time.deltaText time
									Dom.text " • "
							Dom.span !->
								Dom.style color: Plugin.colors().highlight, fontSize: '70%', padding: '3px 5px 3px 2px'
								Dom.text tr("Reply")
								Dom.onTap  !->
									Modal.prompt tr('Your thoughtful reply:'), (reply) !->
										log reply
										if reply then Server.sync 'reply', npath, reply, !->
											base.set 'c', 1+(0|Db.shared.peek('stories',npath[0])),
												text: reply
												user: Plugin.userId()

				renderComments comment, npath, 8
	, (comment) ->
		[-(0|comment.peek('votes')), 0|comment.key()]

exports.render = ->

	if storyId = 0|Page.state.get(0)
		return renderStory storyId

	Ui.list !->
		Db.shared.iterate 'stories', (story) !->
			Ui.item !->
				Dom.style Box: "middle", padding: 0, minHeight: '50px'
				renderUpvoter story.key(), story

				Form.vSep()
				Dom.div !->
					Dom.style Box: 'middle', Flex: 1, minHeight: '50px'
					Dom.div !->
						Dom.style Flex: 1, margin: '5px 0 5px 8px'
						Dom.text story.get('title')
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
			Dom.text tr '+ New topic'
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

