# Warm and Fuzzies Bot

This bot is used for tracking Warm and Fuzzies volunteer hours. I should rename this to VolunteerBot at some point.

## Setup

This app requires some setup. For running the app, you'll need to setup the table. For the first run, uncomment the schema definition, then comment out again once the table has been made.

### Bot Setup

To start, you'll need to setup a bot with Telegram's BotFather. Message `@BotFather` to get started, and get an API key.

### Config

Copy and fill out `config/example_server.yml` and `config/example_tokens.yml` to `config/server.yml` and `config/tokens.yml` respectively.

### Webhook Setup

If you are using a self-signed certificate, the upload currently does not work. You'll need to setup the webhook with curl instead of using the rake task.

Example:
```
curl -F "url=https://<HOSTNAME>/<BOT_TOKEN>" -F "certificate=@<FULL_PATH_TO_CERT.pem" https://api.telegram.org/bot<BOT_TOKEN>/setWebhook
```

If you are not using a self-signed certificate, you can run `rake webhook:set[token]` with token as your bot token.

