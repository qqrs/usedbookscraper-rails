            #if maxprice != None:
                #maxprice_str = '%.2f' % maxprice
                #url = url + \
                    #'&itemFilter(1).name=MaxPrice' \
                    #'&itemFilter(1).value=' + maxprice_str + \
                    #'&itemFilter(1).paramName=Currency' \
                    #'&itemFilter(1).paramValue=USD'


require 'net/http'
#require 'json'
#require 'hashie'
require 'nokogiri'
#require 'active_support/core_ext'
#require 'debugger'

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


MAX_PAGE = 20
def half_finditems(params={})
  total_pages = nil
  total_entries = nil
  page = 1

  params[:isbn] ||= '0553212168'
  params[:condition] ||= 'Good'

  all_items = []

  for page in 1 .. MAX_PAGE do
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
        price: item.css('price').text.to_f,
        seller: item.css('seller userID').text,
      }
    end

    fail 'entriesPerPage' if doc.css('entriesPerPage').text.to_i != items.length
    break if items.length == 0

    all_items += items

  end

  fail 'total_entries' if total_entries and all_items.length != total_entries
  return all_items
end
