class QueryEdition < ActiveRecord::Base
  attr_accessible :edition_id, :query_book_id, :query_id

  belongs_to :query
  belongs_to :query_book
  belongs_to :edition
end
