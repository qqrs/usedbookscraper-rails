require 'goodreads'
require 'hashie'

class HomeController < ApplicationController
  def index
  end

  def shelves
    # TODO: need to escape this?
    @goodreads_user_id = params[:goodreads_user_id]

    gr = Goodreads.new(api_key: ENV["GOODREADS_KEY"]) 
    @shelves = gr.user(@goodreads_user_id).user_shelves
  end

  def books
    goodreads_user_id = params[:goodreads_user_id]
    shelves = params[:shelves]

    gr = Goodreads.new(api_key: ENV["GOODREADS_KEY"]) 
    @books = []

    shelves.each do |shelf_name|
      # TODO: goodreads api is paginated -- retrieve first 200 books per shelf
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
      end

      @books_debug = shelf if Rails.env.development?
    end
  end

  def editions
    @books = params[:book_ids].map{|id| Book.find(id)}
    @book_editions = []
    @books.each do |book|
      # language English and format BA book or BB hardcover or BC paperback
      alt_editions = xisbn_get_editions(book.isbn)
        .select {|e| e.lang == "eng" && 
          e.form && e.form.any? {|f| %w'BA BB BC'.include?(f) } }
        .sort_by{|e| e.year || "9999" }.reverse

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
    max_price = 3.00
    #conditions = [ 'Acceptable', 'Good', 'VeryGood', 'LikeNew', 'BrandNew' ] 
    conditions = [ 'Good', 'VeryGood', 'LikeNew', 'BrandNew' ] 

    # get editions selected by user for Half.com search
    editions = params[:edition_ids].map{|id| Edition.find(id)}

    @debug_half_search = []
    @seller_listings = []
    editions.each do |ed| 
      # get all listings for this edition
      listings = conditions.map do |cond|
        half_finditems(isbn: ed.isbn, condition: cond, maxprice: max_price)
      end.flatten(1)

      # construct list of sellers, with attributes and listings for each seller
      @seller_listings = listings.reduce(@seller_listings) do |sellers, listing|
        # find seller -- construct seller hash if it does not yet exist
        seller = sellers.find { |s| s[:name] == listing[:seller] }
        if !seller
          seller = Hashie::Mash.new(
            listing.slice(:feedback_count, :feedback_rating))
          seller.name = listing[:seller]
          seller.listings = []
          sellers << seller
        end

        # construct listing hash and append to seller listings
        li = Hashie::Mash.new(
          listing.slice(:half_item_url, :price, :condition, :comments))
        li.edition = ed
        seller.listings << li

        sellers
      end

      @debug_half_search += listings
    end

    @seller_listings = @seller_listings.select!{|s| s.listings.length >= 2}
                            .sort_by{|s| s.listings.length}.reverse
    #@seller_listings.each do |s|
      #s.listings.uniq! {|li| li.edition.book }
      #s.books = s.listings.group_by{ |li| li.edition.book }
    #end


=begin
    seller_listings = {}
    editions.each do |book|
      logger.debug book.title

      # TODO: filter to a single edition of a book per seller
      #listings = half_listings.where("price <= ?", max_price)
                        #.order("price").group("half_seller_id").each do |li|
      listings = half_listings.each do |li|
        seller_listings[li[:seller]] ||= [] 
        seller_listings[li[:seller]] << li
      end
    end
    @seller_listings = seller_listings.select{|key,val| val.length >= 2}
                                  .sort_by{|key,val| val.length}.reverse
=end

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
            half_item_url: item.css('itemURL').text,
            price: item.css('price').text.to_f,
            seller: item.css('seller userID').text,
            feedback_count: item.css('seller feedbackScore').text.to_i,
            feedback_rating: item.css('seller positiveFeedbackPercent').text.to_f,
            comments: item.css('comments').text,
            condition: params[:condition].titleize
          }
        end

        fail 'entriesPerPage' if doc.css('entriesPerPage').text.to_i != items.length
        break if items.length == 0

        all_items += items

      end

      fail "total_entries\n" + params.to_yaml if total_entries and all_items.length != total_entries
      return all_items
    end

=begin
    MAX_PAGES = 20
    def half_finditems(params={})

      all_items = []
      all_total_entries = 0

      conditions = [ 'Good', 'VeryGood', 'LikeNew', 'BrandNew' ] 
      #conditions = [ 'Good' ]
      conditions.each do |cond|
        params[:condition] = cond
        total_pages = nil
        total_entries = nil

        for page in 1 .. MAX_PAGES do
            params[:page] = page

            body = half_finditems_request(params)
            doc = Nokogiri::XML(body)

            break if doc.css('ack').text == "Failure"     # TODO: try to resume or retry?

            total_pages = doc.css('totalPages').text.to_i
            total_entries = doc.css('totalEntries').text.to_i
            raise 'totalPages' if total_pages != doc.css('totalPages').text.to_i
            raise 'totalEntries' if total_entries != doc.css('totalEntries').text.to_i

            raise 'pageNumber' if page != doc.css('pageNumber').text.to_i

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

            raise 'entriesPerPage' if doc.css('entriesPerPage').text.to_i != items.length
            break if items.length == 0

            all_items += items
            all_total_entries += total_entries
            logger.debug "%d %d %d" % [total_entries, all_total_entries, all_items.length]

        end
      end

      raise RuntimeError, 'total_entries' + params.to_yaml if all_total_entries and all_items.length != all_total_entries
      return all_items
    end
=end
end
