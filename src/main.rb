# frozen_string_literal: true

require 'active_record'
require 'dotenv'
require 'faraday'
require 'telegram/bot'

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

		throw 'No token' unless token

		ActiveRecord::Base.establish_connection(Config::SQLITE_PARAMS)

		Telegram::Bot::Client.run(token) do |bot|
			begin
				send = lambda { |user_id, text, markup = nil, reply = nil, enable_md = true|
					markup ||= Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
					bot.api.send_message(chat_id: user_id, text:, parse_mode: enable_md ? 'MarkdownV2' : nil, reply_to_message_id: reply, reply_markup: markup, disable_web_page_preview: true)
				}
				send_photo = lambda { |user_id, photo_id, text = nil, markup = nil, enable_md = true| 
					bot.api.send_photo(
						chat_id: user_id, 
						photo: photo_id, 
						reply_markup: markup, 
						caption: text, 
						parse_mode: enable_md ? 'MarkdownV2' : nil
					)
				}
				send_sticker = lambda { |user_id, sticker_id, markup = nil, reply = nil|
					markup ||= Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
					bot.api.send_sticker(
						chat_id: user_id,
						sticker: sticker_id,
						reply_to_message_id: reply,
						reply_markup: markup
					)
				}

				Thread.new do
					loop do
						now = Time.now.strftime('%H:%M')
						users_to_notify = User.where(time: now)
				
						users_to_notify.each do |user|
							send.call(user.id, format(Config::TEXTS[:notification]), get_keyboard_markup(['записать радости', 'посмотреть радости']))
						end
				
						sleep 60
					end
				end



				log 'listening...'

				bot.listen do |message|
					user_id = message.from&.id

					begin
						next if !message.is_a?(Telegram::Bot::Types::Message) or message.chat.type != 'private'

						text = message.text

						is_admin = user_id == Config::ADMIN_USER_ID

						if is_admin
							case text 
							when '/purge'
								send.call(user_id, 'неееет не надо я же ничего не сделал')
								next
							end

							if !message.photo.nil?
								send.call(user_id, "this pic's id: #{message.photo.last.file_id}")
							end
						end


						user = User.find_or_initialize_by(user_id:)
						
						case user.step
						when 0
							user.username = message.from.username
							user.full_name = parse_name(message.from.first_name, message.from.last_name)
							send_photo.call(user_id, Config::PHOTOS[:intro], format(Config::TEXTS[:intro], message.from.username ), get_keyboard_markup(['окей, и что?']))
							user.update(step: 1)


						when 1
							send_photo.call(user_id, Config::PHOTOS[:meme], format(Config::TEXTS[:intro2]))
							send.call(user_id, format(Config::TEXTS[:intro4]), get_keyboard_markup(['да💘', 'сорри, в другой раз']) )
							user.update(step: 2)
						when 2
							if text == 'да💘'
								send.call(user_id, format(Config::TEXTS[:intro3]), get_keyboard_markup(['20:00', '21:00', '22:00', 'введу кастомно']) )
								user.update(step: 3)
							else
								send.call(user_id, format(Config::TEXTS[:nothanks]))
								user.update(step: 9)
							end
						when 3
							if ['20:00', '21:00', '22:00'].include?(text)
								user.update(time: text)
								send.call(user_id, format(Config::TEXTS[:intro_time]), get_keyboard_markup(['записать радости']))
								user.update(step: 5)
							elsif text == 'введу кастомно'
								user.update(step: 4)
								send.call(user_id, format(Config::TEXTS[:intro_time2]))
							end
						when 4
							if is_valid_time?(text)
								user.time = text
								send.call(user_id, format(Config::TEXTS[:intro_time]), get_keyboard_markup(['записать радости']))
								user.update(step: 5)
							else
								send.call(user_id, format(Config::TEXTS[:intro_time2]))
							end
						when 5
							if text =='записать радости'
								send.call(user_id, format(Config::TEXTS[:rules]))
								user.update(step: 6)
							end
						when 6
							Note.create(user_id: user.id, content: text, created_at: Time.now).save
							send_photo.call(user_id, Config::PHOTOS[:chat], format(Config::TEXTS[:first_note_response]), get_keyboard_markup(['записать радости', 'посмотреть радости']))
							user.update(step: 7)
						when 7
							if text == 'записать радости'
								send.call(user_id, format(Config::TEXTS[:note]))
								user.update(step: 8)
							
							elsif text == 'посмотреть радости'
								joys = Note.where("user_id = ? AND created_at >= ?", user_id, Date.today - 3)
											.order(created_at: :desc)
											.group_by { |note| note.created_at.to_date }
							
								if joys.empty?
									send.call(user_id, format(Config::TEXTS[:no_notes]), get_keyboard_markup(['записать радости', 'посмотреть радости']))
								else
									send.call(user_id, format(Config::TEXTS[:review])) 
							
									joys.each do |day, notes|
									message = "**#{escape_markdown(day.strftime('%d.%m.%Y'))}**\n— " + 
												notes.map { |note| escape_markdown(note.content) }.join("\n— ")
									send.call(user_id, message)
									end
							
									send.call(user_id, format(Config::TEXTS[:review_end]), get_keyboard_markup(['записать радости', 'посмотреть радости']))
								end 
							
								user.update(step: 7)
							else
								send.call(user_id, format(Config::TEXTS[:error]), get_keyboard_markup(['записать радости', 'посмотреть радости']))
							end 
						when 8
							Note.create(user_id: user.id, content: text, created_at: Time.now).save
							random_sticker = Config::STICKERS.sample
							send_sticker.call(user_id, random_sticker, get_keyboard_markup(['записать радости', 'посмотреть радости']))
							user.update(step: 7)
						end

						user.save
					rescue StandardError => e
						description = e.message
						send.call(user_id, format(Config::TEXTS[:error]))
						log 'ERROR: ', e
						log description
						log e.backtrace
					end
					
				end
			ensure
				ActiveRecord::Base.connection.close
			end
		end
	end
end

Main.run
