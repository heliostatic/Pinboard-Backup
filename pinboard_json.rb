require 'pry'
require "uri"
require 'yajl/http_stream'

class Bookmark
  require 'time'
  attr_reader :href, :title, :tags, :description
  
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
  
  HEAD = %Q{<!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="utf-8">
      <title>Bookmarks</title>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta name="description" content="">
      <meta name="author" content="">
  
      <!-- Le HTML5 shim, for IE6-8 support of HTML elements -->
      <!--[if lt IE 9]>
        <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
      <![endif]-->
  
      <!-- Le styles -->
      <link href="bootstrap/css/bootstrap.min.css" rel="stylesheet">
      <link href="bookmarks.css" rel="stylesheet">
  
     <script type="text/javascript">
  
     </script>
  
    </head>
    <body>
  }
  FOOTER = %Q{</section></div>
                  <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script>
                  <script type="text/javascript">
                    //$("h2").hover(function(){
                    //  $(this).children(".date").first().toggle()
                    //});
                  </script>
                </body></html>}
  
  def initialize(array_of_bookmarks, page_size, page_number, number_of_pages)
    @bookmarks = array_of_bookmarks
    @page_size = page_size
    @page_number = page_number
    @number_of_pages = number_of_pages
    build_page
  end
  
  def write
      File.open("#{@page_number}.html", 'w') do |f|
        f.write(@page)
      end
  end
  
  private
  def build_page
    @page = HEAD
    @page += %Q{<div class="container"><div class="page-header"><h1>Bookmark Backup: Page #{@page_number}</h1></div><section id="bookmarks">}
    @bookmarks.each do |b|
      @page += build_bookmark_row(b)
    end
    @page += navigation
    @page += FOOTER
  end
  
  def build_bookmark_row(bookmark)
    %Q{<article id="#{bookmark.hash}" class="bookmark row-fluid">
       <div class="span12">
         <h2><a href="#{bookmark.href}">#{bookmark.title}</a></h2>
         <div class="row-fluid">
           <div class="span1 date small">#{bookmark.date_added}</div>
           <div class="span6 offset1">#{bookmark.description}</div>
         </div>
         <div class="tags">#{bookmark.tags}</div>
       </div>
       </article>}
  end
  
  def navigation
    navbar = %Q{<div class="pagination pagination-centered"><ul>#{previous_page_link}}
    (previous_page(@page_number,2)..next_page(@page_number,2)).each do |p|
      navbar += %Q{<li class="#{"active disabled" if p == @page_number}"><a href="#{p}.html">#{p}</a></li>}
    end
    
    navbar += %Q{#{next_page_link}</div>}
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

# url = URI.parse("http://pinboard.in/export/format:json/")
# results = Yajl::HttpStream.get(url)
# pb = PinboardBackup.new(results)

pb = PinboardBackup.new("pinboard.json")
pb.generate_backup