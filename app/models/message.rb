class Message < ApplicationRecord
  include Attachment, Broadcasts, Mentionee, Pagination, Replyable, Searchable

  belongs_to :room, touch: true
  belongs_to :creator, class_name: "User", default: -> { Current.user }

  has_many :boosts, dependent: :destroy

  has_rich_text :body

  before_create -> { self.client_message_id ||= Random.uuid } # Bots don't care
  after_create_commit -> { room.receive(self) }

  scope :ordered, -> { order(:created_at) }
  scope :with_creator, -> { preload(creator: :avatar_attachment) }
  scope :with_attachment_details, -> {
    with_rich_text_body_and_embeds
    with_attached_attachment
      .includes(attachment_blob: :variant_records)
  }
  scope :with_boosts, -> { includes(boosts: :booster) }
  scope :for_push, -> { includes(:rich_text_body, room: { memberships: :user }) }

  def plain_text_body
    body.to_plain_text.presence || attachment&.filename&.to_s || ""
  end

  def emoji_only?
    return false unless body.body.present?

    custom_emoji_count = custom_emoji_attachments.count
    text_without_custom_emoji = plain_text_without_custom_emoji

    if custom_emoji_count > 0 && text_without_custom_emoji.blank?
      # Only custom emojis
      true
    elsif custom_emoji_count == 0
      # Only regular emojis
      text_without_custom_emoji.all_emoji?
    else
      # Mix of custom and regular emojis
      text_without_custom_emoji.all_emoji?
    end
  end

  def total_emoji_count
    custom_count = custom_emoji_attachments.count
    regular_count = plain_text_without_custom_emoji.emoji_count
    custom_count + regular_count
  end

  def to_key
    [ client_message_id ]
  end

  def content_type
    case
    when attachment?    then "attachment"
    when sound.present? then "sound"
    else                     "text"
    end.inquiry
  end

  def sound
    plain_text_body.match(/\A\/play (?<name>\w+)\z/) do |match|
      Sound.find_by_name match[:name]
    end
  end

  private

  def custom_emoji_attachments
    return [] unless body.body.present?
    body.body.attachments.select { |a| a.attachable.is_a?(CustomEmoji) }
  end

  def plain_text_without_custom_emoji
    text = plain_text_body
    # Remove custom emoji shortcodes like :name:
    text.gsub(/:[a-z0-9_-]+:/i, "").gsub(/[\s\u00A0]/, "")
  end
end
