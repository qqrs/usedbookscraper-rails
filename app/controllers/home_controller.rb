require 'goodreads'

class HomeController < ApplicationController
  def index
  end

  def shelves
    #name = params[:name]
    #phone = params[:phone] 

    # TODO: need to escape this?
    @goodreads_user_id = params[:goodreads_user_id]

    gr = Goodreads.new(api_key: ENV["GOODREADS_KEY"]) 
    @shelves = gr.user(@goodreads_user_id).user_shelves

    # mock shelf names for testing
    #@shelves = (1..10).map{|n| Hashie::Mash.new({name: "shelf #{n}"}) }

  end

  def books
    goodreads_user_id = params[:goodreads_user_id]
    shelves = params[:shelves]

    gr = Goodreads.new(api_key: ENV["GOODREADS_KEY"]) 

    shelf = gr.shelf(goodreads_user_id, shelves[0])
    @book_titles = shelf.books.map{|b| b.book.title}
    @books = shelf.books.map do |b|
      Hashie::Mash.new(
        { 
          title:        b.book.title,
          author:       b.book.authors.author.name,
          isbn:         b.book.isbn,
          image_url:    b.book.image_url,
          owned:        b.owned,
          link:         b.link
        }
      )
    end


    @books_debug = shelf if Rails.env.development?  
  end
end
