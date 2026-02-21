class Rooms::CallStatusesController < ApplicationController
  def index
    room_ids = Current.user.rooms.pluck(:id)
    counts = CallTracker.counts_for_rooms(room_ids)

    render json: counts.transform_values { |count| { participant_count: count } }
  end
end
