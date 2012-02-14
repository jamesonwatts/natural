require 'rubygems'

def get_words(corpus)
  tagged_words = corpus.split(" ")
  words = []
  for tword in tagged_words
    tarr = tword.split("/")
    tarr.pop
    words << tarr.join("/").downcase
  end
  return words
end

def classify(n,p)
  return "NEGATIVE" if n > p
  return "POSITIVE" if p > n
  return "TIE"
end

dir = "/Users/jameson/Projects/natural/movie-reviews"
Dir.chdir(dir)

#baseline
nwords = ["bummed","lame","unfortunate","sucks","terrible","horrible","offensive","disappointing","bad","detest","stupid","lousy","miserable","ridiculous","rotten","pathetic","phony","laughable","flawed","dreadful"]
pwords = ["awesome","amazing","love","perfect","entertaining","moving","lovely","best","wonderful","tremendous","good","spectacular","brilliant","clever","inspiring","divine","exquisite","gorgeous","masterful","polished"]
rclass = []

darr = {"NEGATIVE"=>"neg-valid","POSITIVE"=>"pos-valid"}
darr.each {|key, value|
  Dir.foreach(value){|x|
    unless x == "." or x == ".."
      test = []
      f = File.open("#{dir}/#{value}/#{x}", "r")
      f.each_line do |line|
        test << line
      end
      words = get_words(test.join(" "))

      p = n = 0
      for word in nwords
        n += 1 if words.include?(word)
      end
      for word in pwords
        p += 1 if words.include?(word)
      end
      rclass << [key,classify(n,p)]
#      puts "#{x} has #{words.size} words in it. #{n} are negative and #{p} are positive"
    end
  }
}

correct = 0
ties = 0
for review in rclass
  correct += 1 if review[0] == review[1]
  ties += 1 if review[1] == "TIE"
end
puts "#{correct} correct and #{ties} ties out of #{rclass.size} for an awesome percentage of #{(correct.to_f/rclass.size)*100}%"


#working on SVM lite



puts "All Done!"