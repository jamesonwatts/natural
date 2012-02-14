require 'rubygems'

#function
def get_words(corpus)
  tagged_words = corpus.split(" ")
  words = []
  for tword in tagged_words
    words << tword.split("/")
  end
  return words
end

#create n-grams
def ngrams(words)
  #unigrams
  word_uni_grams = Hash.new(0)
  pos_uni_grams = Hash.new(0)
  word_bi_grams = Hash.new(0)
  pos_bi_grams = Hash.new(0)
  word_tri_grams = Hash.new(0)
  pos_tri_grams = Hash.new(0)

  (words.length).times {|i|
    uni = words[i][0]
    word_uni_grams[uni] += 1
    tuni = words[i][1]
    pos_uni_grams[tuni] += 1

    #bigrams
    if i < words.length-1
      bi = words[i][0] + ' ' + words[i+1][0]
      word_bi_grams[bi] += 1
      tbi = words[i][1] + ' ' + words[i+1][1]
      pos_bi_grams[tbi] += 1
    end

    #trigrams
    if i < words.length-2
      tri = words[i][0] + ' ' + words[i+1][0] + ' ' + words[i+2][0]
      word_tri_grams[tri] += 1
      ttri = words[i][1] + ' ' + words[i+1][1] + ' ' + words[i+2][1]
      pos_tri_grams[ttri] += 1
    end
  }
  return {
    :uni=>{:word=>word_uni_grams,:pos=>pos_uni_grams}, 
    :bi=>{:word=>word_bi_grams,:pos=>pos_bi_grams}, 
    :tri=>{:word=>word_tri_grams,:pos=>pos_tri_grams}
  }
end

#print frequency counts
def freq(grams, label)
  txt = "total tokens, #{grams.size}\n\n"
  txt += "#{label}, frequency\n"
  grams.sort_by{|key, value| value}.each { |key, value|
    txt += "\"#{key}\",#{value}\n"
  }
  File.open("/Users/jameson/Projects/natural/doc/assn1/#{label}.csv", 'w') {|f| f.write(txt) }
end

def intercept(target, foil, label)
  grams = target.sort_by{|key, value| value}
  fsize = target.size
  fsum = 0
  rsum = 0
  target.each {|key, value|
    if foil.include?(key)
      fsum += value
      grams.delete(key)
    else
      rsum += value
    end
  }

  txt = "total tokens, #{grams.size}\n"
  txt += "%types in test not in train, #{(grams.size.to_f/fsize)}\n"
  txt += "%token frequency in test not in train, #{rsum.to_f/fsum}\n\n"
  txt += "#{label}, frequency\n"
  grams.each { |key, value|
    txt += "\"#{key}\",#{value}\n"
  }
  File.open("/Users/jameson/Projects/natural/doc/assn1/#{label}.csv", 'w') {|f| f.write(txt) }
end

#read in file
filename = "/Users/jameson/Projects/natural/doc/brown-tagged-lite.txt"
test = []
f = File.open(filename, "r")
f.each_line do |line|
  test << line
end

puts "There are #{test.size} sentences in the corpus"
#create training and test sets
train = test.slice!(0,(test.size*0.9).to_i)
puts "There are #{train.size} training sentences in the corpus"
puts "There are #{test.size} test sentences in the corpus"
train_words = get_words(train.join(" "))
test_words = get_words(test.join(" "))

tr_grams = ngrams(train_words)
te_grams = ngrams(test_words)

#write out training frequencies
freq(tr_grams[:uni][:word], "tr_word_uni_grams")
freq(tr_grams[:bi][:word], "tr_word_bi_grams")
freq(tr_grams[:tri][:word], "tr_word_tri_grams")
freq(tr_grams[:uni][:pos], "tr_pos_uni_grams")
freq(tr_grams[:bi][:pos], "tr_pos_bi_grams")
freq(tr_grams[:tri][:pos], "tr_pos_tri_grams")
#write out test frequencies
freq(te_grams[:uni][:word], "te_word_uni_grams")
freq(te_grams[:bi][:word], "te_word_bi_grams")
freq(te_grams[:tri][:word], "te_word_tri_grams")
freq(te_grams[:uni][:pos], "te_pos_uni_grams")
freq(te_grams[:bi][:pos], "te_pos_bi_grams")
freq(te_grams[:tri][:pos], "te_pos_tri_grams")

#write out contrasts
intercept(te_grams[:uni][:word], tr_grams[:uni][:word], "tr_word_uni_grams_intercept")
intercept(te_grams[:bi][:word], tr_grams[:bi][:word], "tr_word_bi_grams_intercept")
intercept(te_grams[:tri][:word], tr_grams[:tri][:word], "tr_word_tri_grams_intercept")
intercept(te_grams[:uni][:pos], tr_grams[:uni][:pos], "tr_pos_uni_grams_intercept")
intercept(te_grams[:bi][:pos], tr_grams[:bi][:pos], "tr_pos_bi_grams_intercept")
intercept(te_grams[:tri][:pos], tr_grams[:tri][:pos], "tr_pos_tri_grams_intercept")

puts "All Done!"