require "test_helper"

class BoostTest < ActiveSupport::TestCase
  test "creates a boost on a message" do
    message = messages(:first)

    assert_difference -> { message.boosts.count }, +1 do
      message.boosts.create!(booster: users(:jason), content: "🎉")
    end
  end

  test "touches message when boost is created" do
    message = messages(:first)
    original_updated_at = message.updated_at

    travel 1.minute do
      message.boosts.create!(booster: users(:jason), content: "👍")
    end

    assert message.reload.updated_at > original_updated_at
  end

  test "uses current user as default booster" do
    Current.user = users(:david)
    message = messages(:first)

    boost = message.boosts.create!(content: "✨")

    assert_equal users(:david), boost.booster
  end

  test "orders by creation time" do
    message = messages(:first)
    first_boost = message.boosts.create!(booster: users(:jason), content: "1")

    travel 1.minute do
      second_boost = message.boosts.create!(booster: users(:kevin), content: "2")
      assert_equal [ first_boost, second_boost ], message.boosts.ordered.last(2)
    end
  end
end
