class UnicodeEmoji
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :shortcode, :string
  attribute :emoji, :string
  attribute :category, :string

  class << self
    def all
      @all ||= load_emoji_data
    end

    def filtered_by(query)
      query = query.to_s.downcase
      all.select { |e| e.shortcode.include?(query) }
    end

    def find_by_shortcode(shortcode)
      all.find { |e| e.shortcode == shortcode.to_s.downcase }
    end

    def categories
      all.map(&:category).uniq
    end

    def by_category(category)
      all.select { |e| e.category == category }
    end

    private

    def load_emoji_data
      emoji_file = Rails.root.join("config", "emoji.yml")
      return [] unless emoji_file.exist?

      data = YAML.load_file(emoji_file)
      data.flat_map do |category, emojis|
        emojis.map do |shortcode, emoji|
          new(shortcode: shortcode, emoji: emoji, category: category)
        end
      end
    end
  end

  def value
    shortcode
  end

  def name
    emoji
  end

  def type
    "unicode"
  end
end
