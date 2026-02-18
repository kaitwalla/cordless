require "net/http"
require "uri"
require "resolv"

class Webhook < ApplicationRecord
  ENDPOINT_TIMEOUT = 7.seconds
  MAX_RESPONSE_SIZE = 10.megabytes

  belongs_to :user

  validates :url, format: { with: /\Ahttps?:\/\//i, message: "must be HTTP or HTTPS" }
  validate :url_is_valid_uri
  validate :url_is_not_private

  def deliver(message)
    response = post(payload(message))

    if response.body && response.body.bytesize > MAX_RESPONSE_SIZE
      Rails.logger.warn "Webhook response too large: #{url} (#{response.body.bytesize} bytes)"
      return receive_text_reply_to(message.room, text: "Response too large")
    end

    if text = extract_text_from(response)
      receive_text_reply_to(message.room, text: text)
    elsif attachment = extract_attachment_from(response)
      receive_attachment_reply_to(message.room, attachment: attachment)
    end
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.warn "Webhook timeout: #{url} (#{e.class})"
    receive_text_reply_to message.room, text: "Failed to respond (timeout)"
  rescue OpenSSL::SSL::SSLError => e
    Rails.logger.warn "Webhook SSL error: #{url} (#{e.message})"
    receive_text_reply_to message.room, text: "Failed to respond (SSL error)"
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
    Rails.logger.warn "Webhook connection error: #{url} (#{e.class})"
    receive_text_reply_to message.room, text: "Failed to respond (connection error)"
  rescue => e
    Rails.logger.error "Webhook unexpected error: #{url} (#{e.class}: #{e.message})"
    Sentry.capture_exception(e) if defined?(Sentry)
    receive_text_reply_to message.room, text: "Failed to respond (error)"
  end

  private
    def url_is_valid_uri
      URI.parse(url)
    rescue URI::InvalidURIError, ArgumentError
      errors.add(:url, "is not a valid URL")
    end

    def url_is_not_private
      return if url.blank?

      parsed = URI.parse(url)
      return if parsed.host.blank?

      if private_host?(parsed.host)
        errors.add(:url, "cannot point to private or internal addresses")
      end
    rescue URI::InvalidURIError, ArgumentError
      # Already handled by url_is_valid_uri
    end

    def private_host?(host)
      # Check if host is an IP address
      begin
        ip = IPAddr.new(host)
        return ip.loopback? || ip.private? || ip.link_local?
      rescue IPAddr::InvalidAddressError
        # Host is a domain name, resolve it
      end

      # Resolve domain and check all addresses
      begin
        addresses = Resolv.getaddresses(host)
        addresses.any? do |addr|
          ip = IPAddr.new(addr)
          ip.loopback? || ip.private? || ip.link_local?
        end
      rescue Resolv::ResolvError
        false
      end
    end

    def post(payload)
      http.request \
        Net::HTTP::Post.new(uri, "Content-Type" => "application/json").tap { |request| request.body = payload }
    end

    def http
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl = (uri.scheme == "https")
        http.open_timeout = ENDPOINT_TIMEOUT
        http.read_timeout = ENDPOINT_TIMEOUT
      end
    end

    def uri
      @uri ||= URI.parse(url)
    end

    def payload(message)
      {
        user:    { id: message.creator.id, name: message.creator.name },
        room:    { id: message.room.id, name: message.room.name, path: room_bot_messages_path(message) },
        message: { id: message.id, body: { html: message.body.body, plain: without_recipient_mentions(message.plain_text_body) }, path: message_path(message) }
      }.to_json
    end

    def message_path(message)
      Rails.application.routes.url_helpers.room_at_message_path(message.room, message)
    end

    def room_bot_messages_path(message)
      Rails.application.routes.url_helpers.room_bot_messages_path(message.room, user.bot_key)
    end

    def extract_text_from(response)
      String.new(response.body).force_encoding("UTF-8") if response.code == "200" && response.content_type.in?(%w[ text/html text/plain ])
    end

    def receive_text_reply_to(room, text:)
      room.messages.create!(body: text, creator: user).broadcast_create
    end

    def extract_attachment_from(response)
      if response.content_type && mime_type = Mime::Type.lookup(response.content_type)
        ActiveStorage::Blob.create_and_upload! \
          io: StringIO.new(response.body), filename: "attachment.#{mime_type.symbol}", content_type: mime_type.to_s
      end
    end

    def receive_attachment_reply_to(room, attachment:)
      room.messages.create_with_attachment!(attachment: attachment, creator: user).broadcast_create
    end

    def without_recipient_mentions(body)
      body \
        .gsub(user.attachable_plain_text_representation(nil), "") # Remove mentions of the recipient user
        .gsub(/\A\p{Space}+|\p{Space}+\z/, "") # Remove leading and trailing whitespace uncluding unicode spaces
    end
end
