class Rooms::LivekitTokensController < ApplicationController
  include RoomScoped

  def show
    service = LivekitTokenService.new(user: Current.user, room: @room)

    render json: {
      token: service.generate_token,
      url: service.url,
      room_name: service.room_name,
      identity: "user_#{Current.user.id}",
      user_name: Current.user.name
    }
  end
end
