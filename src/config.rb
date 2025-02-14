# frozen_string_literal: true

# Settings & literals
class Config
	# Settings

	const_set('ADMIN_USER_ID', 562717995)

	const_set('SQLITE_PARAMS', {
		adapter: 'sqlite3',
		database: 'db/db.sqlite3'
	})

	const_set('PHOTOS', {
		debug: 'AgACAgIAAxkBAAMdZ6NRrD7JTJJzwpHocUABndOjSMYAApbqMRs8_CFJ-00Z6tVO_nMBAAMCAAN4AAM2BA',
		intro: 'AgACAgIAAxkBAAMrZ6NVhCyj_ieHCPsCAAHNxLFAOQuIAAKw6jEbPPwhSTQkrT4nHSyAAQADAgADeQADNgQ',
		meme:'AgACAgIAAxkBAAMyZ6NWLMp2hMSwJroxlF1d2rotr2UAArLqMRs8_CFJxYrQk1x3WdgBAAMCAAN5AAM2BA',
		chat: 'AgACAgIAAxkBAAM1Z6NWOLQsdC_rfIYAAQP2wXRNOtfMAAKz6jEbPPwhSThgqV6G3IJzAQADAgADeQADNgQ',
	})

	const_set('TEXTS', {
		intro: "%s, приветик\\!👋 \nэто пузырик — твой безопасный спейс, который сохранит хорошие моменты и напомнит, что все уже ок\\!🫧\n\n*good shit happens too*",
		intro2: "разные группы умных ученых из Беркли и Гарварда доказали, что очень здорово замечать хорошие вещи и записывать их — так миллениалы придумали технику «3 good things», которая помогает сделать жизнь чуточку лучше — а точнее, лишь взгляд на нее, потому что все уже хорошо\n\nв этом боте я предлагаю тебе то же самое — *просто записывать радости каждый день*\\. тебе нужно лишь 5 минут каждый вечер🕊️ и не бойся, я обязательно напомню тебе об этом\n\nпо кнопке в меню можно посмотреть записи — так ты сможешь порефлексировать :\\)\n\nкстати, держи [тестик](https://uquiz.com/uQijOR) <33",
		intro3: "супер🥰\\! ты можешь делать записи в любое время, но на всякий случай, я буду напоминать тебе — выбери, в какое время тебе удобно? выбирай конец дня, когда ты уже освободишься от дел и сможешь выделить пять минуточек \\(время московское\\)",
		nothanks: "жаль, что так💔 если передумаешь, напиши \\/start",
		intro4: "ну что, ты со мной?", 
		intro_time: "договорились, я тебе напомню\\!🖇️\n\nхочешь сделать свою первую запись?",
		intro_time2:"напиши время в формате чч:мм, например: 15:20",
		notification: "привет\\! давай сделаем запись радостей этого дня :\\)",
		first_note_response: "супер\\! ты умница\\!\n\nкстати, у нас есть доброе [коммьюнити](https://t.me/+CIMpQ1t6QjllYjli), где мы шерим радости друг с другом\\. если хочешь — заходи🔖",
		review: "*вот твои последние записи*",
		rules: "можешь не ограничивать себя в высказываниях и формате записи: используй нумерацию, эмоджи, буллет\\-поинты\\. пиши много и мало — как хочется\\, но лучше постараться вспомнить как минимум *3 радости*",
		week_review: "привет\\! давай вспомним, что радовало тебя на этой неделе📌",
		error: "ой, что\\-то пошло не так 😔 это не твоя вина, попробуй ещё раз позже\\!",
		note: "ура, я жду сообщение с твоими радостями'\\!\n\nмного их или мало — неважно, ты молодец и отлично справляешься🧦",
		no_notes: "у тебя пока нет записей🩷",
		review_end: "на этом пока все🩷"
	})

	const_set('STICKERS', ['CAACAgIAAxkBAAExgXBnpO1V_DsK1pt7wvha5tJVdmQdRQAC2m0AAvQbEUkuuxWdJft1TjYE', 'CAACAgIAAxkBAAExgW5npO1TnVOSGoBoKQFiye5UOSB1WgACfHEAAmjwEUkmjRGvtDBCLzYE', 'CAACAgIAAxkBAAExgWxnpO1QYSW8uSXsD7uR-_l_yXgPfwACgWwAArSDEUmpG6d1FllECjYE', 'CAACAgIAAxkBAAExgWpnpO1OYWeVpfZ4VNOmky3szpju3wACwWcAAk2AGEncNh7jwB_wHTYE', 'CAACAgIAAxkBAAExgWhnpO1MJylc8w_IDo3YvPLtmc-T7gAC6nEAAmUZEEltT79auSglcDYE', 'CAACAgIAAxkBAAExgWZnpO1KvG6GkJaRYM5jEyg-a9ZppgACe2QAApbAGUkXEqEWVBv_2TYE', 'CAACAgIAAxkBAAExgWRnpO1HvdB9XNh9vpoVWr4AASpGSZMAAj1nAAK_MxhJjWnjV3NpvuQ2BA', 'CAACAgIAAxkBAAExgWJnpO1EJapqqqsPstfiFmUjLRn31AACRHMAAkOKEUkf5WNiflZY6DYE', 'CAACAgIAAxkBAAExgWBnpO1AGQUBJb-8Qft2tvKXbn9ERQACfmgAAq4SEUlSJ0OoJtvuETYE'])
end
