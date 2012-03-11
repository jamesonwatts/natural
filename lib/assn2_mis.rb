require 'rubygems'
base = "/Users/jameson/Projects/natural"
rev = "#{base}/movie-reviews"
doc = "#{base}/doc/assn2/"

#relate file to index
Dir.chdir(rev)
count = 0
dmap = Hash.new(0)
for dir in ["neg-valid","pos-valid"]
  Dir.foreach(dir){|x|
    unless x == "." or x == ".."
      dmap[count] = x
      count +=1
    end
  }
end

Dir.chdir(doc)

missed = Hash.new(0)
for type in ["unigram","bigram","unigram_pos","adjectives","unigram_top","optimized"]

  f = File.open("#{doc}/#{type}_predictions_v.txt", "r")
  count = 0

  f.each_line do |line|
    if (count < 100 and line.to_f > 0) or (count >= 100 and line.to_f < 0)
      if missed.has_key?(count)
        missed[count] << type
      else
        missed[count] = [type]
      end
    end
    count += 1
  end
  #  puts count
  #  exit
end

misses = missed.sort_by{|key,value| value.size}
for miss in misses
  puts "#{miss[0]}, \"#{dmap[miss[0]]}\", #{miss[1].size}"
end
