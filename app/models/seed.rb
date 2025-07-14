class Seed < ApplicationRecord
  has_one_attached :file

  enum status: { pending: 0, processing: 1, completed:  2}, _default: :pending
  enum quality: { good: 0, bad: 1, unknown: 2 }
end
