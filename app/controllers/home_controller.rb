require 'goodreads'
require 'xisbn'
include XISBN
require 'googlebooks'

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
        book = Book.where(isbn: b.book.isbn).first_or_initialize(
            title:  b.book.title, 
            author: b.book.authors.author.name,
            isbn:   b.book.isbn
        )

        if book.valid?
          book.save if book.new_record?
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

      @books_debug = shelf if Rails.env.development?
    end

    # TODO: enforce uniqueness in database
    #@books.uniq!{|b| b.isbn}

  end


  def query
      @query = Query.find(params[:query_id])
      @query.books.clear
      params[:book_ids].each do |id|
        @query.books << Book.find(id)
      end
      @query.save

      #@isbns = @query.books.map{|b| xisbn(b.isbn) }

      @query.books.each do |book| 
        isbns = xisbn(book.isbn)
        isbns.each do |ed_isbn|
          edition = Edition.where(isbn: ed_isbn).first_or_initialize(
              isbn:   ed_isbn
          )

          if edition.new_record?
            search = GoogleBooks.search("isbn:#{ed_isbn}")
            unless search.nil? || search.first.nil?
              edition.title = search.first.title
              edition.author = search.first.authors
              edition.language = search.first.language
              edition.published_date = search.first.published_date
            end
          end

          if edition.valid?
            edition.save if edition.new_record?
            book.editions << edition
          end
        end

        book.save
      end
  end
end
