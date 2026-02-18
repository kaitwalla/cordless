require "test_helper"

class SearchTest < ActiveSupport::TestCase
  test "records a new search" do
    assert_difference -> { users(:jason).searches.count }, +1 do
      users(:jason).searches.record("new query")
    end
  end

  test "touches existing search instead of creating duplicate" do
    existing = searches(:david_pizza)
    original_updated_at = existing.updated_at

    travel 1.minute do
      assert_no_difference -> { users(:david).searches.count } do
        users(:david).searches.record("pizza")
      end
    end

    assert existing.reload.updated_at > original_updated_at
  end

  test "trims searches to recent limit" do
    user = users(:jason)
    user.searches.destroy_all  # Clear any fixture data

    # Create more than the limit
    (Search::RECENT_SEARCHES_LIMIT + 5).times do |i|
      user.searches.create!(query: "query #{i}")
    end

    assert_equal Search::RECENT_SEARCHES_LIMIT, user.searches.count
  end

  test "orders by most recent" do
    user = users(:jason)
    old_search = user.searches.create!(query: "old")

    travel 1.minute do
      new_search = user.searches.create!(query: "new")
      assert_equal new_search, user.searches.ordered.first
    end
  end
end
