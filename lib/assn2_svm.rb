require 'rubygems'
base = "/Users/jameson/Projects/natural"
dir = "#{base}/movie-reviews"
doc = "#{base}/doc/assn2/"
Dir.chdir(dir)

#functions
def get_word(tword)
  i = tword.rindex("/")
  return [tword.slice(0..i-1),tword.slice(i+1..tword.length)]
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

def get_features(words, features)
  u = []
  b = []
  p = []
  a = []
  t = []
  o = []
  for word in words
    if features[:u].include?(word[0])
      ui = features[:u].index(word[0])+1
      u << ui unless u.include?(ui)
    end
    if features[:p].include?("#{word[0]}/#{word[1]}")
      pi = features[:p].index("#{word[0]}/#{word[1]}")+1
      p << pi unless p.include?(pi)
    end
    if features[:a].include?("#{word[0]}/#{word[1]}")
      ai = features[:a].index("#{word[0]}/#{word[1]}")+1
      a << ai unless a.include?(ai)
    end
    if features[:t].include?(word[0])
      ti = features[:t].index(word[0])+1
      t << ti unless t.include?(ti)
    end
    if features[:o].include?(word[0])
      oi = features[:o].index(word[0])+1
      o << oi unless o.include?(oi)
    end
  end
  for j in 0..words.size-2
    gram = "#{words[j][0]} #{words[j+1][0]}"
    if features[:b].include?(gram)
      bi = features[:b].index(gram)+1
      b << bi unless b.include?(bi)
    end
  end
  u.sort!
  u.map!{|c| "#{c}:1.0"}
  b.sort!
  b.map!{|d| "#{d}:1.0"}
  p.sort!
  p.map!{|e| "#{e}:1.0"}
  a.sort!
  a.map!{|f| "#{f}:1.0"}
  t.sort!
  t.map!{|g| "#{g}:1.0"}
  o.sort!
  o.map!{|h| "#{h}:1.0"}

  return {:u=>u,:b=>b,:p=>p,:a=>a,:t=>t,:o=>o}
end

##########################################################################
#read in files to massive gram array
tsize = 0
train = false
validate = false
test = false
svm = true
grams = {
  :uni=>{},
  :bi=>{},
  :pos=>{}
}

for value in ["neg-train","pos-train","neg-valid","pos-valid"]
  tsize = ARGV[0].to_i
  puts "Working on #{value}"
  Dir.foreach(value){|x|
    unless x == "." or x == ".."
      f = File.open("#{dir}/#{value}/#{x}", "r")
      f.each_line do |line|      
        new_grams = ngrams(get_words(line))
        grams[:uni].merge!(new_grams[:uni]) { |key, v1, v2| v1 + v2 }
        grams[:bi].merge!(new_grams[:bi]) { |key, v1, v2| v1 + v2 }
        grams[:pos].merge!(new_grams[:pos]) { |key, v1, v2| v1 + v2 }
      end
    end
    break unless (tsize -= 1) > 0
  }
end
puts "Got through the training files"

##########################################################################
#create unigram features
puts "Total unigrams: #{grams[:uni].size}"
grams[:uni].delete_if {|key, value| value < 4 }
unigrams = grams[:uni].keys
n = unigrams.size

#create bigram features
biarr = grams[:bi].sort_by{|key, value| value}
bigrams = []
n.times do
  bigrams << biarr.pop[0]
end

#create adjectives, optimized and pos unigrams
adjectives = []
unigrams_pos = []
optimized = []

grams[:pos].each {|key, value|
  word = get_word(key)
  adjectives << key if key.include?("/JJ") and value > 3
  unigrams_pos << key if unigrams.include?(word[0])
  optimized << word[0] if key.include?("/JJ") and value > 3
}
m = adjectives.size

#create top unigrams
unigrams_top = []
tu = grams[:uni].sort_by{|key, value| value}
m.times do
  unigrams_top << tu.pop[0]
end

#update optimized grams
optimized += unigrams_top

tokens = {:u=>unigrams,:b=>bigrams,:p=>unigrams_pos,:a=>adjectives,:t=>unigrams_top,:o=>optimized}
tokens.each{|key, value|
  puts "#{key}-size: #{value.size}"
  tmp = []
  for k in 1..value.size
    tmp << "#{k}-#{value[k-1]}"
  end
  File.open("#{doc}/#{key}.txt", 'w') {|f| f.write(tmp.join("\n")) }
}

##########################################################################
#create training files
if(train)
  File.open("#{doc}/unigram_train.txt", 'w') {|f| f.write("#unigram\n") }
  File.open("#{doc}/bigram_train.txt", 'w') {|f| f.write("#bigram\n") }
  File.open("#{doc}/unigram_pos_train.txt", 'w') {|f| f.write("#unigram pos\n") }
  File.open("#{doc}/adjectives_train.txt", 'w') {|f| f.write("#adjectives\n") }
  File.open("#{doc}/unigram_top_train.txt", 'w') {|f| f.write("#unigram top\n") }
  File.open("#{doc}/optimized_train.txt", 'w') {|f| f.write("#optimized\n") }

  td = ["neg-train","pos-train"]
  td.each_index{|i|
    tsize = ARGV[0].to_i
    target = (i==1) ? "+1" : "-1"
    Dir.foreach(td[i]){|x|
      unless x == "." or x == ".."
        t = []
        f = File.open("#{dir}/#{td[i]}/#{x}", "r")
        f.each_line do |line|
          t << line
        end

        features = get_features(get_words(t.join(" ")),tokens)

        File.open("#{doc}/unigram_train.txt", 'a+') {|f| f.write("#{target} #{features[:u].join(" ")}\n") }
        File.open("#{doc}/bigram_train.txt", 'a+') {|f| f.write("#{target} #{features[:b].join(" ")}\n") }
        File.open("#{doc}/unigram_pos_train.txt", 'a+') {|f| f.write("#{target} #{features[:p].join(" ")}\n") }
        File.open("#{doc}/adjectives_train.txt", 'a+') {|f| f.write("#{target} #{features[:a].join(" ")}\n") }
        File.open("#{doc}/unigram_top_train.txt", 'a+') {|f| f.write("#{target} #{features[:t].join(" ")}\n") }
        File.open("#{doc}/optimized_train.txt", 'a+') {|f| f.write("#{target} #{features[:o].join(" ")}\n") }
        
        puts tsize
        break unless (tsize -= 1) > 0
      end
    }
  }
  puts "Created training files"
end
##########################################################################
#create validation files
if(validate)
  File.open("#{doc}/unigram_valid.txt", 'w') {|f| f.write("#unigram\n") }
  File.open("#{doc}/bigram_valid.txt", 'w') {|f| f.write("#bigram\n") }
  File.open("#{doc}/unigram_pos_valid.txt", 'w') {|f| f.write("#unigram pos\n") }
  File.open("#{doc}/adjectives_valid.txt", 'w') {|f| f.write("#adjectives\n") }
  File.open("#{doc}/unigram_top_valid.txt", 'w') {|f| f.write("#unigram top\n") }
  File.open("#{doc}/optimized_valid.txt", 'w') {|f| f.write("#optimized\n") }

  vd = ["neg-valid","pos-valid"]
  vd.each_index{|i|
    tsize = ARGV[0].to_i
    target = (i==1) ? "+1" : "-1"
    Dir.foreach(vd[i]){|x|
      unless x == "." or x == ".."
        t = []
        f = File.open("#{dir}/#{vd[i]}/#{x}", "r")
        f.each_line do |line|
          t << line
        end

        features = get_features(get_words(t.join(" ")),tokens)

        File.open("#{doc}/unigram_valid.txt", 'a+') {|f| f.write("#{target} #{features[:u].join(" ")}\n") }
        File.open("#{doc}/bigram_valid.txt", 'a+') {|f| f.write("#{target} #{features[:b].join(" ")}\n") }
        File.open("#{doc}/unigram_pos_valid.txt", 'a+') {|f| f.write("#{target} #{features[:p].join(" ")}\n") }
        File.open("#{doc}/adjectives_valid.txt", 'a+') {|f| f.write("#{target} #{features[:a].join(" ")}\n") }
        File.open("#{doc}/unigram_top_valid.txt", 'a+') {|f| f.write("#{target} #{features[:t].join(" ")}\n") }
        File.open("#{doc}/optimized_valid.txt", 'a+') {|f| f.write("#{target} #{features[:o].join(" ")}\n") }

        puts tsize
        break unless (tsize -= 1) > 0
      end
    }
  }
  puts "Created validation files"
end

##########################################################################
#create test files
if(test)
  File.open("#{doc}/unigram_test.txt", 'w') {|f| f.write("#unigram\n") }
  File.open("#{doc}/bigram_test.txt", 'w') {|f| f.write("#bigram\n") }
  File.open("#{doc}/unigram_pos_test.txt", 'w') {|f| f.write("#unigram pos\n") }
  File.open("#{doc}/adjectives_test.txt", 'w') {|f| f.write("#adjectives\n") }
  File.open("#{doc}/unigram_top_test.txt", 'w') {|f| f.write("#unigram top\n") }
  File.open("#{doc}/optimized_test.txt", 'w') {|f| f.write("#optimized\n") }

  sd = ["neg-test","pos-test"]
  sd.each_index{|i|
    tsize = ARGV[0].to_i
    target = (i==1) ? "+1" : "-1"
    Dir.foreach(sd[i]){|x|
      unless x == "." or x == ".."
        t = []
        f = File.open("#{dir}/#{sd[i]}/#{x}", "r")
        f.each_line do |line|
          t << line
        end

        features = get_features(get_words(t.join(" ")),tokens)

        File.open("#{doc}/unigram_test.txt", 'a+') {|f| f.write("#{target} #{features[:u].join(" ")}\n") }
        File.open("#{doc}/bigram_test.txt", 'a+') {|f| f.write("#{target} #{features[:b].join(" ")}\n") }
        File.open("#{doc}/unigram_pos_test.txt", 'a+') {|f| f.write("#{target} #{features[:p].join(" ")}\n") }
        File.open("#{doc}/adjectives_test.txt", 'a+') {|f| f.write("#{target} #{features[:a].join(" ")}\n") }
        File.open("#{doc}/unigram_top_test.txt", 'a+') {|f| f.write("#{target} #{features[:t].join(" ")}\n") }
        File.open("#{doc}/optimized_test.txt", 'a+') {|f| f.write("#{target} #{features[:o].join(" ")}\n") }

        puts tsize
        break unless (tsize -= 1) > 0
      end
    }
  }
  puts "Created testing files"
end

##########################################################################
#run svm
if(svm)
  system "#{base}/svm_light/svm_learn #{doc}/unigram_train.txt #{doc}/unigram_model.txt"
  system "#{base}/svm_light/svm_learn #{doc}/bigram_train.txt #{doc}/bigram_model.txt"
  system "#{base}/svm_light/svm_learn #{doc}/unigram_pos_train.txt #{doc}/unigram_pos_model.txt"
  system "#{base}/svm_light/svm_learn #{doc}/adjectives_train.txt #{doc}/adjectives_model.txt"
  system "#{base}/svm_light/svm_learn #{doc}/unigram_top_train.txt #{doc}/unigram_top_model.txt"
  system "#{base}/svm_light/svm_learn #{doc}/optimized_train.txt #{doc}/optimized_model.txt"

  puts "Running Validation Models"

  system "#{base}/svm_light/svm_classify #{doc}/unigram_valid.txt #{doc}/unigram_model.txt #{doc}/unigram_predictions_v.txt"
  system "#{base}/svm_light/svm_classify #{doc}/bigram_valid.txt #{doc}/bigram_model.txt #{doc}/bigram_predictions_v.txt"
  system "#{base}/svm_light/svm_classify #{doc}/unigram_pos_valid.txt #{doc}/unigram_pos_model.txt #{doc}/unigram_pos_predictions_v.txt"
  system "#{base}/svm_light/svm_classify #{doc}/adjectives_valid.txt #{doc}/adjectives_model.txt #{doc}/adjectives_predictions_v.txt"
  system "#{base}/svm_light/svm_classify #{doc}/unigram_top_valid.txt #{doc}/unigram_top_model.txt #{doc}/unigram_top_predictions_v.txt"
  system "#{base}/svm_light/svm_classify #{doc}/optimized_valid.txt #{doc}/optimized_model.txt #{doc}/optimized_predictions_v.txt"

  puts "Running Test Models"
  
  system "#{base}/svm_light/svm_classify #{doc}/unigram_test.txt #{doc}/unigram_model.txt #{doc}/unigram_predictions.txt"
  system "#{base}/svm_light/svm_classify #{doc}/bigram_test.txt #{doc}/bigram_model.txt #{doc}/bigram_predictions.txt"
  system "#{base}/svm_light/svm_classify #{doc}/unigram_pos_test.txt #{doc}/unigram_pos_model.txt #{doc}/unigram_pos_predictions.txt"
  system "#{base}/svm_light/svm_classify #{doc}/adjectives_test.txt #{doc}/adjectives_model.txt #{doc}/adjectives_predictions.txt"
  system "#{base}/svm_light/svm_classify #{doc}/unigram_top_test.txt #{doc}/unigram_top_model.txt #{doc}/unigram_top_predictions.txt"
  system "#{base}/svm_light/svm_classify #{doc}/optimized_test.txt #{doc}/optimized_model.txt #{doc}/optimized_predictions.txt"
end
puts "All Done!"