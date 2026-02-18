require "restricted_http/private_network_guard"

class Opengraph::Location
  include ActiveModel::Validations

  attr_accessor :url, :parsed_url

  validate :validate_url, :validate_url_is_public

  def initialize(url)
    @url = url
  end

  def read_html
    fetch_html if valid? && !url.match(FILES_AND_MEDIA_URL_REGEX)
  end

  def fetch_content_type
    Opengraph::Fetch.new.fetch_content_type(parsed_url, ip: resolved_ip) if valid?
  rescue Net::OpenTimeout, Net::ReadTimeout
    Rails.logger.info "OpenGraph: Timeout fetching content type for #{parsed_url}"
    nil
  rescue OpenSSL::SSL::SSLError
    Rails.logger.info "OpenGraph: SSL error fetching content type for #{parsed_url}"
    nil
  rescue => e
    Rails.logger.warn "OpenGraph: Failed to fetch content type for #{parsed_url} (#{e.class}: #{e.message})"
    nil
  end

  def resolved_ip
    return @resolved_ip if defined? @resolved_ip
    @resolved_ip = RestrictedHTTP::PrivateNetworkGuard.resolve(parsed_url.host) rescue nil
  end

  private
    FILES_AND_MEDIA_URL_REGEX = /\bhttps?:\/\/\S+\.(?:zip|tar|tar\.gz|tar\.bz2|tar\.xz|gz|bz2|rar|7z|dmg|exe|msi|pkg|deb|iso|jpg|jpeg|png|gif|bmp|mp4|mov|avi|mkv|wmv|flv|heic|heif|mp3|wav|ogg|aac|wma|webm|ogv|mpg|mpeg)\b/

    def validate_url
      errors.add :url, "is invalid" unless parsed_url.is_a?(URI::HTTP)
    end

    def validate_url_is_public
      errors.add :url, "is not public" unless resolved_ip
    end

    def parsed_url
      return @parsed_url if defined? @parsed_url
      @parsed_url = URI.parse(url) rescue nil
    end

    def fetch_html
      Opengraph::Fetch.new.fetch_document(parsed_url, ip: resolved_ip)
    rescue URI::InvalidURIError
      Rails.logger.info "OpenGraph: Invalid URI #{parsed_url}"
      nil
    rescue RestrictedHTTP::PrivateNetworkGuard::Violation
      Rails.logger.warn "OpenGraph: SSRF blocked for #{parsed_url}"
      nil
    rescue Opengraph::Fetch::TooManyRedirectsError
      Rails.logger.warn "OpenGraph: Too many redirects for #{parsed_url}"
      nil
    rescue Opengraph::Fetch::RedirectDeniedError
      Rails.logger.warn "OpenGraph: Redirect denied for #{parsed_url}"
      nil
    rescue Net::OpenTimeout, Net::ReadTimeout
      Rails.logger.info "OpenGraph: Timeout fetching #{parsed_url}"
      nil
    rescue OpenSSL::SSL::SSLError
      Rails.logger.info "OpenGraph: SSL error for #{parsed_url}"
      nil
    rescue => e
      Rails.logger.error "OpenGraph: Unexpected error for #{parsed_url}: #{e.class} - #{e.message}"
      Sentry.capture_exception(e) if defined?(Sentry)
      nil
    end
end
