#!/bin/bash

ruby mctb_scraper.rb > mctb2.html.tmp || exit $?
mv -f mctb2.html.tmp mctb2.html
ebook-convert mctb2.html mctb2.mobi --authors "Daniel M. Ingram" --title "Mastering the Core Teachings of the Buddha" --max-toc-links 500 || exit $?
