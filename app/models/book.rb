class Book < ActiveRecord::Base
  attr_accessible :author, :isbn, :title

  validates :isbn, presence: true, uniqueness: true
  validates :author, presence: true
  validates :title, presence: true

  has_many :editions
  has_many :half_listings, through: :editions
end
