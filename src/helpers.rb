# frozen_string_literal: true

require 'telegram/bot'

# Helper functions
module Helpers
	def log(*msg)
		puts(*msg, "\n")
	end

	def escape_markdown(text)
		escape_chars = '_*[]()~`>#+-=|{}.!'
		regex = Regexp.union(escape_chars.chars)
		text.gsub(regex) { |char| "\\#{char}" }
	end

	# def escape_markdown(text)
	# 	escape_chars = ['_', '*', '[', ']', '(', ')', '~', '`', '>', '#', '+', '-', '=', '|', '{', '}', '.', '!']
	# 	escape_chars.each do |char|
	# 		text.gsub!(char, "\\#{char}")
	# 	end
		
	# 	text

	# 	p text
	# end
	  

	def get_keyboard_markup(keys)
		kb = keys.map do |key|
			[Telegram::Bot::Types::KeyboardButton.new(text: key)]
		end

		Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb, one_time_keyboard: true)
	end

	def get_file_download_link(file_info, token)
		p file_info

		"https://api.telegram.org/file/bot#{token}/#{file_path}"
	end

	def is_valid_time?(string)
		/^([01][0-9]|2[0-3]):[0-5][0-9]$/ === string
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
end
