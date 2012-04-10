# #assignment four
class Token

  attr_accessor :word, :ptag, :ctag, :etag, :prev, :next

  
  def entity?
    return false if @etag=="O"
    return true
  end

  def name
    return @etag if @etag=="O"
    return @etag.split("-")[1]
  end

  def p
    return "#{@word} #{@ptag}"
  end
  def c
    return "#{@word} #{@ctag}"
  end
  def e
    return "#{@word} #{@etag}"
  end

  def initialize(t)
    @word = t[0]
    @ptag = t[1]
    @ctag = t[2]
    @etag = t[3]
  end

end

def features(t, g, pg, ng)
  return [
    t.name,
    g[t.e],
    ((t.prev.nil?) ? 0.0 : pg[t.prev.e]),
    ((t.next.nil?) ? 0.0 : ng[t.next.e]),
    g[t.p],
    ((t.prev.nil?) ? 0.0 : pg[t.prev.p]),
    ((t.next.nil?) ? 0.0 : ng[t.next.p]),
    g[t.c],
    ((t.prev.nil?) ? 0.0 : pg[t.prev.c]),
    ((t.next.nil?) ? 0.0 : ng[t.next.c])
  ]
end

nat = "/Users/jameson/Projects/natural"
doc = "#{nat}/doc/assn4"
csy = "#{nat}/stanford-classifier"

if ARGV[0] == "build"
  Dir.chdir(doc)

  # ################################################# train
  tokens = []
  grams = Hash.new(0.0)
  pgrams = Hash.new(0.0)
  ngrams = Hash.new(0.0)
  
  f = File.open("eng.train", "r")
  f.each_line do |token|
    
    t = Token.new(token.split(" "))
    tokens << t
  end

  for i in 0..tokens.size-1
    t = tokens[i]
    t.prev = tokens[i-1]
    t.next = tokens[i+1]
    if t.entity?
      grams[t.e] = 1.0
      grams[t.p] = 1.0
      grams[t.c] = 1.0

      unless t.prev.nil?
        pgrams[t.prev.p] = 1.0
        pgrams[t.prev.e] = 1.0
        pgrams[t.prev.c] = 1.0
      
      end

      unless t.next.nil?
        ngrams[t.next.e] = 1.0
        ngrams[t.next.p] = 1.0
        ngrams[t.next.c] = 1.0
      end
  
    end
  end

  train = []
  for t in tokens
    unless t.etag.nil?
      line = features(t,grams, pgrams, ngrams)
      train << line.join("\t")
    end
  end
  File.open("features_train.txt", 'w') {|f| f.write(train.join("\n")) }

  # ################################################# test
  tokens = []
  
  f = File.open("eng.test", "r")
  f.each_line do |token|
    t = Token.new(token.split(" "))
    tokens << t
  end

  for i in 0..tokens.size-1
    t = tokens[i]
    t.prev = tokens[i-1]
    t.next = tokens[i+1]
  end

  test = []
  #  k = 0
  for t in tokens
    unless t.etag.nil?
      #      puts "#{t.prev.word} #{t.word} #{t.next.word}\n"
      line = features(t,grams, pgrams, ngrams)
      test << line.join("\t")
    end
    #    break if (k+=1) > 10
  end

  File.open("features_test.txt", 'w') {|f| f.write(test.join("\n")) }
else
  Dir.chdir(csy)
  system "java -mx1800m -cp stanford-classifier.jar edu.stanford.nlp.classify.ColumnDataClassifier -prop #{doc}/prop.txt"
end