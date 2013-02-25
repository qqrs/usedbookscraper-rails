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
    @query = Query.new

    goodreads_user_id = params[:goodreads_user_id]
    shelves = params[:shelves]

    gr = Goodreads.new(api_key: ENV["GOODREADS_KEY"]) 
    @books = []

    shelves.each do |shelf_name|
      # TODO: goodreads api paginates -- this gets first 200 books per shelf
      shelf = gr.shelf(goodreads_user_id, shelf_name, per_page: '200')
      shelf.books.each do |b|
        book = Book.new( 
            title:  b.book.title, 
            author: b.book.authors.author.name,
            isbn:   b.book.isbn
        )

        if book.valid?
            book.save
            @books << book
        end

=begin
        @books << Hashie::Mash.new(
          { 
            title:        b.book.title,
            author:       b.book.authors.author.name,
            isbn:         b.book.isbn,
            image:        b.book.small_image_url,
            owned:        b.owned,
            link:         b.link
          }
        )
=end
      end

      @query.save
      #@books = @query.books

      @books_debug = shelf if Rails.env.development?
    end

    # TODO: enforce uniqueness in database
    #@books.uniq!{|b| b.isbn}

  end


  def query
      @query = Query.find(params[:query_id])
  end
end
