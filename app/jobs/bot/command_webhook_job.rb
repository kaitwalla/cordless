class Bot::CommandWebhookJob < ApplicationJob
  def perform(bot, command, args, room, user)
    return unless bot.webhook.present?
    bot.webhook.deliver_command(command, args, room, user)
  end
end
