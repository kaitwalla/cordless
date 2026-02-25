class Autocompletable::EmojisController < ApplicationController
  def index
    if params.key?(:all)
      render_all_emojis
    else
      render_autocomplete_emojis
    end
  end

  private

  def render_all_emojis
    @custom_emojis = CustomEmoji.ordered.with_attached_image
    @unicode_emojis_by_category = UnicodeEmoji.all.group_by(&:category)
    render :all
  end

  def render_autocomplete_emojis
    @custom_emojis = find_custom_emojis.limit(10)
    @unicode_emojis = find_unicode_emojis.first(10)
  end

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
