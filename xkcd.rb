#!/usr/bin/ruby
#
# Generate a screensaver on your nook with the contents of the current XKCD RSS feed
# http://xkcd.com/rss.xml
#
# Requirements:
#  * Hpricot
# Optional:
#  * RMagick
#

require 'rubygems'
require 'open-uri'
require 'hpricot'

ss_path = "/Volumes/nook/my screensavers"
xk_ss_path = ss_path + "/xkcd"
rss_path = "http://xkcd.com/rss.xml"

# Verify the Nook is mounted and we can write to the screensavers directory
throw "Nook not mounted or My Screensaver's directory not available" unless File.exists?(ss_path) and File.directory?(ss_path) and File.writable?(ss_path)

# Empty the directory if it exists, otherwise create it
if File.exists?(xk_ss_path)
  d = Dir.new xk_ss_path
  d.each do |f|
    File.delete(xk_ss_path + "/" + f) unless f == "." or f == ".."
  end
  d = nil
else
  Dir.mkdir xk_ss_path
end

# Grab the RSS feed and pass it in to hpricot
rss = open(rss_path) { |f| Hpricot(f) }

# Parse the feed and pull down the appropriate images into our screensaver directory
lib = require 'RMagick'
rss.search("rss channel item description").each do |description|
  # Convert the description into a document and feed it to Hpricot
  doc = Hpricot(description.inner_html.gsub("&lt;", "<").gsub("&gt;", ">"))
  img = doc.root.attributes["src"]
  xk_img_path = xk_ss_path + "/" + img.match(/\/([a-zA-Z0-9_]*\.png$)/)[1]
  
  puts "Downloading #{xk_img_path}"
  
  # Snag the file and write it to the nook
  f = File.new(xk_img_path, "w")
  open(img) { |bin| f.write bin.read }
  f.close
  
  # Use Rmagick to rotate the image to fill the most space
  if lib
    xk_img = Magick::ImageList.new(xk_img_path)
    if xk_img.columns > xk_img.rows
      puts "Rotating #{xk_img_path}"
      xk_img = xk_img.rotate(90) 
    end
    #xk_img = xk_img.quantize(256, Magick::GRAYColorspace) # Grayscale the image?
    xk_img.write(xk_img_path)
    xk_img = nil
  end
  
end