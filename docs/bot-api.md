# Bot API Documentation

This document describes the API for building bots that integrate with Cordless.

## Overview

Bots are special user accounts that can:
- Send messages to rooms via the HTTP API
- Receive messages via webhooks when mentioned (or all messages in direct rooms)
- Respond to messages with text or file attachments

## Authentication

Bots authenticate using a **bot key** in the format `{user_id}-{token}`.

The bot key is generated when creating a bot and can be regenerated in the admin interface.

### Using the Bot Key

Include the bot key in the URL path when making API requests:

```
POST /rooms/{room_id}/{bot_key}/messages
```

**Example:**
```bash
curl -X POST "https://your-instance.com/rooms/123/456-abc123def456/messages" \
  -H "Content-Type: text/plain" \
  -d "Hello from my bot!"
```

> **Security Note**: The bot key is included in the URL path for simplicity. Be aware that URLs may be logged by proxies, load balancers, and monitoring tools. For high-security environments, consider placing Cordless behind a reverse proxy that strips sensitive URL components from logs.

## API Endpoints

### Create Message

Send a message to a room.

```
POST /rooms/{room_id}/{bot_key}/messages
```

#### Text Message

**Request:**
```bash
curl -X POST "https://your-instance.com/rooms/{room_id}/{bot_key}/messages" \
  -H "Content-Type: text/plain" \
  -d "Your message text here"
```

**Response:**
- `201 Created` - Message created successfully
  - `Location` header contains the message URL
- `401 Unauthorized` - Invalid bot key
- `403 Forbidden` - Bot is not a member of the room
- `422 Unprocessable Entity` - Validation errors

#### File Attachment

**Request:**
```bash
curl -X POST "https://your-instance.com/rooms/{room_id}/{bot_key}/messages" \
  -F "attachment=@/path/to/file.pdf"
```

**Response:**
- `201 Created` - Message with attachment created
- `401 Unauthorized` - Invalid bot key
- `403 Forbidden` - Bot is not a member of the room

## Webhooks

When your bot is mentioned in a message (or receives any message in a direct room), Cordless will POST to your configured webhook URL.

### Webhook Request

Cordless sends a JSON payload to your webhook URL:

```json
{
  "user": {
    "id": 42,
    "name": "Alice"
  },
  "room": {
    "id": 123,
    "name": "General",
    "path": "/rooms/123/456-abc123def456/messages"
  },
  "message": {
    "id": 789,
    "body": {
      "html": "<p>Hey @bot, what's the weather?</p>",
      "plain": "what's the weather?"
    },
    "path": "/rooms/123/messages/789"
  }
}
```

**Fields:**

| Field | Description |
|-------|-------------|
| `user.id` | ID of the user who sent the message |
| `user.name` | Display name of the user |
| `room.id` | ID of the room |
| `room.name` | Name of the room |
| `room.path` | API path for bot to post messages back |
| `message.id` | ID of the message |
| `message.body.html` | HTML content of the message |
| `message.body.plain` | Plain text content (with bot mention removed) |
| `message.path` | URL path to view the message |

### Webhook Response

Your webhook can optionally respond to post a message back to the room.

**Reply behavior:**
- Only HTTP `200 OK` with a non-empty body triggers a reply
- `204 No Content` or any empty response will not trigger a reply
- Non-2xx status codes will not trigger a reply

#### Text Reply

Respond with `Content-Type: text/plain` or `text/html`:

```
HTTP/1.1 200 OK
Content-Type: text/plain

The weather is sunny with a high of 72F!
```

#### Attachment Reply

Respond with any other content type to send as a file attachment:

```
HTTP/1.1 200 OK
Content-Type: image/png

<binary image data>
```

#### No Reply

Return 204 or any non-200 status to skip sending a reply:

```
HTTP/1.1 204 No Content
```

### Webhook Timeouts

- **Connection timeout:** 7 seconds
- **Read timeout:** 7 seconds

If your webhook doesn't respond in time, users will see "Failed to respond (timeout)".

### Webhook Error Handling

| Error | User sees |
|-------|-----------|
| Timeout | "Failed to respond (timeout)" |
| SSL error | "Failed to respond (SSL error)" |
| Connection refused | "Failed to respond (connection error)" |
| Response too large (>10MB) | "Response too large" |
| HTTP 4xx/5xx | No message (silent failure) |
| Other errors | "Failed to respond (error)" |

## Bot Membership

Bots can only send messages to rooms they are members of. Add bots to rooms through the room membership settings in the admin interface.

In **direct rooms**, bots receive all messages (not just mentions).

In **open/closed rooms**, bots only receive messages where they are @mentioned.

## Example Bot (Ruby)

```ruby
require "sinatra"
require "json"

BOT_KEY = ENV["BOT_KEY"]
BASE_URL = ENV["CORDLESS_URL"]

post "/webhook" do
  begin
    payload = JSON.parse(request.body.read)
    message = payload.dig("message", "body", "plain")&.downcase

    unless message
      status 400
      return
    end

    response = case message
    when /hello/
      "Hello! I'm a friendly bot."
    when /help/
      "I can respond to: hello, help, time"
    when /time/
      "The current time is #{Time.now}"
    else
      nil
    end

    if response
      content_type "text/plain"
      response
    else
      status 204
    end
  rescue JSON::ParserError
    status 400
  end
end
```

## Example Bot (Node.js)

```javascript
const express = require('express');
const app = express();

app.use(express.json());

app.post('/webhook', (req, res) => {
  const message = req.body?.message?.body?.plain?.toLowerCase();

  if (!message) {
    return res.status(400).end();
  }

  if (message.includes('hello')) {
    res.type('text/plain').send("Hello! I'm a friendly bot.");
  } else if (message.includes('time')) {
    res.type('text/plain').send(`The current time is ${new Date()}`);
  } else {
    res.status(204).end();
  }
});

app.listen(3000);
```

## Security Considerations

1. **Validate webhook source**: Consider validating that webhook requests come from your Cordless instance (check source IP or implement a shared secret).

2. **Rate limiting**: Your webhook should handle bursts of traffic. Cordless doesn't currently de-duplicate rapid mentions.

3. **Response size**: Keep responses under 10MB. Large responses will be rejected.

4. **HTTPS**: Use HTTPS for your webhook URL in production.

5. **Bot key security**: Treat the bot key like a password. Don't commit it to version control. URLs containing credentials may be logged.

6. **Input validation**: Always validate the webhook payload structure before processing to avoid crashes on malformed input.
