class Store < ActiveRecord::Base
  validates_presence_of :store_id, :city, :address, :lat, :long
  
  # this should only need to be run once, or as ABC stores open
  def self.get_stores
    agent = Mechanize.new
    # ignore SSL (requests will fail otherwise)
    agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    stores = []
    i = 0
    
    while true
      base_url = "https://www.abc.virginia.gov/coveo/rest/v2/?sitecoreItemUri=sitecore%3A%2F%2Fpubweb%2F%7B712668CA-41D0-461E-B27D-4D8E1D35FFD0%7D%3Flang%3Den%26ver%3D6&siteName=website"
      q = "aq=(((%40fz95xpath79869%20%3D%3D%20712668ca41d0461eb27d4d8e1d35ffd0)%20(%40ftemplateid79869%20%3D%3D%20a1a81c71-eb25-4bcf-b968-6611212a840b)))%20(%40syssource%3D%3D(%22Coveo_pubweb_index%20-%20prod%22)%20NOT%20%40ftemplateid79869%3D%3D(%22adb6ca4f-03ef-4f47-b9ac-9ce2ba53ff97%22%2C%22fe5dd826-48c6-436d-b87a-7c4210c7413b%22)%20)%20(%24qf(function%3A'dist(%40flatitude79869%2C%40flongitude79869%2C37.540725%2C-77.43604800000003)'%2C%20fieldName%3A%20%40fdistance79869))&cq=(%40fz95xlanguage79869%3D%3D%22en%22%20%40fz95xlatestversion79869%3D%3D%221%22)&searchHub=Stores&language=en&partialMatch=true&partialMatchKeywords=4&partialMatchThreshold=50%25&firstResult=#{i * 100}&numberOfResults=100&excerptLength=200&enableDidYouMean=true&sortCriteria=%40fdistance79869%20ascending&queryFunctions=%5B%5D&rankingFunctions=%5B%5D&groupBy=%5B%5D&retrieveFirstSentences=true&timezone=America%2FNew_York&disableQuerySyntax=false&enableDuplicateFiltering=false&enableCollaborativeRating=false&debug=false"
      
      response = agent.post(base_url + "&" + q, {})
      
      hash = JSON.parse(response.body)
      
      # only check total pages the first time
      if i == 0
        total_results = hash["totalCount"]
      
        pages = (total_results/100.0).ceil
      end
      
      stores << hash["results"].map { |r| { :store_id => r["title"], :city => r["raw"]["fcity79869"], :address => r["raw"]["fpagez32xtitle79869"], :lat => r["raw"]["flatitude79869"], :long => r["raw"]["flongitude79869"] } }
      
      i += 1
      
      break if i == pages || i > 9 # use 9 as a failsafe for now
    end
    stores.flatten!
    
    stores.each do |store|
      Store.where(:store_id => store[:store_id], :city => store[:city], :address => store[:address], :lat => store[:lat], :long => store[:long]).first_or_create
    end
  end
  
  def get_data_single(product_id)
    agent = Mechanize.new
    # ignore SSL (requests will fail otherwise)
    agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    url = "https://www.abc.virginia.gov/webapi/inventory/mystore?storeNumbers=#{self.store_id}&productCodes=#{product_id}"

    response = agent.get(url)
    
    raw = response.body
    
    hash = Hash.from_xml(raw)
    
    return hash["MyStoreInventoryResponseModel"]["products"]["products"]["storeInfo"]
  end
  
  def get_data_multiple(product_id)
    puts "Getting inventory info for store #{self.store_id}"
    agent = Mechanize.new
    # ignore SSL (requests will fail otherwise)
    agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    url = "https://www.abc.virginia.gov/webapi/inventory/storeNearby?storeNumber=#{self.store_id}&productCode=#{product_id}&mileRadius=999&storeCount=5"
    
    response = agent.get(url)
    
    raw = response.body
    
    hash = Hash.from_xml(raw)
    
    return hash
  end
end
