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


  def editions
    @query = Query.find(params[:query_id])
    @query.books.clear
    params[:book_ids].each do |id|
      @query.books << Book.find(id)
    end
    @query.save

    @book_editions = []
    @query.books.each do |book| 
      alt_editions = xisbn_get_editions(book.isbn)
      alt_editions.select! {|e| e.lang == "eng" }
      # format includes BA book or BB hardcover or BC paperback
      alt_editions.select! {|e| e.form && 
                            e.form.any? {|f| %w'BA BB BC'.include?(f) } }     
      alt_editions.sort_by!{|e| e.year || "9999" }.reverse!
      #@book_editions << alt_editions

      alt_editions.each do |alt_ed|
        edition = book.editions.where(isbn: alt_ed.isbn.first).first_or_create(
            isbn:     alt_ed.isbn.first,
            title:    alt_ed.title,
            author:   alt_ed.author,
            language: alt_ed.lang,
            ed:       alt_ed.ed,
            published_date:   alt_ed.year
        )
      end
    end
  end

  def query
    @query = Query.find(params[:query_id])
    @query.query_books.each{|b| b.query_editions.clear }

    params[:edition_ids].each do |id|
      ed = Edition.find(id)
      qb = @query.query_books.find_by_book_id( ed.book.id )
      qb.editions << ed
    end
    debugger
    0
  end

  private
    # TODO: move this somewhere else?
    # TODO: handle timeout
    def xisbn_get_editions(isbn)
      require 'net/http'
      require 'json'
      require 'hashie'

      oclc_host = "xisbn.worldcat.org"
      oclc_request = "/webservices/xid/isbn/#{isbn}?method=getEditions&fl=form,lang,author,ed,year,isbn,title&format=json"

      http = Net::HTTP.new(oclc_host)
      http.read_timeout = 20
      http.open_timeout = 20
      response = http.get(oclc_request)

      return [] if response.code != '200'
      hash = JSON.parse response.body
      return [] if hash['stat'] != 'ok'

      return Hashie::Mash.new(hash).list
    end

end
