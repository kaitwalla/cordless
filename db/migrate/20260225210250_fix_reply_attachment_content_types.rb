class FixReplyAttachmentContentTypes < ActiveRecord::Migration[8.0]
  def up
    # Find all ActionText::RichText records that contain action-text-attachment tags
    # with Message SGIDs but missing or incorrect content-type
    ActionText::RichText.find_each do |rich_text|
      body_html = rich_text.body.to_s
      next unless body_html.include?("action-text-attachment")

      # Check if any attachments reference Message SGIDs
      next unless body_html.include?("gid://")

      updated = false
      new_body = body_html.gsub(/<action-text-attachment([^>]*)>/) do |match|
        attrs = $1

        # Skip if it's not a Message attachment (check for Message in the sgid)
        next match unless attrs.include?("Message")

        # Skip if it already has the correct content-type
        next match if attrs.include?('content-type="application/vnd.cordless.reply"')

        # Add or fix the content-type
        if attrs.include?("content-type=")
          # Replace existing content-type
          attrs = attrs.gsub(/content-type="[^"]*"/, 'content-type="application/vnd.cordless.reply"')
        else
          # Add content-type attribute
          attrs = attrs + ' content-type="application/vnd.cordless.reply"'
        end

        updated = true
        "<action-text-attachment#{attrs}>"
      end

      if updated
        # Update the body directly in the database to avoid callbacks
        rich_text.update_column(:body, new_body)
        puts "Fixed reply attachment in RichText ##{rich_text.id}"
      end
    end
  end

  def down
    # This migration is not reversible - we can't know which attachments
    # had incorrect content types before
    raise ActiveRecord::IrreversibleMigration
  end
end
