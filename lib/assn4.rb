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

def b()
  return '~'
end

def trisuffix(w)
  return w[-3,3] if w.size > 3 and !w.match(/^[a-zA-Z]*$/).nil?
  return b
end

def cappattern(w)
  return 'XX' unless w.match(/^[A-Z]*$/).nil?
  return 'Xx' unless w.match(/^[A-Z][a-z]*$/).nil?
  return 'xx' unless w.match(/^[a-z]*$/).nil?
  return b
end


def features(t)
  return [
    t.name,                                       # 0 class
    t.word,                                       # 1 word
    t.prev.nil? ? b : t.prev.word,                # 2 previous word
    t.next.nil? ? b : t.next.word,                # 3 next word
    t.ptag,                                       # 4 POS
    t.prev.nil? ? b : t.prev.ptag,                # 5 prev word POS
    t.next.nil? ? b : t.next.ptag,                # 6 next word POS
    t.ctag,                                       # 7 chunk
    t.prev.nil? ? b : t.prev.ctag,                # 8 prev chunk
    t.next.nil? ? b : t.next.ctag,                # 9 next chunk
    t.prev.etag.nil? ? 1 : 0,                     # 10 starts a sentence
    t.word.index(/[:punct:]/).nil? ? 0 : 1,       # 11 has punctuation
    t.word.match(/^[a-zA-Z]*$/).nil? ? 0 : 1,     # 12 is alpha-only
    trisuffix(t.word),                            # 13 trichar suffix
    t.word.match(/^[A-Z].$/).nil? ? 0 : 1,        # 14 Cap letter and a period
    cappattern(t.word),                           # 15 capitalization pattern
    t.prev.word.nil? ? b : cappattern(t.prev.word),                # 16 prev word cap pattern
    t.next.word.nil? ? b : cappattern(t.next.word),                 # 17 next word cap pattern
    $persons.has_key?(t.word) ? 1 : 0,
    t.prev.word.nil? ? 0 : $persons.has_key?(t.prev.word) ? 1 : 0,
    t.next.word.nil? ? 0 : $persons.has_key?(t.next.word) ? 1 : 0,
    $fnames.has_key?(t.word) ? 1 : 0,
    t.prev.word.nil? ? 0 : $fnames.has_key?(t.prev.word) ? 1 : 0,
    t.next.word.nil? ? 0 : $fnames.has_key?(t.next.word) ? 1 : 0,
    $lnames.has_key?(t.word) ? 1 : 0,
    t.prev.word.nil? ? 0 : $lnames.has_key?(t.prev.word) ? 1 : 0,
    t.next.word.nil? ? 0 : $lnames.has_key?(t.next.word) ? 1 : 0,
    $locations.has_key?(t.word) ? 1 : 0,
    t.prev.word.nil? ? 0 : $locations.has_key?(t.prev.word) ? 1 : 0,
    t.next.word.nil? ? 0 : $locations.has_key?(t.next.word) ? 1 : 0,
    $organizations.has_key?(t.word) ? 1 : 0,
    t.prev.word.nil? ? 0 : $organizations.has_key?(t.prev.word) ? 1 : 0,
    t.next.word.nil? ? 0 : $organizations.has_key?(t.next.word) ? 1 : 0
  ]
end

nat = "/Users/jameson/Projects/natural"
doc = "#{nat}/doc/assn4"
csy = "#{nat}/stanford-classifier"

if ARGV[0] == "build" or ARGV[0] == "both"
  Dir.chdir(doc)

  # ################################################# train
  $persons = {}
  f = File.open("PER.txt", "r")
  f.each_line do |x|
    $persons[x.split(" ")[1]] = true
  end
  $fnames = {}
  f = File.open("first.names.txt", "r")
  f.each_line do |x|
    $fnames[x] = true
  end
  $lnames = {}
  f = File.open("last.names.txt", "r")
  f.each_line do |x|
    $lnames[x] = true
  end
  $locations = {}
  f = File.open("LOC.txt", "r")
  f.each_line do |x|
    $locations[x.split(" ")[1]] = true
  end
  $organizations = {}
  f = File.open("ORG.txt", "r")
  f.each_line do |x|
    $organizations[x.split(" ")[1]] = true
  end

  tokens = []
  f = File.open("eng.train", "r")
  f.each_line do |token|
    t = Token.new(token.split(" "))
    tokens << t
  end

  for i in 0..tokens.size-1
    t = tokens[i]
    t.prev = tokens[i-1]
    t.next = tokens[i+1]
  end

  train = []
  for t in tokens
    unless t.etag.nil?
      line = features(t)
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
  for t in tokens
    unless t.etag.nil?
      line = features(t)
      test << line.join("\t")
    end
  end

  File.open("features_test.txt", 'w') {|f| f.write(test.join("\n")) }
end

if ARGV[0] == "both" or ARGV[0] == "train"
  Dir.chdir(csy)
  system "java -mx1800m -cp stanford-classifier.jar edu.stanford.nlp.classify.ColumnDataClassifier -prop #{doc}/prop.txt"
end