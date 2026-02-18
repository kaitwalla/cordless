require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "starts a new session" do
    session = users(:david).sessions.start!(user_agent: "Test Browser", ip_address: "203.0.113.1")

    assert session.persisted?
    assert_equal "Test Browser", session.user_agent
    assert_equal "203.0.113.1", session.ip_address
    assert session.token.present?
    assert session.last_active_at.present?
  end

  test "generates secure token on creation" do
    session = users(:david).sessions.start!(user_agent: "Test", ip_address: "203.0.113.1")

    assert_equal 24, session.token.length
  end

  test "resumes session and updates activity when stale" do
    session = sessions(:david_safari)
    original_active_at = session.last_active_at

    travel 2.hours do
      session.resume(user_agent: "New Browser", ip_address: "203.0.113.2")
    end

    session.reload
    assert_equal "New Browser", session.user_agent
    assert_equal "203.0.113.2", session.ip_address
    assert session.last_active_at > original_active_at
  end

  test "does not update session when recently active" do
    session = sessions(:david_safari)
    session.update!(last_active_at: 30.minutes.ago)

    session.resume(user_agent: "New Browser", ip_address: "203.0.113.2")

    session.reload
    assert_not_equal "New Browser", session.user_agent
  end
end
