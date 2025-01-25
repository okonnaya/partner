# frozen_string_literal: true

require 'active_record'
require 'dotenv'
require 'telegram/bot'
require 'yaml'

require_relative 'config'
require_relative 'data'
require_relative 'helpers'
require_relative 'mail'
require_relative 'models'

# Main module
module Main
	extend Helpers

	def self.run
		Dotenv.load

		story = YAML.load_file('config/story.yml')

		ActiveRecord::Base.establish_connection(Config::SQLITE_PARAMS)

		Telegram::Bot::Client.run(ENV['BOT_TOKEN']) do |bot|
			begin
				send = lambda { |user_id, text, markup = nil, reply = nil, enable_md = false|
					markup ||= Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
					bot.api.send_message(chat_id: user_id, text:, parse_mode: enable_md ? 'Markdown' : nil, reply_to_message_id: reply, reply_markup: markup, disable_web_page_preview: true)
				}

				execute_step = lambda { |user_id, step|
					photo_id = step['file_id']

					markup = step['keyboard'] ? get_keyboard_markup(step['keyboard']) : nil

					if photo_id
						bot.api.send_photo(chat_id: user_id, photo: photo_id, reply_markup: markup, caption: step['text'])
					else
						send.call(user_id, step['text'], markup)
					end
				}

				puts 'listening...'

				bot.listen do |message|
					user_id = message.from&.id

					begin
						next if !message.is_a?(Telegram::Bot::Types::Message) or message.chat.type != 'private'

						text = message.text

						is_admin = user_id == Config::ADMIN_USER_ID

						if is_admin
							if !message.photo.nil?
								send.call(user_id, "this pic's id: #{message.photo.last.file_id}")
							else
								send.call(user_id, 'hey girlboss')
							end
							next
						end

						next if Config::IS_DOWN

						###### Message handling

						responded = false
						steps = story['steps']
						step = steps[0]

						if step['respond_to'].nil? or step['respond_to'] == text
							puts "executing step '#{step['id']}'..."
							execute_step.call(user_id, step)

							responded = true
						end

						send.call(user_id, story['out_message']) unless responded
					rescue StandardError => e
						description = e.respond_to?(:message) ? get_bot_api_error_description(e.message) : nil

						case description
						when Config::VOICE_FORBIDDEN_ERROR
							send.call(user_id, Config::VOICE_FORBIDDEN_MESSAGE)
						else
							puts 'ERROR: ', e
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
