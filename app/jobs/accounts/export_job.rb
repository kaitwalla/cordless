class Accounts::ExportJob < ApplicationJob
  queue_as :default

  def perform(export)
    export.generate!
  end
end
