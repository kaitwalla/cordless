class Autocompletable::EmojisController < ApplicationController
  def index
    @custom_emojis = find_custom_emojis.limit(10)
    @unicode_emojis = find_unicode_emojis.first(10)
  end

  private

  def find_custom_emojis
    query = params[:query].to_s.downcase
    emojis = CustomEmoji.ordered.with_attached_image
    query.present? ? emojis.filtered_by(query) : emojis
  end

  def find_unicode_emojis
    query = params[:query].to_s.downcase
    query.present? ? UnicodeEmoji.filtered_by(query) : UnicodeEmoji.all
  end
end
