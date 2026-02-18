require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  setup do
    Current.user = users(:david)
  end

  teardown do
    Current.user = nil
  end

  test "logs user creation" do
    assert_difference -> { AuditLog.count }, +1 do
      User.create!(name: "New User", email_address: "new@example.com", password: "secret123456")
    end

    log = AuditLog.last
    assert_equal "create", log.action
    assert_equal "User", log.resource_type
    assert_equal users(:david), log.user
  end

  test "logs user update" do
    user = users(:jason)

    assert_difference -> { AuditLog.count }, +1 do
      user.update!(name: "Jason Updated")
    end

    log = AuditLog.last
    assert_equal "update", log.action
    assert_equal "User", log.resource_type
    assert_includes log.changes_made.keys, "name"
  end

  test "logs room creation" do
    assert_difference -> { AuditLog.count }, +1 do
      Rooms::Open.create!(name: "Audit Test Room")
    end

    log = AuditLog.last
    assert_equal "create", log.action
    assert_equal "Rooms::Open", log.resource_type
  end

  test "logs ban creation" do
    assert_difference -> { AuditLog.count }, +1 do
      Ban.create!(user: users(:jason), ip_address: "203.0.113.50")
    end

    log = AuditLog.last
    assert_equal "create", log.action
    assert_equal "Ban", log.resource_type
  end

  test "sanitizes sensitive fields from changes" do
    user = users(:jason)

    assert_difference -> { AuditLog.count }, +1 do
      user.update!(password: "newsecret123")
    end

    log = AuditLog.last
    assert_not_includes log.changes_made.keys, "password_digest"
  end

  test "does not log when no current user" do
    Current.user = nil

    assert_no_difference -> { AuditLog.count } do
      Ban.create!(user: users(:jason), ip_address: "203.0.113.51")
    end
  end

  test "scopes by resource" do
    room = rooms(:watercooler)

    assert_difference -> { AuditLog.count }, +1 do
      room.update!(name: "Updated Name")
    end

    logs = AuditLog.for_resource(room)
    assert logs.any?, "Expected at least one audit log for resource"
    assert logs.all? { |log| log.resource_type == room.class.name && log.resource_id == room.id }
  end

  test "for_resource returns none for nil" do
    assert_equal AuditLog.none.to_a, AuditLog.for_resource(nil).to_a
  end
end
