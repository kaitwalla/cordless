class CustomEmojisController < ApplicationController
  before_action :ensure_can_administer, only: :destroy
  before_action :set_custom_emoji, only: :destroy

  def index
    @custom_emojis = CustomEmoji.ordered.with_attached_image
  end

  def new
    @custom_emoji = CustomEmoji.new
  end

  def create
    @custom_emoji = CustomEmoji.new(custom_emoji_params)
    @custom_emoji.creator = Current.user

    if @custom_emoji.save
      redirect_to custom_emojis_url, notice: "Emoji :#{@custom_emoji.shortcode}: was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @custom_emoji.destroy!
    redirect_to custom_emojis_url, notice: "Emoji :#{@custom_emoji.shortcode}: was deleted."
  end

  private

  def set_custom_emoji
    @custom_emoji = CustomEmoji.find(params[:id])
  end

  def custom_emoji_params
    params.require(:custom_emoji).permit(:shortcode, :image)
  end
end
