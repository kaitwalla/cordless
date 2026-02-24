class CustomEmoji < ApplicationRecord
  include ActionText::Attachable

  belongs_to :creator, class_name: "User"

  has_one_attached :image

  validates :shortcode, presence: true, uniqueness: true,
    format: { with: /\A[a-z0-9_-]+\z/, message: "only allows lowercase letters, numbers, underscores, and hyphens" }
  validates :image, presence: true

  scope :ordered, -> { order(:shortcode) }
  scope :filtered_by, ->(query) { where("shortcode LIKE ?", "%#{sanitize_sql_like(query)}%") }

  def to_attachable_partial_path
    "custom_emojis/custom_emoji"
  end

  def to_trix_content_attachment_partial_path
    "custom_emojis/custom_emoji"
  end

  def attachable_plain_text_representation(caption)
    ":#{shortcode}:"
  end
end
