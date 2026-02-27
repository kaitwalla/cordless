class RemoveImagesFromReplyAttachmentContent < ActiveRecord::Migration[8.0]
  def up
    ActionText::RichText.find_each do |rich_text|
      body_html = rich_text.body.to_s
      next unless body_html.include?("application/vnd.cordless.reply")

      updated = false
      new_body = body_html.gsub(/(<action-text-attachment[^>]*content=")([^"]*)(")/) do |match|
        prefix = $1
        content = $2
        suffix = $3

        # Decode HTML entities in the content attribute
        decoded_content = CGI.unescapeHTML(content)

        # Remove <img> tags from the content
        if decoded_content.include?("<img")
          cleaned_content = decoded_content.gsub(/<img[^>]*>/, "")
          updated = true
          prefix + CGI.escapeHTML(cleaned_content) + suffix
        else
          match
        end
      end

      if updated
        rich_text.update_column(:body, new_body)
        puts "Cleaned reply attachment content in RichText ##{rich_text.id}"
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
