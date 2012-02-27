require 'yajl'
require 'pry'

PAGE_SIZE = 100

class Bookmark
  attr_reader :href, :title, :tags, :description
  
  def initialize(bookmark_hash)
  	@href = bookmark_hash["href"]
  	@title = bookmark_hash["description"]
  	@tags = bookmark_hash["tags"]
  	@description = bookmark_hash["extended"] 
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
      <link href="bootstrap.min.css" rel="stylesheet">
  
     <script type="text/javascript">
  
     </script>
  
    </head>
    <body>
    <section id="bookmarks">
  }
  FOOTER = %Q{</section></body></html>}
  
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
    @bookmarks.each do |b|
      @page += build_bookmark_row(b)
    end
    @page += navigation
    @page += FOOTER
  end
  
  def build_bookmark_row(bookmark)
    %Q{<div class="row"><div class="span7 offset1"><a href="#{bookmark.href}">#{bookmark.title}</a></div></div>}
  end
  
  def navigation
    navbar = %Q{<div class="pagination pagination-centered"><ul>#{previous_page_link}}
    
    (@page_number-2..@page_number+2).each do |p|
      navbar += %Q{<li class="#{"active disabled" if p == @page_number}"><a href="#{p}.html">#{p}</a></li>}
    end
    
    navbar += %Q{<li><a href="#{@page_number + 1}.html">Next</a></li></ul></div>}
  end
  
  def previous_page(page_number)
    page_number - 1
  end
  
  def next_page(page_number)
    page_number + 1
  end
  
  def previous_page_link
    if @page_number == 1
      %Q{<li class="disabled"><a href="#">Prev</a></li>}
    else
      %Q{<li><a href="#{previous_page(@page_number)}.html">Prev</a></li>}
    end
  end
  
  def next_page_link
    
  end
end

json = File.new('pinboard.json', 'r')
parser = Yajl::Parser.new
hash = parser.parse(json)

number_of_bookmarks = hash.size
number_of_pages =  number_of_bookmarks / PAGE_SIZE
page_num = 1
bookmarks = []

hash.each_with_index do |b,i|
  
  bm = Bookmark.new(b)
  bookmarks << bm
      
  if i % 100 == 0 then
    p = Page.new(bookmarks, PAGE_SIZE, page_num, number_of_pages)
    p.write
    page_num +=1 
    bookmarks = []
  end

end