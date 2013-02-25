class Query < ActiveRecord::Base
  attr_accessible :user_id

  has_many :query_books
  has_many :books, through: :query_books
end
