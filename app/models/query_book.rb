class QueryBook < ActiveRecord::Base
  attr_accessible :book_id, :query_id, :desirability

  belongs_to :query
  belongs_to :book

  has_many :query_editions
  has_many :editions, through: :query_editions
end
