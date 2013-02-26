class QueryBook < ActiveRecord::Base
  attr_accessible :book_id, :query_id, :desirability

  belongs_to :query
  belongs_to :book
end
