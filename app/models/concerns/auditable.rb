module Auditable
  extend ActiveSupport::Concern

  included do
    after_create_commit { audit_log("create") }
    after_update_commit { audit_log("update", previous_changes) }
    after_destroy_commit { audit_log("destroy") }
  end

  private
    def audit_log(action, changes = nil)
      return unless Current.user

      AuditLog.create!(
        user: Current.user,
        action: action,
        resource_type: self.class.name,
        resource_id: id,
        changes_made: sanitized_changes(changes),
        ip_address: Current.request&.remote_ip
      )
    rescue StandardError => e
      Rails.logger.error("Failed to create audit log: #{e.message}")
    end

    def sanitized_changes(changes)
      return nil unless changes

      # Remove sensitive fields from audit log
      changes.except("password_digest", "bot_token", "token")
    end
end
