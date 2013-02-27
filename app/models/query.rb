class Query < ActiveRecord::Base
  attr_accessible :user_id

  has_many :query_books
  has_many :books, through: :query_books
  has_many :query_editions, through: :query_books
  has_many :editions, through: :query_editions
end
