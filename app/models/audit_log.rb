class AuditLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :action, :resource_type, presence: true

  scope :recent, -> { order(created_at: :desc).limit(100) }
  scope :for_resource, ->(resource) { resource ? where(resource_type: resource.class.name, resource_id: resource.id) : none }
end
