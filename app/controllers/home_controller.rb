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
    @query.query_books.each{|b| b.query_editions.destroy_all }

    params[:edition_ids].each do |id|
      ed = Edition.find(id)
      qb = @query.query_books.find_by_book_id( ed.book.id )
      qb.editions << ed
    end

    @half_search = []
    @query.editions.each do |ed| 
      #@half_search << {isbn: ed.isbn, title: ed.book.title} 
      # TODO: all conditions
      listings = half_finditems(isbn: ed.isbn)
      listings.each do |listing|
        hl = HalfListing.where(half_item_id: listing[:half_item_id])
                          .first_or_initialize(
          half_item_id: listing[:half_item_id],
          price: listing[:price],
          comments: listing[:comments]
        )
        if hl.new_record?
          seller = HalfSeller.where(name: listing[:seller]).first_or_create(
            name: listing[:seller],
            feedback_count: listing[:feedback_count],
            feedback_rating: listing[:feedback_rating]
          )
          seller.half_listings << hl
          hl.save
        end
        ed.half_listings << hl
      end
      # find or create HalfSeller by name and link to listing
      @half_search += listings
     
    end
  end

  private
    # TODO: move these somewhere else?
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


    require 'net/http'
    require 'nokogiri'

    def half_finditems_request(params)
      host = "svcs.ebay.com"
      request = "/services/half/HalfFindingService/v1" \
        "?OPERATION-NAME=findHalfItems" \
        "&X-EBAY-SOA-SERVICE-NAME=HalfFindingService" \
        "&SERVICE-VERSION=1.0.0" \
        "&GLOBAL-ID=EBAY-US" \
        "&X-EBAY-SOA-SECURITY-APPNAME=#{ENV['HALF_APPNAME']}" \
        "&RESPONSE-DATA-FORMAT=XML" \
        "&REST-PAYLOAD" \
        "&productID=#{params[:isbn]}" \
        "&productID.@type=ISBN" \
        "&paginationInput.pageNumber=#{params[:page].to_s}" \
        "&itemFilter(0).name=Condition" \
        "&itemFilter(0).value=#{params[:condition]}"

      if params.has_key?(:maxprice)
        request << "&itemFilter(1).name=MaxPrice" \
                  "&itemFilter(1).value=#{'%.2f' % params[:maxprice].to_f}" \
                  "&itemFilter(1).paramName=Currency" \
                  "&itemFilter(1).paramValue=USD"
      end

      http = Net::HTTP.new(host)
      http.read_timeout = 20
      http.open_timeout = 20
      response = http.get(request)

      return [] if response.code != '200' # TODO: retry, throw exception?
      return response.body
    end


    MAX_PAGES = 20
    def half_finditems(params={})
      total_pages = nil
      total_entries = nil
      page = 1

      params[:isbn] ||= '0553212168'
      params[:condition] ||= 'Good'

      all_items = []

      for page in 1 .. MAX_PAGES do
        params[:page] = page

        body = half_finditems_request(params)
        doc = Nokogiri::XML(body)

        break if doc.css('ack').text == "Failure"     # TODO: try to resume or retry?

        total_pages ||= doc.css('totalPages').text.to_i
        total_entries ||= doc.css('totalEntries').text.to_i
        fail 'totalPages' if total_pages != doc.css('totalPages').text.to_i
        fail 'totalEntries' if total_entries != doc.css('totalEntries').text.to_i

        fail 'pageNumber' if page != doc.css('pageNumber').text.to_i

        items = doc.css('item').map do |item|
          { 
            half_item_id: item.css('itemID').text.to_i,
            price: item.css('price').text.to_f,
            seller: item.css('seller userID').text,
            feedback_count: item.css('seller feedbackScore').text.to_i,
            feedback_rating: item.css('seller positiveFeedbackPercent').text.to_f,
            comments: item.css('comments').text
          }
        end

        fail 'entriesPerPage' if doc.css('entriesPerPage').text.to_i != items.length
        break if items.length == 0

        all_items += items

      end

      fail 'total_entries' if total_entries and all_items.length != total_entries
      return all_items
    end
end
