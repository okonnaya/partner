# frozen_string_literal: true

# Settings & literals
class Config
	# Settings

	const_set('IS_DOWN', false)

	# const_set('ADMIN_USER_ID', 182195759)
	const_set('ADMIN_USER_ID', 6200808057)

	const_set('TARGET_USER_ID', 182195759)
	# const_set('TARGET_USER_ID', 562717995)

	const_set('SQLITE_PARAMS', {
		adapter: 'sqlite3',
		database: 'db/db.sqlite3'
	})

	# ERROR TYPES

	const_set('VOICE_FORBIDDEN_ERROR', 'Bad Request: VOICE_MESSAGES_FORBIDDEN')

	# COMMANDS

	const_set('TALK_COMMAND', '/talk')
end
