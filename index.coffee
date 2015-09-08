request = require 'superagent'
colors = require 'irc-colors'

module.exports = (Module) ->
	getClue = () ->
		return new Promise (resolve,reject) =>
			req = request.get("http://jservice.io/api/random?count=1")
			req.end (err, res) =>
				if err
					reject err
				else
					clue = []
					clue = JSON.parse(res.text)
					answer = clue[0].answer
					answer = answer.replace(/<\/?[^>]+(>|$)/g, "");
					answer = answer.replace("\\", "")
					answer = answer.replace("\\", "")
					answer = answer.replace("(", "")
					answer = answer.replace(")", "")
					resolve {category:clue[0].category.title, question: clue[0].question,answer:answer}


	class TriviaModule extends Module
		shortName: 'Trivia'
		helpText:
			default: 'A module for Kurea to tell someone they\'re rekt.'
		usage:
			default: 'trivia [arg]'
		constructor: (moduleManager) ->
			super
			@game = {unansweredCount:0}
			@addRoute 'trivia stop', (origin, route) =>
				if @game.running
					@reply origin, "Stopping the Trivia game"
					@game = {unansweredCount:0}
				else
					@reply origin, "There is no Trivia game running"

			@addRoute 'trivia', (origin, route) =>
				@game.running = true
				@reply origin, "Starting a new Trivia game"
				gameLoop = () =>
					if @game.running
						@game.answered = false
						clue = getClue()
						clue.catch () =>
							@reply origin, "Couldn't connect to API. Stopping Trivia Game"
							@game = {unansweredCount:0}
						clue.then (value) =>
							@game.question = value.question
							@game.answer = value.answer
							@game.category = value.category
							console.log(@game.answer)
							@reply origin, "Category: #{colors.bold(@game.category)}"
							@reply origin, @game.question
							setTimeout ()=>
									@reply origin, "5 seconds remaining this round."
							,10000
							setTimeout ()=>
									if !@game.answered
										@reply origin, "The answer was: #{colors.bold(@game.answer)}"
										@game = {unansweredCount:0, running:true}
										@game.unansweredCount += 1
									if @game.unansweredCount == 3
										@reply origin, "Stopping the Trivia game"
										@game = {unansweredCount:0}
									@reply origin, "5 seconds until next round."
							,15000
							setTimeout gameLoop, 25000
				setTimeout gameLoop,5000


			@on 'message', (bot, user, channel, message) =>
				if @game.running
					if @game.answer && message.toLowerCase().replace("'", "") is @game.answer.toLowerCase().replace("'", "")
						bot.say channel, "#{colors.bold(user)} got the answer correct. The Answer was: #{colors.bold(@game.answer)}."
						@game.unansweredCount = 0;
						@game.answered = true
						@game.answer = @game.question = null

	TriviaModule
