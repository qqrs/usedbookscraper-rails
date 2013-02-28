require 'vacuum'
require 'nokogiri'
require 'active_support/core_ext'

def amazon_isbn_response(isbn)
    @req = Vacuum.new
    @req.configure(key:   ENV['AMAZON_AWSKEY'])
    @req.configure(secret: ENV['AMAZON_SECRETKEY'])
    @req.configure(tag:    ENV['AMAZON_ASSOCKEY'])

    @params = { 'Operation'   => 'ItemLookup',
            'SearchIndex' => 'Books',
            #'ResponseGroup' => 'ItemAttributes,OfferListings',
            'ResponseGroup' => 'ItemAttributes,AlternateVersions,OfferListings',
            'MerchantId' => 'Amazon',
            'Condition' => 'New',
            'IdType' => 'ISBN',
            #'ItemId' => '0684813785'
            'ItemId' => isbn
    }

    @response = @req.get(query: @params)

    #@doc = Nokogiri::XML(@response.body)
    #puts @doc.css("Price Amount").children.text

    #@my_hash = Hash.from_xml(@response.body)
    #puts @my_hash.to_yaml
    #@my_hash['ItemLookupResponse']['Items']['Item']['Offers']['Offer']['OfferListing']['Price']['Amount']
end

def amazon_asin_response(asin)
    @req = Vacuum.new
    @req.configure(key:   ENV['AMAZON_AWSKEY'])
    @req.configure(secret: ENV['AMAZON_SECRETKEY'])
    @req.configure(tag:    ENV['AMAZON_ASSOCKEY'])

    @params = { 'Operation'   => 'ItemLookup',
            'ResponseGroup' => 'ItemAttributes,OfferFull',
            'MerchantId' => 'Amazon',
            'Condition' => 'New',
            'IdType' => 'ASIN',
            'ItemId' => asin
    }

    @response = @req.get(query: @params)
end

def amazon_isbn_price(isbn)
    @response = amazon_isbn_response(isbn)
    @doc = Nokogiri::XML(@response.body)

    @price_element = @doc.css("Price Amount")
    #puts Hash.from_xml(@response.body).to_yaml

    if !@price_element.empty?
        return @price_element.children.text 
    else
        asins = @doc.css("AlternateVersion").select{|v| v.css("Binding").text == "Paperback"}.map{|v| v.css("ASIN").text}
        asins.each do |asin| 
            @response = amazon_asin_response(asin)
            sleep(1)
            #puts Hash.from_xml(@response.body).to_yaml
            @doc = Nokogiri::XML(@response.body)
            @price_element = @doc.css("Price Amount")
            if !@price_element.empty?
                return @price_element.children.text 
            end
        end
    end
    return "not found"
end

def amazon_isbn_yaml(isbn)
    @response = amazon_isbn_response(isbn)
    @my_hash = Hash.from_xml(@response.body)
    puts @my_hash.to_yaml
end


@req = Vacuum.new
@req.configure(key:   ENV['AMAZON_AWSKEY'])
@req.configure(secret: ENV['AMAZON_SECRETKEY'])
@req.configure(tag:    ENV['AMAZON_ASSOCKEY'])

@params = { 'Operation'   => 'ItemLookup',
        'SearchIndex' => 'Books',
        #'ResponseGroup' => 'ItemAttributes,OfferListings',
        'ResponseGroup' => 'ItemAttributes,AlternateVersions,OfferListings',

        'MerchantId' => 'Amazon',
        'Condition' => 'New',
        'IdType' => 'ISBN',
        'ItemId' => '0684813785'
}

@response = @req.get(query: @params)

    #@doc = Nokogiri::XML(@response.body)
    #puts @doc.css("Price Amount").children.text

    #@my_hash = Hash.from_xml(@response.body)
    #puts @my_hash.to_yaml
    #@my_hash['ItemLookupResponse']['Items']['Item']['Offers']['Offer']['OfferListing']['Price']['Amount']
