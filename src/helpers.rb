# frozen_string_literal: true

require 'telegram/bot'

# Helper functions
module Helpers
	def valid_hse_email?(email)
		regex = /\A[\w+\-.]+@edu\.hse\.ru\z/i
		email =~ regex ? true : false
	end

	def parse_name(first_name, last_name)
		if first_name && last_name
			"#{first_name} #{last_name}"
		elsif first_name
			first_name
		elsif last_name
			last_name
		else
			nil
		end
	end

	def get_bot_api_error_description(message)
		message[/description: "(.*?)"/, 1]
	end

	def get_keyboard_markup(keys)
		kb = keys.map do |key|
			[Telegram::Bot::Types::KeyboardButton.new(text: key)]
		end

		Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb, one_time_keyboard: true)
	end
end
