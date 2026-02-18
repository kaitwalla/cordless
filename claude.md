# Cordless - Claude Code Documentation

## Overview

Cordless is a web-based team chat application built with Rails 8. It provides real-time messaging, room management, direct messages, file attachments, web push notifications, and bot integrations via webhooks.

**Architecture**: Single-tenant (one account per instance, enforced by database singleton constraint)

## Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | Ruby on Rails | 8.2.x (main branch) |
| Ruby | Ruby | 3.4.5 |
| Database | SQLite3 | 2.7.x |
| Cache/Queue Backend | Redis | 5.4.x |
| Job Processing | Resque + resque-pool | 2.7.x |
| Real-time | ActionCable + Turbo Streams | - |
| Frontend JS | Stimulus + Hotwire | - |
| Asset Pipeline | Propshaft + Importmap | - |
| Web Server | Puma + Thruster | 6.6.x |

## Directory Structure

```
app/
├── models/                     # ActiveRecord models
│   ├── account.rb             # Organization config (singleton)
│   ├── user.rb                # Users with authentication
│   ├── room.rb                # Base room model
│   ├── rooms/                 # Polymorphic room types
│   │   ├── open.rb           # Auto-membership for all users
│   │   ├── closed.rb         # Explicit membership only
│   │   └── direct.rb         # 1:1 or group DMs
│   ├── message.rb             # Messages with ActionText body
│   ├── message/               # Message concerns
│   │   ├── attachment.rb     # File handling, thumbnails
│   │   ├── broadcasts.rb     # Turbo Stream broadcasts
│   │   ├── mentionee.rb      # @mention extraction
│   │   ├── pagination.rb     # Cursor-based pagination
│   │   └── searchable.rb     # FTS5 search indexing
│   ├── membership.rb          # User-room associations
│   ├── user/                  # User concerns
│   │   ├── avatar.rb         # Avatar attachments
│   │   ├── bot.rb            # Bot authentication/webhooks
│   │   ├── role.rb           # Authorization (admin/member/bot)
│   │   ├── bannable.rb       # IP ban management
│   │   ├── mentionable.rb    # Mention representations
│   │   └── transferable.rb   # Account transfer on deactivation
│   ├── room/
│   │   └── message_pusher.rb # Web push notification logic
│   ├── webhook.rb             # Bot webhook configuration
│   ├── push.rb                # Web push subscriptions
│   ├── session.rb             # User sessions
│   ├── ban.rb                 # IP address bans
│   ├── boost.rb               # Message reactions
│   └── search.rb              # Search history
│
├── controllers/
│   ├── application_controller.rb    # Base with auth concerns
│   ├── rooms_controller.rb          # Room CRUD
│   ├── messages_controller.rb       # Message creation
│   ├── sessions_controller.rb       # Login/logout
│   ├── accounts/                    # Account management
│   │   ├── users_controller.rb     # User admin
│   │   └── bots_controller.rb      # Bot management
│   ├── messages/
│   │   └── by_bots_controller.rb   # Bot API endpoint
│   ├── rooms/
│   │   ├── memberships_controller.rb
│   │   └── involvements_controller.rb
│   ├── users/
│   │   ├── bans_controller.rb
│   │   └── push_subscriptions_controller.rb
│   └── concerns/
│       ├── authentication.rb        # Login/session management
│       ├── authorization.rb         # Permission checking
│       └── block_banned_requests.rb # Ban enforcement
│
├── channels/                   # ActionCable WebSocket channels
│   ├── room_channel.rb        # Real-time room messages
│   ├── presence_channel.rb    # User online status
│   ├── typing_notifications_channel.rb
│   ├── unread_rooms_channel.rb
│   └── heartbeat_channel.rb
│
├── jobs/
│   ├── room/
│   │   └── push_message_job.rb     # Web push delivery
│   └── bot/
│       └── webhook_job.rb          # Webhook delivery
│
└── javascript/
    ├── controllers/           # Stimulus controllers
    └── lib/                   # Rich text, autocomplete, unfurl

lib/
├── restricted_http/           # SSRF protection
│   └── private_network_guard.rb
└── web_push/                  # Push notification utilities

config/
├── routes.rb                  # URL routing
├── database.yml               # SQLite config
├── cable.yml                  # ActionCable/Redis
├── storage.yml                # Active Storage (local/S3/GCS)
├── resque-pool.yml            # Worker configuration
└── initializers/
    ├── sentry.rb              # Error tracking
    └── vapid.rb               # Web push keys

test/
├── models/                    # Unit tests (20 files)
├── controllers/               # Integration tests (31 files)
├── system/                    # Browser tests (3 files)
├── channels/                  # WebSocket tests (2 files)
├── fixtures/                  # Test data (11 YAML files)
└── test_helpers/              # Custom helpers
```

## Key Concepts

### Room Types (Polymorphic STI)

| Type | Class | Behavior |
|------|-------|----------|
| Open | `Rooms::Open` | Auto-grants membership to all account users |
| Closed | `Rooms::Closed` | Explicit membership required |
| Direct | `Rooms::Direct` | Singleton per user set, always "everything" involvement |

### Membership Involvement Levels

| Level | Notifications | Visibility |
|-------|--------------|------------|
| `invisible` | None | Hidden from room, data retained |
| `nothing` | None | Visible, no push |
| `mentions` | @mentions only | Push for mentions |
| `everything` | All messages | Push for everything |

### User Roles

| Role | Capabilities |
|------|-------------|
| `administrator` | Full access, can manage users/rooms/bots |
| `member` | Standard user, can create rooms/messages |
| `bot` | API access via bot_key, webhook delivery |

### Bot Authentication

Bots authenticate via `bot_key` in format `{user_id}-{bot_token}`:
- Token is 12 alphanumeric characters stored on User model
- CSRF protection skipped for bot_key authentication
- Webhook responses can include text or file attachments

### Real-time Architecture

1. **ActionCable Channels**: `RoomChannel`, `PresenceChannel`, `TypingNotificationsChannel`, `UnreadRoomsChannel`
2. **Turbo Streams**: Message creation/update/deletion broadcast via `Message::Broadcasts`
3. **Web Push**: Delivered via `Room::PushMessageJob` based on membership involvement and connection state

### Search

- Uses SQLite FTS5 virtual table (`message_search_index`)
- Indexed on message creation via `Message::Searchable`
- Search history stored per-user in `searches` table

## Development Guidelines

### Docker Development

All development commands should be run inside the Docker container:

```bash
# Start development environment
docker compose up

# Run commands inside the container
docker compose exec web bin/rails db:migrate
docker compose exec web bin/rails test
docker compose exec web bin/rubocop

# Open a shell in the container
docker compose exec web bash
```

### Code Style

- Follow Rails conventions and rubocop-rails-omakase rules
- Run `docker compose exec web bin/rubocop` before committing
- Run `docker compose exec web bin/brakeman` for security scanning

### Testing

```bash
# Run all tests
docker compose exec web bin/rails test

# Run system tests (requires Chrome)
docker compose exec web bin/rails test:system

# Run specific test file
docker compose exec web bin/rails test test/models/user_test.rb
```

- Use Minitest assertions
- Use Mocha for mocking (`mocha/minitest`)
- Use fixtures in `test/fixtures/` for test data
- WebMock is enabled by default - external HTTP is blocked

### Database

```bash
# Setup
bin/rails db:setup

# Migrations
bin/rails db:migrate

# Reset
bin/rails db:reset
```

SQLite with immediate transactions. Schema in `db/schema.rb`.

### Background Jobs

```bash
# Start workers (development)
bin/dev

# Or manually
QUEUE=* rake resque:work
```

Jobs use Resque with Redis backend. Key jobs:
- `Room::PushMessageJob` - Web push notifications
- `Bot::WebhookJob` - Webhook delivery

### Environment Variables

| Variable | Purpose | Required |
|----------|---------|----------|
| `SECRET_KEY_BASE` | Encryption key | Yes |
| `VAPID_PUBLIC_KEY` | Web push public key | Yes (for push) |
| `VAPID_PRIVATE_KEY` | Web push private key | Yes (for push) |
| `SENTRY_DSN` | Error tracking | No |
| `SSL_DOMAIN` | Let's Encrypt domain | No |
| `DISABLE_SSL` | Disable forced SSL | No |
| `REDIS_URL` | Redis connection | No (defaults to localhost) |

## Common Patterns

### Adding a New Model Concern

```ruby
# app/models/model_name/concern_name.rb
module ModelName::ConcernName
  extend ActiveSupport::Concern

  included do
    # associations, validations, callbacks
  end

  # instance methods

  class_methods do
    # class methods
  end
end

# Include in model
class ModelName < ApplicationRecord
  include ModelName::ConcernName
end
```

### Adding a Controller with Authorization

```ruby
class Things::ActionsController < ApplicationController
  include RoomScoped  # if room-scoped

  before_action :set_thing
  before_action :require_administrator  # if admin-only

  def update
    authorize @thing  # checks can_administer?
    @thing.update!(thing_params)
  end

  private

  def set_thing
    @thing = @room.things.find(params[:id])
  end
end
```

### Broadcasting Real-time Updates

```ruby
# In model
after_create_commit :broadcast_create

def broadcast_create
  broadcast_append_to room, :messages, target: [room, :messages]
end

# Or manually
Turbo::StreamsChannel.broadcast_append_to(
  room, :messages,
  target: [room, :messages],
  partial: "messages/message",
  locals: { message: self }
)
```

### Testing with Fixtures

```ruby
# test/models/thing_test.rb
class ThingTest < ActiveSupport::TestCase
  setup do
    @user = users(:david)  # from test/fixtures/users.yml
    @room = rooms(:watercooler)
  end

  test "does something" do
    assert @user.can_do_thing?(@room)
  end
end
```

### Testing Controllers

```ruby
# test/controllers/things_controller_test.rb
class ThingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:david)
    sign_in @user  # from SessionTestHelper
  end

  test "creates thing" do
    post things_url, params: { thing: { name: "Test" } }
    assert_response :redirect
  end
end
```

## Known Issues & Technical Debt

See `todo.md` for detailed list. Key items:

1. **Performance**: `Rooms::Direct.find_for` uses O(n) algorithm - needs optimization
2. **Dependencies**: Running on Rails main branch (alpha) - not production-ready
3. **Testing**: Only 50% model coverage, 3 system tests
4. **Security**: Some input validation gaps, webhook error handling incomplete

## Deployment

### Docker

```bash
docker build -t cordless .
docker run -e SECRET_KEY_BASE=... -e VAPID_PUBLIC_KEY=... -e VAPID_PRIVATE_KEY=... -p 3000:3000 cordless
```

Persistent storage at `/rails/storage`.

### Manual

```bash
bundle install
bin/rails db:setup
bin/rails assets:precompile
bin/rails server
```

Requires Redis running for ActionCable and Resque.
