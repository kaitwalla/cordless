class Accounts::ExportsController < ApplicationController
  before_action :require_administrator

  def show
    @export = Current.account.exports.recent.first
  end

  def create
    export = Current.account.exports.create!(requested_by: Current.user)
    Accounts::ExportJob.perform_later(export)
    redirect_to account_export_url, notice: "Export started. This page will update when ready."
  end

  def download
    @export = Current.account.exports.find(params[:id])

    if @export.file.attached?
      redirect_to rails_blob_path(@export.file, disposition: "attachment")
    else
      redirect_to account_export_url, alert: "Export not ready yet."
    end
  end
end
