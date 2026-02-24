class SlashCommand < ApplicationRecord
  belongs_to :bot, class_name: "User", optional: true

  validates :name, presence: true, uniqueness: true,
    format: { with: /\A[a-z0-9_]+\z/, message: "only allows lowercase letters, numbers, and underscores" }
  validates :description, presence: true
  validates :bot, presence: true, if: :webhook?

  enum :command_type, { builtin: 0, webhook: 1 }

  scope :ordered, -> { order(:name) }
  scope :filtered_by, ->(query) {
    sanitized = sanitize_sql_like(query)
    where("name LIKE ? OR description LIKE ?", "%#{sanitized}%", "%#{sanitized}%")
  }

  def execute(args:, room:, user:)
    if builtin?
      handler_class.new(args: args, room: room, user: user).execute
    elsif webhook? && bot
      bot.deliver_webhook_for_command(self, args, room, user)
    end
  end

  def handler_class
    "SlashCommand::#{name.camelize}Handler".constantize
  rescue NameError
    SlashCommand::BaseHandler
  end
end
