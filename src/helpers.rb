# frozen_string_literal: true

require 'telegram/bot'

# Helper functions
module Helpers
	def log(*msg)
		puts(*msg, "\n")
	end

	def get_keyboard_markup(keys)
		kb = keys.map do |key|
			[Telegram::Bot::Types::KeyboardButton.new(text: key)]
		end

		Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb, one_time_keyboard: true)
	end

	def get_step_by_id(steps, id)
		index = steps.find_index { |step| step['id'] == id }

		[index, index.nil? ? nil : steps[index]]
	end

	def get_bot_api_error_description(message)
		message[/description: "(.*?)"/, 1]
	end

	def get_file_download_link(file_info, token)
		p file_info

		"https://api.telegram.org/file/bot#{token}/#{file_path}"
	end
end
