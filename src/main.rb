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
				send_media_group = lambda { |user_id, photos, captions = nil, enable_md = true|
					media = photos.map.with_index do |photo_id, index|
						media_item = {
							type: 'photo',
							media: photo_id
						}
						
						# Add caption to the first photo only (Telegram only displays caption on the first item)
						if index == 0 && captions.is_a?(String) && !captions.empty?
							media_item[:caption] = captions
							media_item[:parse_mode] = 'MarkdownV2' if enable_md
						end
						
						media_item
					end

					# Send the media group
					bot.api.send_media_group(
						chat_id: user_id,
						media: media
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
				get_user_markup = lambda { |user|
					user.is_premium == 1 ?
						get_keyboard_markup(['записать радости', 'посмотреть радости', 'пройти тестик']) :
						get_keyboard_markup(['записать радости', 'посмотреть радости', 'пройти тестик', 'оформить подписку'])
				}

				Thread.new do
					loop do
						now = Time.now.strftime('%H:%M')
						users_to_notify = User.where(time: now)
						weekday = Time.now.wday
				
						users_to_notify.each do |user|
							begin
								send.call(user.id, format(Config::TEXTS[:notification]), get_user_markup.call(user))
							rescue StandardError => e
								warn 'Follow-up err:', e.message
							end
						end
						if weekday == 0 && now == '23:59'
							week_dates = (0..6).map { |i| Date.today - i }.reverse
							notes = Note.where(created_at: week_dates.first.beginning_of_day..week_dates.last.end_of_day, user_id: User.where(is_premium: 1).select(:user_id))
							notes_by_user = notes.group_by(&:user_id)
							User.where(is_premium: 1).find_each do |user|
							  begin
								send.call(Config::ADMIN_USER_ID, "UserID: #{user.user_id}")
						  
								week_dates.each do |date|
								  user_notes = notes_by_user[user.id]&.select { |note| note.created_at.to_date == date } || []
								  date_str = "**#{escape_markdown(date.strftime('%d.%m.%Y'))}**"
								  notes_list = user_notes.map { |note| escape_markdown(note.content) }
								  message = if notes_list.any?
									"#{date_str}\n— " + notes_list.join("\n— ")
								  else
									"#{date_str}\n— Нет записей"
								  end
								  send.call(Config::ADMIN_USER_ID, message)
								end
						  
							  rescue StandardError => e
								warn 'Sunday premium report err:', e.message
							  end
							end
						  end
				
						sleep 50
					end
				end

				log 'listening...'

				bot.listen do |message|
					user_id = message.from&.id

					begin
						next if !message.is_a?(Telegram::Bot::Types::Message) or message.chat.type != 'private'

						text = message.text || message.caption

						is_admin = user_id == Config::ADMIN_USER_ID

						if is_admin
							if text == '/purge'
								send.call(user_id, 'неееет не надо я же ничего не сделал')

								next

							elsif text =~ /^\/send_group/
								args = text.split(' ')

								throw 'Not enough args' if args.length < 3

								id = args[1]

								throw 'Wrong id' unless id =~ /^\d+$/

								photos = args[2..]

								p id, photos

								send_media_group.call(id, photos, format(Config::TEXTS[:premium_letter]))

								next
							end
							
							if !message.photo.nil?
								if text =~ /^\d+$/
									send_photo.call(text, message.photo.last.file_id, format(Config::TEXTS[:premium_letter]))
								else
									send.call(user_id, "this pic's id: #{message.photo.last.file_id}", nil, nil, nil)
								end

								next
							end
						end

						user = User.find_or_initialize_by(user_id:)
						
						case user.step
						when 0
							user.username = message.from.username
							user.full_name = parse_name(message.from.first_name, message.from.last_name)
							send_photo.call(user_id, Config::PHOTOS[:intro], format(Config::TEXTS[:intro], message.from.username), get_keyboard_markup(['окей, и что?']))
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
								user.update(step: 0)
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
							if text == 'записать радости'
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
							elsif text == 'оформить подписку'
								send_photo.call(user_id, Config::PHOTOS[:premium], format(Config::TEXTS[:premium_intro], message.from.username), get_keyboard_markup(['все оки', 'отмена, не хочу подписку']))
								user.update(step: 12)
							elsif text == 'пройти тестик'
								send.call(user_id, Config::TEXTS[:test], get_keyboard_markup(['оки']) )
								user.update(test_answers: nil)
								user.update(step: 10)
							elsif text == 'посмотреть радости'
								joys = Note.where("user_id = ? AND created_at >= ?", user_id, Date.today - 3)
											.order(created_at: :desc)
											.group_by { |note| note.created_at.to_date }
							
								if joys.empty?
									send.call(user_id, format(Config::TEXTS[:no_notes]), get_user_markup.call(user))
								else
									send.call(user_id, format(Config::TEXTS[:review])) 
							
									joys.each do |day, notes|
									message = "**#{escape_markdown(day.strftime('%d.%m.%Y'))}**\n— " + 
												notes.map { |note| escape_markdown(note.content) }.join("\n— ")
									send.call(user_id, message)
									end

									send.call(user_id, format(Config::TEXTS[:review_end]), get_user_markup.call(user))
								end 
							
								user.update(step: 7)
							else
								send.call(user_id, format(Config::TEXTS[:unknown]), get_user_markup.call(user))
							end 
						when 8
							Note.create(user_id: user.id, content: text, created_at: Time.now).save
							random_sticker = Config::STICKERS.sample
							send_sticker.call(user_id, random_sticker, get_user_markup.call(user))
							user.update(step: 7)
						when 9
							user.update(step: 0)
						when 10
							if text == 'карина'
							  user.update(step: 7)
							else
							  user_answers = user.test_answers || ''
							  p "1. Текущие ответы пользователя: #{user_answers}"
							  if text.match?(/^[1-5]$/)
								user_answers += text
								p "2. Ответы пользователя после добавления нового ответа (#{text}): #{user_answers}"
								user.update(test_answers: user_answers)
								p "3. Ответы пользователя сохранены в базе данных: #{user.test_answers}"
								question_index = user_answers.length
								p "4. Индекс текущего вопроса: #{question_index}"
								if question_index < Config::TEST.size
								  question = Config::TEST[question_index]
								  p "5. Следующий вопрос: #{question[:text]}"
								  markup = get_keyboard_markup(question[:options].keys)
								  p "6. Клавиатура создана: #{markup}"
								  send.call(user_id, escape_markdown(question[:text]), markup)
								  p "7. Вопрос отправлен пользователю."
								else
								  p "8. Вопросы закончились. Показываем результат."
								  most_frequent_answer = user_answers.chars.tally.max_by { |_, count| count }[0]
								  answer_key = "answer_#{most_frequent_answer}".to_sym
								  result_text = Config::TEST_ANSWERS[answer_key]
								  p "9. Пользователь выбрал самый частый ответ: #{most_frequent_answer} (#{result_text})"
								  send.call(user_id, result_text, get_keyboard_markup(['записать радости', 'посмотреть радости']))
								  p "10. Результат отправлен пользователю: #{result_text}"
								  user.update(step: 7)
								  p "11. Шаг пользователя обновлён на 7."
								end
							  else
								# Игнорируем недопустимый ответ, но не останавливаем тест
								p "12. Игнорируем недопустимый ответ: #{text}. Ожидается число от 1 до 4."
						  
								# Если user_answers пуст, отправляем первый вопрос
								if user_answers.empty?
								  question_index = 0
								  question = Config::TEST[question_index]
								  p "13. Отправляем первый вопрос, так как тест еще не начался."
						  
								  # Создаем клавиатуру с вариантами ответа
								  markup = get_keyboard_markup(question[:options].keys)
								  p "14. Клавиатура создана: #{markup}"
						  
								  # Отправляем вопрос пользователю
								  send.call(user_id, escape_markdown(question[:text]), markup)
								  p "15. Вопрос отправлен пользователю."
								end
							  end
							end
						when 11
							user.update(step: 7)
						when 12
							if text == 'все оки'
								begin
									response = bot.api.getChatMember(chat_id: Config::CHANNEL_ID, user_id: user_id)
									status = response.status

									if %w[creator administrator member restricted].include?(status)
										user.update(is_premium: 1)
										send.call(user_id, format(Config::TEXTS[:premium_ok]), get_user_markup.call(user))
										user.update(step: 7)
									else
										send.call(user_id, format(Config::TEXTS[:premium_not_ok]), get_keyboard_markup(['все оки', 'отмена, не хочу подписку']))
									end
								rescue => e
									puts "Ошибка при проверке подписки: #{e}"
									send.call(user_id, format(Config::TEXTS[:error]), get_user_markup.call(user))
								end
							else
								send.call(user_id, format(Config::TEXTS[:premium_no]), get_user_markup.call(user))
								user.update(step: 7)
							end
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
