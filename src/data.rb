# frozen_string_literal: true

# Internal literals & constants
class Data
	const_set('APPLICATION_STAGES', {
		not_approved: 0,
		approved: 1
	})
	const_set('MESSAGE_TYPES', {
		text: 0,
		photo: 1,
		sticker: 2,
		voice: 3,
		video: 4,
		circle: 5,
		undefined: 9
	})

	const_set('CHANNEL_REPORT_TYPES', {
		reply: '00',
		error: '01',
		verification_request: '02',
		ban_request: '03'
	})
end
