class String
  EMOJI_PATTERN = /\p{Emoji_Presentation}|\p{Extended_Pictographic}/u
  WHITESPACE_PATTERN = /[\s\u00A0]/  # Include non-breaking space

  def all_emoji?
    stripped = self.gsub(WHITESPACE_PATTERN, "")
    stripped.present? && stripped.match?(/\A(#{EMOJI_PATTERN}|\uFE0F)+\z/u)
  end

  def emoji_count
    # Count emoji sequences (handles compound emojis like flags, skin tones, ZWJ sequences)
    self.scan(/#{EMOJI_PATTERN}(\uFE0F|\u200D#{EMOJI_PATTERN})*/u).count
  end
end
