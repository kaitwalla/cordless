class Bot::CommandWebhookJob < ApplicationJob
  def perform(bot, message, command, args)
    return unless bot.webhook.present?
    bot.webhook.deliver_command(message, command, args)
  end
end
