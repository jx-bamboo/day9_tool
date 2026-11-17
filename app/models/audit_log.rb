class AuditLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  scope :recent, -> { order(created_at: :desc) }

  validates :action, presence: true
end
