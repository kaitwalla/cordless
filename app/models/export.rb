class Export < ApplicationRecord
  belongs_to :account
  belongs_to :requested_by, class_name: "User"

  has_one_attached :file

  enum :status, %i[ pending processing completed failed ], default: :pending

  scope :recent, -> { order(created_at: :desc) }

  def generate!
    return if completed? || processing?

    processing!

    Dir.mktmpdir do |dir|
      export_data(dir)
      zip_path = create_zip(dir)

      File.open(zip_path, "rb") do |zip_file|
        file.attach(
          io: zip_file,
          filename: "cordless-export-#{created_at.strftime('%Y%m%d-%H%M%S')}.zip",
          content_type: "application/zip"
        )
      end
    end

    completed!
  rescue => e
    Rails.logger.error "Export failed: #{e.message}"
    failed!
    raise
  end

  private

  def export_data(dir)
    export_account(dir)
    export_users(dir)
    export_rooms(dir)
    export_messages(dir)
  end

  def export_account(dir)
    File.write("#{dir}/account.json", JSON.pretty_generate(account.as_json(except: :id)))
  end

  def export_users(dir)
    users = account.users.map do |user|
      user.as_json(only: %i[id name email_address bio role status created_at])
    end
    File.write("#{dir}/users.json", JSON.pretty_generate(users))
  end

  def export_rooms(dir)
    rooms = account_rooms.map do |room|
      room.as_json(only: %i[id name type created_at]).merge(
        members: room.users.pluck(:id)
      )
    end
    File.write("#{dir}/rooms.json", JSON.pretty_generate(rooms))
  end

  def export_messages(dir)
    FileUtils.mkdir_p("#{dir}/rooms")

    account_rooms.find_each do |room|
      messages = room.messages.includes(:creator).map do |message|
        {
          id: message.id,
          creator_id: message.creator_id,
          creator_name: message.creator&.name,
          body: message.plain_text_body,
          created_at: message.created_at,
          has_attachment: message.attachment?
        }
      end

      File.write("#{dir}/rooms/#{room.id}.json", JSON.pretty_generate(messages))
    end
  end

  def account_rooms
    Room.joins(:memberships).where(memberships: { user_id: account.users.select(:id) }).distinct
  end

  def create_zip(dir)
    zip_path = "#{dir}/export.zip"

    if defined?(Zip)
      create_zip_with_rubyzip(dir, zip_path)
    else
      Dir.chdir(dir) do
        system("zip", "-r", "export.zip", ".", "-x", "export.zip")
      end
    end

    zip_path
  end

  def create_zip_with_rubyzip(dir, zip_path)
    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      Dir.glob("#{dir}/**/*").each do |file_path|
        next if File.directory?(file_path)
        next if File.expand_path(file_path) == File.expand_path(zip_path)
        zipfile.add(file_path.sub("#{dir}/", ""), file_path)
      end
    end
  end
end
