# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'uri'
require 'parallel'
require 'addressable/uri'

def URI.variants_of(url)
  yield url
  if url.to_s.start_with?("//")
    url = "https:" + url
    yield url
  end
  unless url.ascii_only?
    url = Addressable::URI.escape url
    yield url
  end
end

def local_url_of(folder, url)
  folder + '/' + url.gsub(/[^0-9A-Za-z.\-]/, '_')
end

def URI.open_cached(url, mode='r')
  Dir.mkdir('cache') unless File.exists?('cache')
  cache_name = local_url_of('cache', url)
  if not File.exists?(cache_name) then
    url = URI.variants_of(url).to_a.last
    Uri.open(url, 'rb') do |u|
      contents = u.read()
      File.open(cache_name + '.tmp', 'wb') { |f| f.write(contents) }
    end
    File.rename(cache_name + '.tmp', cache_name)
  end
  File.open(cache_name, mode)
end

def download_image(url)
  Dir.mkdir('media') unless File.exists?('media')
  image_name = local_url_of('media', url)
  contents = URI.open_cached(url, 'rb').read()
  File.open(image_name, 'wb') { |f| f.write(contents) }
  image_name
end

toc_page = Nokogiri::HTML(URI.open_cached('https://www.mctb.org/mctb2/table-of-contents/')).css('.page-list')

chapters = Parallel.map_with_index(toc_page.css('a'), :in_threads => 8) do |link, ind|
  index = ind # - 1
  url = link['href']
  doc = Nokogiri::HTML(URI.open_cached(url))
  chapter_title = doc.css('div.headline h1').first

  #modify chapter to have link
  chapter_title_plain = chapter_title.content
  $stderr.puts chapter_title_plain
  chapter_content = doc.css('section.page-section').first
  #clean
  imgs = chapter_content.css('img').map { |img| img.attr('src') }

  [chapter_content.css('p').first, # the forward-back link at the top
   chapter_content.css('div.sharedaddy').first, # sharing
   chapter_content.css('div.sharedaddy ~ p').last # forward-back link at the bottom
  ].each do |to_remove|
    chapter_content = chapter_content.to_s.gsub(to_remove.to_s,"")
  end

  imgs.each do |img_url|
    $stderr.puts img_url
    img = download_image(img_url)
    URI.variants_of(img_url) do |orig_img_url|
      chapter_content = chapter_content.to_s.gsub("\"#{orig_img_url}\"", "\"#{img}\"")
      chapter_content = chapter_content.to_s.gsub("'#{orig_img_url}'", "'#{img}'")
    end
  end

  #write
  {"chapter_tite_plain" => chapter_title_plain,
   "index" => index.to_s,
   "url" => url,
   "depth" => url.count("/"),
   "body" => chapter_content, # "<h1 id=\"chap#{index.to_s}\">#{chapter_title_plain}</h1>" + chapter_content
   "toc" => "<a href=\"#chap#{index.to_s}\">#{chapter_title_plain}</a><br>"}
end.select {|chapter| chapter}

@toc = "<h1>Table of Contents</h1>"
@book_body = ""

max_depth = chapters.map { |chapter| chapter["depth"] }.max
max_h_depth = 3 # max depth for h
prev_depth = 0

chapters.each do |chapter|
  depth = [1, chapter["depth"] - max_depth + max_h_depth].max
  while prev_depth < depth do
    @toc << "<ul style=\"list-style: none;\">"
    prev_depth += 1
  end
  while depth < prev_depth do
    @toc << "</ul>"
    prev_depth -= 1
  end
  index = chapter["index"]
  chapter_title_plain = chapter["chapter_title_plain"]
  @book_body << "<h#{depth} id=\"chap#{index}\"\" class=\"chapter\">#{chapter_title_plain}</h#{depth}>" + chapter["body"]
  @toc << "<li style=\"list-style: none;\">" + chapter["toc"] + "</li>"
  prev_depth = depth
end
while 0 < prev_depth do
  @toc << "</ul>"
  prev_depth -= 1
end

chapters.each do |chapter|
  index = chapter["index"]
  URI.variants_of(chapter["url"]) do |url|
    @book_body.gsub! "'#{url}'", "\"#chap#{index}\""
    @book_body.gsub! "\"#{url}\"", "\"#chap#{index}\""
  end
end

$stderr.puts "Writing Book..."

puts @toc
puts @book_body
