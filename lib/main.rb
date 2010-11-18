require 'rubygems'
require 'hpricot'
require "stanfordparser"

#read in file
#filename = "/Users/jameson/Projects/natural/doc/WSJ9_041_lite.txt"
filename = "/Users/jameson/Projects/natural/doc/WSJ9_041.txt"
data = ""
f = File.open(filename, "r")
f.each_line do |line|
  data += line
end

#grab the stuff in <text/>
corpus = ""
doc = Hpricot(data)
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
uni_grams = Hash.new(0)
bi_grams = Hash.new(0)

num = words.length - 1
num.times {|i|
  uni = words[i]
  bi = uni + ' ' + words[i+1]
  uni_grams[uni] += 1
  bi_grams[bi] += 1
}

#write out top ten with probability in each case
puts "\nuni-grams:"
uu = uni_grams.sort{|a,b| b[1] <=> a[1]}
(num/10).times {|i|  puts "#{uu[i][0]} --> #{uu[i][1]} <> #{uu[i][1].to_f/num}"}

puts "\nbi-grams:"
bb = bi_grams.sort{|a,b| b[1] <=> a[1]}
(num/10).times {|i|
  bw = bb[i][0].split(" ")
  puts "#{bb[i][0]} --> #{bb[i][1]}, #{uni_grams[bw[0]]}, #{uni_grams[bw[1]]} <> #{(uni_grams[bw[0]].to_f/num)*(bb[i][1].to_f/num)}"
}
