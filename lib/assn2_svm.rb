require 'rubygems'
base = "/Users/jameson/Projects/natural"
dir = "#{base}/movie-reviews"
Dir.chdir(dir)

#functions
def get_word(tword)
  tmp = tword.split("/")
  pos = tmp.pop
  return [tmp.join("/"),pos]
end

def get_words(corpus)
  tagged_words = corpus.split(" ")
  words = []
  for tword in tagged_words
    words << get_word(tword)
  end
  return words
end

def ngrams(words)
  uni_grams = Hash.new(0)
  bi_grams = Hash.new(0)
  pos_grams = Hash.new(0)

  (words.length).times {|i|
    #uni grams
    uni = words[i][0]
    uni_grams[uni] += 1

    #uni grams w/ pos
    pos = words[i].join("/")
    pos_grams[pos] += 1

    #bigrams
    if i < words.length-1
      bi = words[i][0] + ' ' + words[i+1][0]
      bi_grams[bi] += 1
    end

  }
  return {
    :uni=>uni_grams,
    :bi=>bi_grams,
    :pos=>pos_grams
  }
end

##########################################################################
#read in files to massive gram array
tsize = ARGV[0].to_i
grams = {
  :uni=>{},
  :bi=>{},
  :pos=>{}
}

darr = ["neg-train","pos-train"]
for value in darr
  Dir.foreach(value){|x|

    unless x == "." or x == ".."
      test = []
      f = File.open("#{dir}/#{value}/#{x}", "r")
      f.each_line do |line|
        test << line
      end

      new_grams = ngrams(get_words(test.join(" ")))
      grams[:uni].merge!(new_grams[:uni]) { |key, v1, v2| v1 + v2 }
      grams[:bi].merge!(new_grams[:bi]) { |key, v1, v2| v1 + v2 }
      grams[:pos].merge!(new_grams[:pos]) { |key, v1, v2| v1 + v2 }
    end
    break unless (tsize -= 1) > 0
  }
end
puts "Got through the training files"

##########################################################################
#create unigram features
grams[:uni].delete_if {|key, value| value < 4 }
unigrams = grams[:uni].keys
n = unigrams.size

#create bigram features
biarr = grams[:bi].sort_by{|key, value| value}
bigrams = []
n.times do
  bigrams << biarr.shift[0]
end

#create adjectives and pos unigrams
adjectives = []
unigrams_pos = []

grams[:pos].each {|key, value|
  word = get_word(key)
  adjectives << word[0] if key.include?("/JJ") and value > 3
  unigrams_pos << key if unigrams.include?(word[0])
}
m = adjectives.size

#create top unigrams
unigrams_top = []
tu = grams[:uni].sort_by{|key, value| value}
m.times do
  unigrams_top << tu.shift[0]
end
puts "Created Features"

##########################################################################
#create feature files

features = {
  :unigram => [],
  :bigram => [],
  :unigram_pos => [],
  :adjectives => [],
  :unigram_top => []
}

darr.each_index{|i|
  tsize = ARGV[0].to_i
  target = (i==1) ? 1 : -1
  Dir.foreach(darr[i]){|x|
    unless x == "." or x == ".."
      test = []
      f = File.open("#{dir}/#{darr[i]}/#{x}", "r")
      f.each_line do |line|
        test << line
      end
      words = get_words(test.join(" "))

      u = []
      p = []
      t = []
      for word in words
        if unigrams.include?(word[0])
          ui = unigrams.index(word[0])+1
          u << ui unless u.include?(ui)
        end
        if unigrams_pos.include?("#{word[0]}/#{word[1]}")
          pi = unigrams_pos.index("#{word[0]}/#{word[1]}")+1
          p << pi unless p.include?(pi)
        end
        if unigrams_top.include?(word[0])
          ti = unigrams_top.index(word[0])+1
          t << ti unless t.include?(ti)
        end
      end
      u.sort!
      u.map!{|x| "#{x}:1.0"}
      p.sort!
      p.map!{|y| "#{y}:1.0"}
      t.sort!
      t.map!{|z| "#{z}:1.0"}

      features[:unigram] << "#{target} #{u.join(" ")}"
      features[:unigram_pos] << "#{target} #{p.join(" ")}"
      features[:unigram_top] << "#{target} #{t.join(" ")}"

      break unless (tsize -= 1) > 0
    end 
  }
}
puts "Created feature files"

doc = "#{base}/doc/assn2/"
File.open("#{doc}/unigram_train.txt", 'w') {|f| f.write(features[:unigram].join("\n")) }
File.open("#{doc}/unigram_pos_train.txt", 'w') {|f| f.write(features[:unigram_pos].join("\n")) }
File.open("#{doc}/unigram_top_train.txt", 'w') {|f| f.write(features[:unigram_top].join("\n")) }

system "#{base}/svm_light/svm_learn #{doc}/unigram_train.txt #{doc}/unigram_model.txt"
system "#{base}/svm_light/svm_learn #{doc}/unigram_pos_train.txt #{doc}/unigram_pos_model.txt"
system "#{base}/svm_light/svm_learn #{doc}/unigram_top_train.txt #{doc}/unigram_top_model.txt"

puts "All Done!"