const Log = require("logger");
const NodeHelper = require("node_helper");
const { scheduleTimer } = require("#module_functions");

/**
 * Responsible for requesting Telegram messages on the set interval and broadcasting the data.
 * @param {string} botToken Telegram bot token from @BotFather
 * @param {string} chatId Chat ID or user ID to fetch messages from
 * @param {number} updateInterval Update interval in milliseconds
 * @param {number} maxMessages Maximum number of messages to fetch
 * @param {number} messageMaxAgeHours Maximum age of messages in hours
 * @class
 */
const TelegramFetcher = function (botToken, chatId, updateInterval, maxMessages, messageMaxAgeHours) {
	const maxAgeHours = Number(messageMaxAgeHours) > 0 ? Number(messageMaxAgeHours) : 4;
	const messageMaxAgeMS = maxAgeHours * 60 * 60 * 1000;
	let updateTimer = null;
	let messages = [];
	let updateIntervalMS = updateInterval;
	let lastUpdateId = 0; // Track last processed update ID

	let fetchFailedCallback = function () {};
	let messagesReceivedCallback = function () {};

	if (updateIntervalMS < 1000) {
		updateIntervalMS = 1000;
	}

	/* private methods */

	/**
	 * Request new messages from Telegram Bot API.
	 */
	const fetchMessages = async () => {
		clearTimeout(updateTimer);
		updateTimer = null;

		const now = Date.now();
		messages = messages.filter((message) => now - message.date <= messageMaxAgeMS);

		try {
			// Telegram Bot API endpoint for getting updates
			const url = `https://api.telegram.org/bot${botToken}/getUpdates?offset=${lastUpdateId + 1}&limit=${maxMessages}&timeout=0`;

			const response = await fetch(url);
			await NodeHelper.checkFetchStatus(response);
			
			const data = await response.json();

			if (!data.ok) {
				throw new Error(`Telegram API error: ${data.description || "Unknown error"}`);
			}

			// Process updates
			const newMessages = [];
			if (data.result && data.result.length > 0) {
				data.result.forEach((update) => {
					if (update.message && update.message.text) {
						const message = update.message;
						
						// Update the lastUpdateId
						if (update.update_id > lastUpdateId) {
							lastUpdateId = update.update_id;
						}

						// Check if message is from the specified chat
						if (message.chat.id.toString() === chatId.toString()) {
							newMessages.push({
								text: message.text,
								sender: message.from ? (message.from.first_name + (message.from.last_name ? " " + message.from.last_name : "")) : "Unknown",
								date: message.date * 1000, // Convert Unix timestamp to milliseconds
								messageId: message.message_id
							});
						}
					}
				});

				// Add new messages to the beginning of the array
				if (newMessages.length > 0) {
					messages = [...newMessages, ...messages]
						.filter((message) => now - message.date <= messageMaxAgeMS)
						.slice(0, maxMessages);
					Log.info(`Fetched ${newMessages.length} new Telegram message(s)`);
				}
			}

			this.broadcastMessages();
		} catch (error) {
			Log.error("Error fetching Telegram messages:", error);
			fetchFailedCallback(this, error);
		}

		// Schedule next fetch
		scheduleTimer(updateTimer, updateIntervalMS, fetchMessages);
	};

	/* public methods */

	/**
	 * Update the update interval, but only if we need to increase the speed.
	 * @param {number} interval Interval for the update in milliseconds.
	 */
	this.setUpdateInterval = function (interval) {
		if (interval > 1000 && interval < updateIntervalMS) {
			updateIntervalMS = interval;
		}
	};

	/**
	 * Initiate fetchMessages();
	 */
	this.startFetch = function () {
		fetchMessages();
	};

	/**
	 * Broadcast the existing messages.
	 */
	this.broadcastMessages = function () {
		const now = Date.now();
		messages = messages.filter((message) => now - message.date <= messageMaxAgeMS);

		if (messages.length <= 0) {
			Log.info("No Telegram messages to broadcast yet.");
			// Still call the callback to inform the frontend
		}
		Log.info(`Broadcasting ${messages.length} Telegram message(s).`);
		messagesReceivedCallback(this);
	};

	this.onReceive = function (callback) {
		messagesReceivedCallback = callback;
	};

	this.onError = function (callback) {
		fetchFailedCallback = callback;
	};

	this.messages = function () {
		return messages;
	};
};

module.exports = TelegramFetcher;
