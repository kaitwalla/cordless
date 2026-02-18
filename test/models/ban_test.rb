require "test_helper"

class BanTest < ActiveSupport::TestCase
  test "bans user by IP address" do
    ban = Ban.create!(user: users(:david), ip_address: "203.0.113.1")

    assert ban.persisted?
    assert_equal "203.0.113.1", ban.ip_address
  end

  test "detects banned IP" do
    Ban.create!(user: users(:david), ip_address: "203.0.113.1")

    assert Ban.banned?("203.0.113.1")
    assert_not Ban.banned?("203.0.113.2")
  end

  test "rejects private IP addresses" do
    ban = Ban.new(user: users(:david), ip_address: "192.168.1.1")

    assert_not ban.valid?
    assert_includes ban.errors[:ip_address], "cannot be a private or internal IP address"
  end

  test "rejects loopback IP addresses" do
    ban = Ban.new(user: users(:david), ip_address: "127.0.0.1")

    assert_not ban.valid?
    assert_includes ban.errors[:ip_address], "cannot be a private or internal IP address"
  end

  test "rejects link-local IP addresses" do
    ban = Ban.new(user: users(:david), ip_address: "169.254.1.1")

    assert_not ban.valid?
    assert_includes ban.errors[:ip_address], "cannot be a private or internal IP address"
  end

  test "rejects invalid IP addresses" do
    ban = Ban.new(user: users(:david), ip_address: "not-an-ip")

    assert_not ban.valid?
    assert_includes ban.errors[:ip_address], "is not a valid IP address"
  end
end
