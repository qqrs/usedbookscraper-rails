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

ActiveRecord::Schema.define(:version => 20130226165210) do

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
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "editions", ["book_id"], :name => "index_editions_on_book_id"
  add_index "editions", ["isbn"], :name => "index_editions_on_isbn", :unique => true

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

end
