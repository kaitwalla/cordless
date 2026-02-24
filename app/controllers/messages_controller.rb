class MessagesController < ApplicationController
  include ActiveStorage::SetCurrent, RoomScoped

  rate_limit to: 60, within: 1.minute, only: :create

  before_action :set_room, except: :create
  before_action :set_message, only: %i[ show edit update destroy ]
  before_action :ensure_can_administer, only: %i[ edit update destroy ]

  layout false, only: :index

  def index
    @messages = find_paged_messages

    if @messages.any?
      fresh_when @messages
    else
      head :no_content
    end
  end

  def create
    set_room
    @message = @room.messages.create_with_attachment!(message_params)

    @message.broadcast_create

    if command = detect_slash_command(@message)
      execute_slash_command(command, @message)
    else
      deliver_webhooks_to_bots
    end
  rescue ActiveRecord::RecordNotFound
    render action: :room_not_found
  end

  def show
  end

  def edit
  end

  def update
    @message.update!(message_params)

    @message.broadcast_replace_to @room, :messages, target: [ @message, :presentation ], partial: "messages/presentation", attributes: { maintain_scroll: true }
    redirect_to room_message_url(@room, @message)
  end

  def destroy
    @message.destroy
    @message.broadcast_remove
  end

  private
    def set_message
      @message = @room.messages.find(params[:id])
    end

    def ensure_can_administer
      head :forbidden unless Current.user.can_administer?(@message)
    end


    def find_paged_messages
      case
      when params[:before].present?
        @room.messages.with_creator.page_before(@room.messages.find(params[:before]))
      when params[:after].present?
        @room.messages.with_creator.page_after(@room.messages.find(params[:after]))
      else
        @room.messages.with_creator.last_page
      end
    end


    def message_params
      params.require(:message).permit(:body, :attachment, :client_message_id)
    end


    def deliver_webhooks_to_bots
      bots_eligible_for_webhook.excluding(@message.creator).each { |bot| bot.deliver_webhook_later(@message) }
    end

    def bots_eligible_for_webhook
      @room.direct? ? @room.users.active_bots : @message.mentionees.active_bots
    end


    def detect_slash_command(message)
      plain_text = message.plain_text_body.to_s.strip
      return unless plain_text.start_with?("/")

      match = plain_text.match(/\A\/([a-z0-9_]+)/)
      SlashCommand.find_by(name: match[1]) if match
    end

    def execute_slash_command(command, message)
      args = message.plain_text_body.to_s.strip.sub(/\A\/[a-z0-9_]+\s*/, "")
      command.execute(message: message, args: args, room: @room, user: Current.user)
    end
end
