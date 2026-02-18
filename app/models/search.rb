class Search < ApplicationRecord
  RECENT_SEARCHES_LIMIT = 10

  belongs_to :user

  after_create :trim_recent_searches

  scope :ordered, -> { order(updated_at: :desc) }

  class << self
    def record(query)
      find_or_create_by(query: query).touch
    end
  end

  private
    def trim_recent_searches
      user.searches.excluding(user.searches.ordered.limit(RECENT_SEARCHES_LIMIT)).destroy_all
    end
end
