class Account < ApplicationRecord
  include Joinable

  has_one_attached :logo
  has_many :exports, dependent: :destroy
  has_many :users

  has_json :settings, restrict_room_creation_to_administrators: false, anonymous_confessions_enabled: false
end
