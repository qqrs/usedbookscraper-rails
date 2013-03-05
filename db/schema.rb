# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130304205723) do

  create_table "books", :force => true do |t|
    t.string   "isbn"
    t.string   "title"
    t.string   "author"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "books", ["isbn"], :name => "index_books_on_isbn", :unique => true

  create_table "editions", :force => true do |t|
    t.integer  "book_id"
    t.string   "isbn"
    t.string   "title"
    t.string   "author"
    t.string   "language"
    t.string   "published_date"
    t.string   "ed"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "editions", ["book_id"], :name => "index_editions_on_book_id"
  add_index "editions", ["isbn"], :name => "index_editions_on_isbn", :unique => true

  create_table "half_listings", :force => true do |t|
    t.integer  "edition_id"
    t.float    "price"
    t.integer  "half_item_id"
    t.integer  "half_seller_id"
    t.string   "comments"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "half_listings", ["edition_id"], :name => "index_half_listings_on_edition_id"
  add_index "half_listings", ["half_item_id"], :name => "index_half_listings_on_half_item_id"
  add_index "half_listings", ["half_seller_id"], :name => "index_half_listings_on_half_seller_id"

  create_table "half_sellers", :force => true do |t|
    t.string   "name"
    t.integer  "feedback_count"
    t.float    "feedback_rating"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "half_sellers", ["name"], :name => "index_half_sellers_on_name"

  create_table "queries", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "query_books", :force => true do |t|
    t.integer  "query_id"
    t.integer  "book_id"
    t.integer  "desirabilty"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "query_books", ["book_id"], :name => "index_query_books_on_book_id"
  add_index "query_books", ["query_id", "book_id"], :name => "index_query_books_on_query_id_and_book_id", :unique => true
  add_index "query_books", ["query_id"], :name => "index_query_books_on_query_id"

  create_table "query_editions", :force => true do |t|
    t.integer  "query_book_id"
    t.integer  "edition_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "query_editions", ["edition_id"], :name => "index_query_editions_on_edition_id"
  add_index "query_editions", ["query_book_id", "edition_id"], :name => "index_query_editions_on_query_book_id_and_edition_id", :unique => true
  add_index "query_editions", ["query_book_id"], :name => "index_query_editions_on_query_book_id"

end
