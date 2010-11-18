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

puts "There are #{words.length} words in the corpus"
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

#write out top 5000 with probabilities to txt files
uni_txt = "uni_gram, gram_freq, prob\n"
uu = uni_grams.sort{|a,b| b[1] <=> a[1]}
1000.times {|i|
  uni_txt += "\"#{uu[i][0]}\",#{uu[i][1]}\n"
}
File.open("/Users/jameson/Projects/natural/doc/uni-grams.txt", 'w') {|f| f.write(uni_txt) }

bi_txt = "bi_gram,gram_freq,w1_freq,w2_freq,prob\n"
bb = bi_grams.sort{|a,b| b[1] <=> a[1]}
1000.times {|i|
  bw = bb[i][0].split(" ")
  bi_txt += "\"#{bb[i][0]}\",#{bb[i][1]},#{uni_grams[bw[0]]},#{uni_grams[bw[1]]}\n"
  break if bb[i][1] == 1;
}
File.open("/Users/jameson/Projects/natural/doc/bi-grams.txt", 'w') {|f| f.write(bi_txt) }

#output for part 3 of hmwk
for sentence in "<s> Bristol-Myers agreed to merge with Sun . </s>~<s> Bristol-Myers and Sun agreed to merge . </s>".split("~")
  words = sentence.split(" ")
  puts "U: #{uni_grams.length}; B: #{bi_grams.length}"
  (words.length - 1).times {|i|
    bg = "#{words[i]} #{words[i+1]}"
    puts "#{bg} #{bi_grams[bg]} #{uni_grams[words[i]]} #{uni_grams[words[i+1]]}"
  }
end
puts "All Done!"