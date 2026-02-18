class QrCodeController < ApplicationController
  allow_unauthenticated_access

  def show
    url = Base64.urlsafe_decode64(params[:id])

    return head :bad_request if url.length > 2048

    parsed = URI.parse(url)
    return head :bad_request unless parsed.is_a?(URI::HTTP) || parsed.is_a?(URI::HTTPS)

    qr_code = RQRCode::QRCode.new(url).as_svg(viewbox: true, fill: :white, color: :black)

    expires_in 1.year, public: true
    render plain: qr_code, content_type: "image/svg+xml"
  rescue ArgumentError, URI::InvalidURIError
    head :bad_request
  end
end
