module Message::Pagination
  extend ActiveSupport::Concern

  PAGE_SIZE = 40

  included do
    scope :last_page, -> { ordered.last(PAGE_SIZE) }
    scope :first_page, -> { ordered.first(PAGE_SIZE) }

    scope :before, ->(message) { where("created_at < ? OR (created_at = ? AND id < ?)", message.created_at, message.created_at, message.id) }
    scope :after, ->(message) { where("created_at > ? OR (created_at = ? AND id > ?)", message.created_at, message.created_at, message.id) }

    scope :page_before, ->(message) { before(message).last_page }
    scope :page_after, ->(message) { after(message).first_page }

    scope :page_created_since, ->(time) { where("created_at > ?", time).first_page }
    scope :page_updated_since, ->(time) { where("updated_at > ?", time).last_page }
  end

  class_methods do
    def page_around(message)
      page_before(message) + [ message ] + page_after(message)
    end

    def paged?
      count > PAGE_SIZE
    end
  end
end
