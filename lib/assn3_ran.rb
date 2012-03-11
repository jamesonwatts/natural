require 'rubygems'
require 'timeout'
base = "/Users/jameson/Projects/natural"
doc = "#{base}/doc/assn3"
Dir.chdir(base)

# #class extension
class Array
  # Chooses a random array element from the receiver based on the weights
  # provided. If _weights_ is nil, then each element is weighed equally.
  #
  #   [1,2,3].random          #=> 2
  #   [1,2,3].random          #=> 1
  #   [1,2,3].random          #=> 3
  #
  # If _weights_ is an array, then each element of the receiver gets its weight
  # from the corresponding element of _weights_. Notice that it favors the
  # element with the highest weight.
  #
  #   [1,2,3].random([1,4,1]) #=> 2
  #   [1,2,3].random([1,4,1]) #=> 1
  #   [1,2,3].random([1,4,1]) #=> 2
  #   [1,2,3].random([1,4,1]) #=> 2
  #   [1,2,3].random([1,4,1]) #=> 3
  #
  # If _weights_ is a symbol, the weight array is constructed by calling the
  # appropriate method on each array element in turn. Notice that it favors the
  # longer word when using :length.
  #
  #   ['dog', 'cat', 'hippopotamus'].random(:length) #=> "hippopotamus"
  #   ['dog', 'cat', 'hippopotamus'].random(:length) #=> "dog"
  #   ['dog', 'cat', 'hippopotamus'].random(:length) #=> "hippopotamus"
  #   ['dog', 'cat', 'hippopotamus'].random(:length) #=> "hippopotamus"
  #   ['dog', 'cat', 'hippopotamus'].random(:length) #=> "cat"
  def random(weights=nil)
    return random(map {|n| n.send(weights)}) if weights.is_a? Symbol

    weights ||= Array.new(length, 1.0)
    total = weights.inject(0.0) {|t,w| t+w}
    point = rand * total

    zip(weights).each do |n,w|
      return n if w >= point
      point -= w
    end
  end
end

# #functions
def ngrams(w,s,n)
  a = Array.new(n){Hash.new(0)}
  (w.length).times {|i|
    g = Array[w[i]]
    for j in 1..[w.length-i, n-1].min
      g << "#{g[j-1]}#{s}#{w[i+j]}"
    end
    for k in 0..g.size-1
      a[k][g[k]] += 1
    end
  }
  return a
end

def prob(file,cn,wn)

  words = []
  chars = []
  f = File.open("#{file}", "r")
  f.each_line do |line|
    chars += line.chomp.upcase.split(//)
    words += line.upcase.split(" ")
  end

  cg = ngrams(chars,'',cn)
  wg = ngrams(words,' ',wn)

  c = Array.new(cn) {Hash.new(0)}
  w = Array.new(wn) {Hash.new(0)}
  
  total = cg[0].values.inject(0){|sum,x| sum+x}
  cg[0].each{|k, v|
    c[0][k] = v.to_f/total
  }
  for i in 1..cn-1
    for key in cg[i-1].keys
      h = cg[i].select{|k,v| k.rindex(key) == 0}
      total = h.values.inject(0){|sum,x| sum+x}
      h.each{|k,v|
        h[k] = v.to_f/total
      }
      c[i][key]=h
    end
  end

  total = wg[0].values.inject(0){|sum,x| sum+x}
  wg[0].each{|k, v|
    w[0][k] = v.to_f/total
  }
  for i in 1..wn-1
    for key in wg[i-1].keys
      h = wg[i].select{|k,v| k.rindex(key+" ") == 0}
      total = h.values.inject(0){|sum,x| sum+x}
      h.each{|k,v|
        h[k] = v.to_f/total
      }
      w[i][key]=h
    end
  end

  return c,w
end

def sees(c,n)
  return c[0].keys.random(c[0].values) if n==0
  k = sees(c,n-1)
  return c[n][k].keys.random(c[n][k].values)
end

def perplexity(file,cm,wm)
  c = []
  w = []
  f = File.open("#{file}", "r")
  f.each_line do |line|
    c += line.chomp.upcase.split(//)
    w += line.upcase.split(" ")
  end


  sums = Array.new(cm.size){ 0 }
  (c.length).times {|i|
    g = Array[c[i]]
    for j in 1..[c.length-i, cm.size-1].min
      g << "#{g[j-1]}#{c[i+j]}"
    end

    sums[0] += Math.log2(cm[0][g[0]])
    for k in 1..g.size-1
      sums[k] += (1.0/c.size)*Math.log2(cm[k][g[k-1]][g[k]]) unless cm[k][g[k-1]][g[k]].nil?
    end
  }
  
  perps = []
  for sum in sums
    perps << 2**(-1*sum)
  end
  return perps
end

# run it
nc = 1000
nw = 200
cn = 21
wn = 7
if ARGV[1]
  ch,wo = prob("#{doc}/#{ARGV[0]}.txt",cn,wn)
  File.open("#{doc}/#{ARGV[0]}C.txt", "wb") {|f| Marshal.dump(ch, f)}
  File.open("#{doc}/#{ARGV[0]}W.txt", "wb") {|f| Marshal.dump(wo, f)}
else
  ch = File.open("#{doc}/#{ARGV[0]}C.txt", "rb") {|f| Marshal.load(f)}
  wo = File.open("#{doc}/#{ARGV[0]}W.txt", "rb") {|f| Marshal.load(f)}
end

puts("//////////////////PERPS")
perps = perplexity("#{doc}/#{ARGV[0]}.txt",ch,wo)
puts perps
exit

puts("//////////////////CHARS")
for i in 0..15
  puts "####{i} order"
  s = ""
  if i==0
    nc.times do
      s += ch[0].keys.random(ch[0].values)
    end
  else
    c = sees(ch,i-1)
    s = c
    (nc-i).times do
      chars = ch[i][c].keys.collect{|x| x.split(//)[i]}
      begin
        new = chars.random(ch[i][c].values) while new.nil?
        s += new
        c = (c+new).slice(-i,i)
      rescue
        puts "BUMMER"
        c = sees(ch,i-1)
      end
    end
  end
  puts s
end

puts("//////////////////WORDS")
for i in 0..6
  puts "####{i} order"
  s = []
  if i==0
    nw.times do
      s << wo[0].keys.random(wo[0].values)
    end
  else
    c = sees(wo,i-1)

    s << c
    (nw-i).times do
      words = wo[i][c].keys.random(wo[i][c].values)
      words = words.split(" ")
      s << words[i]
      words.shift
      c = words.join(" ")
    end
  end
  puts s.join(" ")
end