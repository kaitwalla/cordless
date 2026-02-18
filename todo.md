# Cordless - Technical Debt & Improvements

## Critical Priority

### ~~1. Fix O(n) Direct Room Lookup~~ ✅ DONE
**File**: `app/models/rooms/direct.rb`
**Status**: Implemented with `membership_hash` column and O(1) lookup via `find_by`.

---

### 2. Switch from Rails Main Branch to Stable Release
**File**: `Gemfile`
**Impact**: Alpha releases have breaking changes; not production-ready

**Current**:
```ruby
gem "rails", github: "rails/rails", branch: "main"
gem "propshaft", github: "rails/propshaft", branch: "main"
gem "importmap-rails", github: "rails/importmap-rails", branch: "main"
gem "turbo-rails", github: "hotwired/turbo-rails", branch: "main"
```

**Implementation**:
```ruby
# When Rails 8.0 stable releases, change to:
gem "rails", "~> 8.0.0"
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
```

Then run:
```bash
bundle update rails propshaft importmap-rails turbo-rails
bin/rails app:update
```

---

### ~~3. Add QR Code URL Validation~~ ✅ DONE
**File**: `app/controllers/qr_code_controller.rb`
**Status**: Implemented with URL length check, HTTP/HTTPS validation, and proper error handling.

---

### ~~4. Improve Webhook Delivery Error Handling~~ ✅ DONE
**File**: `app/models/webhook.rb`
**Status**: Implemented with MAX_RESPONSE_SIZE constant, detailed exception handling (timeout, SSL, connection errors), Sentry integration, and URL validation.

---

## High Priority

### ~~5. Add Message Pagination Database Index~~ ✅ DONE
**File**: `app/models/message/pagination.rb`
**Status**: Implemented with `PAGE_SIZE` constant and cursor-based pagination using `id` as tiebreaker for stable ordering. Migration added.

---

### ~~6. Add Input Validation for Enum Parameters~~ ✅ DONE
**File**: `app/controllers/rooms/involvements_controller.rb`
**Status**: Implemented with enum validation before update, returning `:bad_request` for invalid values.

---

### ~~7. Fix N+1 Query in MessagePusher~~ ✅ DONE
**File**: `app/models/message.rb`, `app/jobs/room/push_message_job.rb`
**Status**: Implemented with `scope :for_push` that includes associations, used in the job.

---

### ~~8. Improve Exception Handling in OpenGraph Fetching~~ ✅ DONE
**File**: `app/models/opengraph/location.rb`, `app/models/opengraph/metadata/fetching.rb`
**Status**: Implemented with detailed exception handling for all error types (SSRF, redirects, timeouts, SSL), Sentry integration, and typo fix.

---

## Medium Priority

### ~~9. Add Code Coverage Reporting~~ ✅ DONE
**File**: `Gemfile`, `test/test_helper.rb`
**Status**: SimpleCov added to Gemfile and test_helper.rb with 70% minimum coverage, enabled via `COVERAGE=true` env var.

---

### ~~10. Add System Tests for Key User Flows~~ ✅ DONE
**File**: `test/system/`
**Status**: 16 system test files now (was 3). Added tests for:
- `authentication_test.rb` - Login/logout flows
- `room_creation_test.rb` - Creating open/closed rooms
- `room_involvement_test.rb` - Notification settings
- `room_membership_test.rb` - Adding/removing members
- `direct_messages_test.rb` - DM conversations
- `search_test.rb` - Search functionality
- `user_management_test.rb` - Admin user management
- `bot_management_test.rb` - Bot configuration
- `profile_test.rb` - Profile editing
- `first_run_test.rb` - Account setup
- `mentions_test.rb` - @mention autocomplete
- `account_settings_test.rb` - Organization settings
- `message_attachments_test.rb` - File attachments

---

### ~~11. Add API Documentation for Bot Webhooks~~ ✅ DONE
**File**: `docs/bot-api.md`
**Status**: Comprehensive documentation created covering authentication, API endpoints, webhook payloads/responses, error handling, and example bots in Ruby and Node.js.

---

### ~~12. Fix Broadcasting Scope Leak~~ ✅ DONE
**File**: `app/models/message/broadcasts.rb`, `app/channels/unread_rooms_channel.rb`
**Status**: Implemented per-user broadcasts to `unread_rooms:#{user_id}` instead of global channel.

---

### ~~13. Tighten Dependency Version Constraints~~ ✅ DONE
**File**: `Gemfile`
**Status**: All key gems now have proper pessimistic version constraints (~>).

---

## Low Priority

### ~~14. Add Rate Limiting to Core Features~~ ✅ DONE
**File**: `app/controllers/messages_controller.rb`, `app/controllers/rooms_controller.rb`, `app/controllers/searches_controller.rb`
**Status**: Rate limiting implemented - messages (60/min), rooms (10/min), searches (30/min).

---

### ~~15. Add Audit Logging~~ ✅ DONE
**File**: `app/models/audit_log.rb`, `app/models/concerns/auditable.rb`
**Status**: Implemented with AuditLog model, Auditable concern (with sensitive field filtering), included in User, Room, and Ban models.

---

### ~~16. Add Tests for Untested Core Models~~ ✅ DONE
**File**: `test/models/`
**Status**: Tests added for Ban, Session, Search, Boost, and AuditLog models.

---

### ~~17. Define Magic Number Constants~~ ✅ DONE
**File**: Various models
**Status**: Constants defined - `BOT_TOKEN_LENGTH` (12), `RECENT_SEARCHES_LIMIT` (10), `PAGE_SIZE` (40), `MAX_RESPONSE_SIZE` (10MB).

---

### ~~18. Add Data Export Functionality~~ ✅ DONE
**File**: `app/controllers/accounts/exports_controller.rb`, `app/models/export.rb`, `app/jobs/accounts/export_job.rb`
**Status**: Implemented with Export model, background job, Active Storage attachment for zip file, and admin-only controller. Migration added.

---

## Testing Improvements Summary

| Area | Current | Target | Priority | Status |
|------|---------|--------|----------|--------|
| Model coverage | ~70% | 80% | High | ✅ Improved |
| System tests | 16 | 15+ | Medium | ✅ Done |
| Code coverage tool | SimpleCov | SimpleCov | Medium | ✅ Done |
| Factory library | None | Consider factory_bot | Low | ❌ Pending |
| Push notification tests | None | Add coverage | Medium | ❌ Pending |
| PWA tests | None | Add coverage | Low | ❌ Pending |

---

## Remaining Items

The following item still needs work:

1. **#2 - Switch from Rails Main Branch** - Blocked until Rails 8.0 stable releases

---

## Completion Summary

**17 of 18 items completed.** The only remaining item (#2) is blocked waiting for Rails 8.0 stable release.
