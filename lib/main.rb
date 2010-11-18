require 'rubygems'
require 'hpricot'
require "stanfordparser"

#function to grab an entire file as a string
def get_file_as_string filename
  data = ''
  f = File.open(filename, "r")
  f.each_line do |line|
    data += line
  end
  return data
end

def lwr_words text
  text.downcase.scan(/[a-z]+/)
end

#read in file
data = "/Users/jameson/Projects/natural/doc/WSJ9_041_lite.txt"
puts "Reading in file...#{data}"
doc = Hpricot(get_file_as_string(data))

#grab the stuff in <text/>
corpus = ""
for text in doc.search("//text")
  corpus += text.inner_html
end

#parse sentences, ad <s/> wrapper and create word array
preproc = StanfordParser::DocumentPreprocessor.new
words = []
for sentence in preproc.getSentencesFromString(corpus)
  words += "<s><>#{sentence.join("<>")}<></s>".split("<>")
end

#create n-grams
bi_grams = Hash.new(0)
tri_grams = Hash.new(0)

num = words.length - 2
num.times {|i|
  bi = words[i] + ' ' + words[i+1]
  tri = bi + ' ' + words[i+2]
  bi_grams[bi] += 1
  tri_grams[tri] += 1
}
puts "bi-grams:"
bb = bi_grams.sort{|a,b| b[1] <=> a[1]}
(num / 10).times {|i|  puts "#{bb[i][0]} : #{bb[i][1]}"}