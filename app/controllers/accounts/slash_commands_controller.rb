class Accounts::SlashCommandsController < ApplicationController
  before_action :ensure_can_administer
  before_action :set_slash_command, only: %i[edit update destroy]
  before_action :ensure_webhook_command, only: %i[edit update destroy]

  def index
    @slash_commands = SlashCommand.ordered.includes(:bot)
    @bots = User.active_bots.ordered
  end

  def new
    @slash_command = SlashCommand.new(command_type: :webhook)
    @bots = User.active_bots.ordered
  end

  def create
    @slash_command = SlashCommand.new(slash_command_params)

    if @slash_command.save
      redirect_to account_slash_commands_url, notice: "Command /#{@slash_command.name} was created."
    else
      @bots = User.active_bots.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @bots = User.active_bots.ordered
  end

  def update
    if @slash_command.update(slash_command_params)
      redirect_to account_slash_commands_url, notice: "Command /#{@slash_command.name} was updated."
    else
      @bots = User.active_bots.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @slash_command.destroy!
    redirect_to account_slash_commands_url, notice: "Command /#{@slash_command.name} was deleted."
  end

  private

  def set_slash_command
    @slash_command = SlashCommand.find(params[:id])
  end

  def ensure_webhook_command
    head :forbidden if @slash_command.builtin?
  end

  def slash_command_params
    params.require(:slash_command).permit(:name, :description, :usage_hint, :command_type, :bot_id)
  end
end
