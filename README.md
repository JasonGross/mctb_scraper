# Unsong Web Serial Scraper for Kindle

I adapted a [Worm Web Serial scaper](https://github.com/rhelsing/worm_scraper) to make a ebook/kindle version of [Mastering the Core Teachings of the Buddha, by Daniel M. Ingram](https://www.mctb.org/mctb2/title-page/). You can now enjoy Mastering the Core Teachings of the Buddha on an e-reader!

![MCTB Cover](https://www.mctb.org/wp-content/uploads/2018/05/BookCover.jpg)

<!--## Download

Download the ebook or run the scraper yourself.

- [Generated .mobi](//jasongross.github.io/mctb_scraper/mctb.mobi)
- [Generated .epub](//jasongross.github.io/mctb_scraper/mctb.epub)
-->
## How to run:

1. Clone this project
2. Install dependencies

```command
gem install uri
gem install open-uri
gem install nokogiri
gem install parallel
gem install addressable
```

3. Run the script and output into html file

```command
ruby mctb_scraper.rb > mctb.html
```

4. Convert (requires Calibre CLI)

```command
ebook-convert mctb.html mctb.mobi --authors "Daniel M. Ingram" --title "Mastering the Core Teachings of the Buddha" --max-toc-links 500
```
