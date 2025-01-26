# frozen_string_literal: true

require 'active_record'
require 'dotenv'
require 'faraday'
require 'telegram/bot'
require 'yaml'

require_relative 'config'
require_relative 'data'
require_relative 'helpers'
require_relative 'models'

# Main module
module Main
	extend Helpers

	def self.run
		Dotenv.load

		token = ENV['BOT_TOKEN']

		story = YAML.load_file('config/story.yml')

		ActiveRecord::Base.establish_connection(Config::SQLITE_PARAMS)

		Telegram::Bot::Client.run(token) do |bot|
			begin
				send = lambda { |user_id, text, markup = nil, reply = nil, enable_md = false|
					markup ||= Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
					bot.api.send_message(chat_id: user_id, text:, parse_mode: enable_md ? 'Markdown' : nil, reply_to_message_id: reply, reply_markup: markup, disable_web_page_preview: true)
				}

				execute_step = lambda { |user_id, step|
					photo_id = step['photo_id']
					sticker_id = step['sticker_id']

					markup = step['keyboard'] ? get_keyboard_markup(step['keyboard']) : nil

					if photo_id
						bot.api.send_photo(chat_id: user_id, photo: photo_id, reply_markup: markup, caption: step['text'])
					elsif sticker_id
						bot.api.send_sticker(chat_id: user_id, sticker: sticker_id)
					else
						send.call(user_id, step['text'], markup)
					end
				}

				log 'listening...'

				bot.listen do |message|
					user_id = message.from&.id

					begin
						next if !message.is_a?(Telegram::Bot::Types::Message) or message.chat.type != 'private'

						text = message.text

						is_admin = user_id == Config::ADMIN_USER_ID

						if is_admin
							if !message.photo.nil?
								send.call(user_id, "this pic's id: #{message.photo.last.file_id}")
							elsif !message.sticker.nil?
								send.call(user_id, "this sticker's id: #{message.sticker.file_id}")
							elsif text == '/reset'
								User.delete_all
								send.call(user_id, 'progress reset')
							else
								send.call(user_id, 'hey girlboss')
							end
							next
						end

						next if Config::IS_DOWN

						###### Message handling

						user = User.find_or_initialize_by(id: user_id)

						step_executed = false

						steps = story['steps']
						step_id = user.current_step_id || steps[0]['id']
						step_index, step = get_step_by_id(steps, step_id)

						log "received: '#{text}'\ncurrent step: #{step_id}"

						throw 'Nil step' if step.nil?

						if step['respond_to'].nil? or step['respond_to'] == text
							log "executing step '#{step_id}'..."
							execute_step.call(user_id, step)

							step_executed = true
						end

						if step_executed
							case step['after']
							when 'set_next_step'
								next_step = steps[step_index + 1]
								user.current_step_id = next_step['id']
							end

							user.save
						end

						send.call(user_id, story['out_message']) unless step_executed
					rescue StandardError => e
						description = e.respond_to?(:message) ? get_bot_api_error_description(e.message) : nil

						case description
						when Config::VOICE_FORBIDDEN_ERROR
							send.call(user_id, Config::VOICE_FORBIDDEN_MESSAGE)
						else
							log 'ERROR: ', e
							log e.backtrace
						end
					end
				end
			ensure
				ActiveRecord::Base.connection.close
			end
		end
	end
end

Main.run
