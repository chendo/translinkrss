#
# translinkRSS v0.01
# by chendo
# 
# This little ramaze page gets the next train and bus times from Translink (Brisbane) from certain areas. Ugly hack at the moment.
# You get the URLs by doing a search for what you usually want, then taking out the JourneyTime* parts.
# Requires ramaze and hpricot
# 


require 'rubygems'
require 'hpricot'
require 'timeout'
require 'open-uri'
require 'ramaze'

class MainController < Ramaze::Controller
  helper :cache

  def get_time_string
    Time.now.strftime("&JourneyTimeHours=%I&JourneyTimeMinutes=%M&JourneyTimeAmPm=%p&Date=%d%/%%d/%Y") % (Time.now.mon)
  end
  
  def bus
    urls = Hash.new

    time_string = get_time_string

    urls[:inbound_bus] = "http://jp.translink.com.au/TransLinkExactEnquiry.asp?ToLoc=Queen+St+Mall~~;Queen+St+Mall;[502494:6961547]~~POINT~~ONS&FromLoc=Lang+Parade,+Auchenflower~~Lang+Parade;Auchenflower;[500193:6961036]~~POINT~~OAM&Vehicle=Bus&Advanced=true&WalkSpeed=67&WalkDistance=1000&Priority=504;0&IsAfter=AFromRailStation=&FromLandmarkType=&ToRailStation=&ToLandmarkType=&PageFrom=&UseTranslink=true"
    urls[:outbound_bus] = "http://jp.translink.com.au/TransLinkExactEnquiry.asp?Advanced=true&PageFrom=&Vehicle=&WalkSpeed=67&WalkDistance=1000&Priority=504%3B-1&UseTranslink=true&IsAfter=A&FromRailStation=&FromLandmarkType=&ToRailStation=&ToLandmarkType=&FromLoc=Lang+Parade%2C+Auchenflower~~Lang+Parade%3BAuchenflower%3B[500193%3A6961036]~~POINT&ToLoc=Indooroopilly+C~~%3BIndooroopilly+C%3BIndooroopilly+C~~NODE&findjourney.x=71&findjourney.y=13"

    times = Hash.new

    urls.each do |k, v|
      Timeout::timeout(3) do
        doc = Hpricot(open(v + time_string))
        out = (doc/'td.JourneyDetails b').map{|c| c.inner_html.match(/[\d:apm]{6,8}/) }.compact.map { |c| c.to_s }
        routes = (doc/'td.JourneyDetails').map{|c| c.inner_html.match(/Route\s+([\dA-Z]{2,5})/) }.compact.map{ |d| d.to_s }
    
        routes.map!{ |d| d.match(/([\dA-Z]{2,5})/)[1] }
        s = true
        t = out.reject { s = !s }
        times[k.to_sym] = []
        i = 0
        t.zip(routes).each do |a, b|
          i += 1
          if i > 3
            break
          end
          times[k.to_sym] << "#{a} (#{b})"
        end
        
      end
    end
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>


    <rss version=\"2.0\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">
      <channel>
        <title>
     Bus Times
    </title>        
        <link>http://reddit.com/</link>
        <description></description>
    <item>
    <title>To City: #{times[:inbound_bus].join ", "}</title>
    </item>
    <item>
    <title>To Taringa: #{times[:outbound_bus].join ", "}</title>
    </item>
    </channel></rss>"
  end
  
  def train
    urls = Hash.new

    time_string = get_time_string

    urls[:inbound_train] = "http://jp.translink.com.au/TransLinkExactEnquiry.asp?ToLoc=Central+Railway+Station~~;Central+Railway+Station;Central+Railway+Station~~LOCATION&FromLoc=Milton+Rly+Station~~+;Milton+Rly+Station;Milton+Rly+Station~~NODE&Vehicle=Train&Advanced=true&WalkSpeed=67&WalkDistance=1000&Priority=504;-1&IsAfter=AFromRailStation=&FromLandmarkType=&ToRailStation=&ToLandmarkType=&PageFrom=&UseTranslink=true"
    urls[:outbound_train] = "http://jp.translink.com.au/TransLinkExactEnquiry.asp?Advanced=true&PageFrom=&Vehicle=Train&WalkSpeed=67&WalkDistance=1000&Priority=504%3B-1&UseTranslink=true&IsAfter=A&FromRailStation=&FromLandmarkType=&ToRailStation=&ToLandmarkType=&FromLoc=Milton+Rly+Station~~+%3BMilton+Rly+Station%3BMilton+Rly+Station~~NODE&ToLoc=Indooroopilly+Railway+Station~~%3BIndooroopilly+Railway+Station%3BIndooroopilly+Railway+Station~~LOCATION&findjourney.x=56&findjourney.y=13"
  

    times = Hash.new

    urls.each do |k, v|
      Timeout::timeout(3) do
        doc = Hpricot(open(v + time_string))
        out = (doc/'td.JourneyDetails b').map{|c| c.inner_html.match(/[\d:apm]{6,8}/) }.compact.map { |c| c.to_s }
        routes = (doc/'td.JourneyDetails').map{|c| c.inner_html.match(/Route\s+([\dA-Z]{2,5})/) }.compact.map{ |d| d.to_s }
    
        routes.map!{ |d| d.match(/([\dA-Z]{2,5})/)[1] }
        s = true
        t = out.reject { s = !s }
        times[k.to_sym] = []
        i = 0
        t.zip(routes).each do |a, b|
          i += 1
          if i > 3
            break
          end
          times[k.to_sym] << "#{a} (#{b})"
        end
        
      end
    end
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>


    <rss version=\"2.0\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">
      <channel>
        <title>
     Train Times
    </title>        
        <link>http://reddit.com/</link>
        <description></description>
    <item>
    <title>Next train to Central: #{times[:inbound_train].join ", "}</title>
    </item>
    <item>
    <title>Next train to Indro: #{times[:outbound_train].join ", "}</title>
    </item>
    </channel></rss>"
  end
  
  cache :bus, :ttl => 120
  cache :train, :ttl => 120
  
end

