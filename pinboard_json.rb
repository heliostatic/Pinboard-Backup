require "uri"
require 'open-uri'
require 'nokogiri'
require 'mechanize'
require 'highline/import'

class Bookmark
  require 'time'
  attr_reader :href, :title, :tags, :description, :hash
  
  def initialize(bookmark_hash)
  	@href = bookmark_hash["href"]
  	@title = bookmark_hash["description"]
  	@title = @href if @title.size == 0
  	@tags = bookmark_hash["tags"]
  	@description = bookmark_hash["extended"] 
  	@date_added = Time.parse(bookmark_hash["time"]) #2004-12-27T04:35:13Z
  	@hash = bookmark_hash["hash"]
  end
  
  def date_added
    @date_added.strftime("%A, %b %-d, %Y")
  end
  
  def to_s
    "#{@title} - #{@href}"
  end
end

class Page
require 'haml'
require 'tilt'
  
  def initialize(array_of_bookmarks, page_size, page_number, number_of_pages)
    @bookmarks = array_of_bookmarks
    @page_size = page_size
    @page_number = page_number
    @number_of_pages = number_of_pages
    @navigation = navigation
    @template = Tilt.new('page.haml')
    build_page
  end
  
  def write
      File.open("#{@page_number}.html", 'w') do |f|
        f.write(@page)
      end
  end
  
  private
  def build_page
    @page = @template.render(self, :bookmarks => @bookmarks, :page_number => @page_number, :navigation => @navigation)
  end
  
  def class_if_active(page)
    "active disabled" if page == @page_number
  end
  
  def navigation
    (previous_page(@page_number,2)..next_page(@page_number,2)).to_a
  end
  
  def previous_page(page_number,offset=1)
    new_page_number = page_number
    1.upto(offset) do |n|
      new_page_number = page_number - n unless page_number - n < 1
    end
    new_page_number
  end
  
  def next_page(page_number,offset=1)
    new_page_number = page_number
    1.upto(offset) do |n|
      new_page_number = page_number + n unless page_number + n > @number_of_pages
    end
    new_page_number
  end
  
  def previous_page_link
    if @page_number == 1
      %Q{<li class="disabled"><a href="#">Prev</a></li>}
    else
      %Q{<li><a href="#{previous_page(@page_number)}.html">Prev</a></li>}
    end
  end
  
  def next_page_link
    if @page_number == @number_of_pages
      %Q{<li class="disabled"><a href="#">Next</a></li>}
    else
      %Q{<li><a href="#{next_page(@page_number)}.html">Next</a></li>}
    end
  end
end

class PinboardBackup
require 'yajl'

  PAGE_SIZE = 100

  def initialize(bookmark_json_file)
    json = File.new(bookmark_json_file, 'r')
    parser = Yajl::Parser.new
    @hash = parser.parse(json)
    # @hash = parser.parse(bookmark_json_file)
    prepare_hash
  end
  
  def generate_backup
    page_num = 1
    bookmarks = []
    
    @hash.each_with_index do |b,i|
    
      bm = Bookmark.new(b)
      bookmarks << bm
    
      if i % PAGE_SIZE == 0 && i != 0 then
        p = Page.new(bookmarks, PAGE_SIZE, page_num, @number_of_pages)
        p.write
        page_num +=1 
        bookmarks = []
      end
    
      if i + 1 == @number_of_bookmarks then
        p = Page.new(bookmarks, PAGE_SIZE, page_num, @number_of_pages)
        p.write
      end
    
    end
    
  end
  
  private
  def prepare_hash
    @number_of_bookmarks = @hash.size  
    @number_of_pages =  ((@number_of_bookmarks + 0.00) / PAGE_SIZE).ceil    
  end
end


puts "Pinboard Backup 0.1"

t = Time.now
todays_backup = "pinboard_#{t.day}.json"
user = {}

if File.exist? todays_backup then
  puts "File exists, generating backup"
else
  user[:username] = ask("Enter your username:  ")
  user[:password] = ask("Enter your password:  ") { |q| q.echo = "*" }
    
  # Mechanize agent
  agent = Mechanize.new
  
  # Logging in to pinboard
  page = agent.get('http://pinboard.in')
  login_form = page.form('login')
  login_form.username = user[:username]
  login_form.password = user[:password]
  page = agent.submit(login_form)
  
  puts "Logged in, getting backup file."
  
  agent.download("http://pinboard.in/export/format:json/", todays_backup)
end

puts "Generating pages..."

pb = PinboardBackup.new(todays_backup)
pb.generate_backup

puts "Pages generated, press enter to open 1.html"
gets
`open 1.html`