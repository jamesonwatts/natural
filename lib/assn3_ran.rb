require 'rubygems'
require 'timeout'
require 'set'
base = "/Users/jameson/Projects/natural"
doc = "#{base}/doc/assn3"
Dir.chdir(base)

# class extension for weighted random selection
class Array
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

# functions
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
  puts "#{a[n-1].size} of size #{n}-grams"
  return a
end

def prob(file,cn,wn)
  puts "Reading in file"
  words = []
  chars = []
  f = File.open("#{file}", "r")
  f.each_line do |line|
    chars += line.chomp.upcase.split(//)
    words += line.upcase.split(" ")
  end

  puts "Working on character ngrams"
  cg = ngrams(chars,'',cn)
  puts "Working on word ngrams"
  wg = ngrams(words,' ',wn)

  puts "Calculating character model"
  c = Array.new(cn) {Hash.new(0)}
  total = cg[0].values.inject(0){|sum,x| sum+x}
  cg[0].each{|k, v|
    c[0][k] = v.to_f/total
  }
  for i in 1..cn-1
    puts "...#{i}"
    for key in cg[i-1].keys
      set = cg[i].to_set
      tmp = set.select{|k,v| k.rindex(key) == 0}
      keys = tmp.collect{|x| x[0]}
      values = tmp.collect{|x| x[1]}
      total = values.inject(0){|sum,x| sum+x}
      h = {}
      keys.size.times { |i| h[ keys[i] ] = values[i].to_f/total }
      c[i][key]=h
    end
  end

  puts "Calculating word model"
  w = Array.new(wn) {Hash.new(0)}
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
  cp = []
  for sum in sums
    cp << 2**(-1*sum)
  end

  sums = Array.new(wm.size){ 0 }
  (w.length).times {|i|
    g = Array[w[i]]
    for j in 1..[w.length-i, wm.size-1].min
      g << "#{g[j-1]} #{w[i+j]}"
    end

    sums[0] += Math.log2(wm[0][g[0]])
    for k in 1..g.size-1
      sums[k] += (1.0/w.size)*Math.log2(wm[k][g[k-1]][g[k]]) unless wm[k][g[k-1]][g[k]].nil?
    end
  }
  wp = []
  for sum in sums
    wp << 2**(-1*sum)
  end
  puts("//////////////////PERPS")
  puts cp
  puts wp
end

def words(wo,nw)
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
        begin
          words = wo[i][c].keys.random(wo[i][c].values)
          words = words.split(" ")
          s << words[i]
          words.shift
          c = words.join(" ")
        rescue
          puts "BUMMER"
          c = sees(wo,i-1)
        end
      end
    end
    puts s.join(" ")
  end
end

def chars(ch,nc)
  puts("//////////////////CHARS")
  for i in 0..20
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
          new = chars.random(ch[i][c].values)
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
end

def accuracy(ch,wo,cn,n)
  puts("//////////////////ACCURACY")
  for i in 0..cn
    puts "####{i} order"
    s = ""
    if i==0
      n.times do
        s += ch[0].keys.random(ch[0].values)
      end
    else
      c = sees(ch,i-1)
      s = c
      (n-i).times do
        chars = ch[i][c].keys.collect{|x| x.split(//)[i]}
        begin
          new = chars.random(ch[i][c].values)
          s += new
          c = (c+new).slice(-i,i)
        rescue
          c = sees(ch,i-1)
        end
      end
    end
    words = s.split(" ")
    wg = ngrams(words,' ',3)

    sums = Array.new(3){0}
    for i in 0..wg.size-1
      for word in wg[i].keys
        sums[i] += 1 if wo[i].include?(word)
      end
    end
    for j in 0..sums.size-1
      puts sums[j].to_f/wo[i].keys.size
    end
  end
end

def get_word(tword)
  i = tword.rindex("/")
  return [tword.slice(0..i-1),tword.slice(i+1..tword.length)]
end

def hmm(file,n)
  puts "Reading in file"
  twords = ""
  f = File.open("#{file}", "r")
  f.each_line do |line|
    twords += line.upcase
  end

  twords.gsub!("./.","./. ##/## ##/##")
  twords = twords.split(" ")

  words = []
  tags = []
  for tword in twords
    tmp = get_word(tword)
    words << tmp[0]
    tags << tmp[1]
  end


  puts "Working on ngrams"
  wtg = ngrams(twords,' ',n)
  wg = ngrams(words,' ',n)
  tg = ngrams(tags,' ',n)

  puts "Calculating combined model"
  wt = Array.new(n) {Hash.new(0)}
  total = wtg[0].values.inject(0){|sum,x| sum+x}
  wtg[0].each{|k, v|
    wt[0][k] = v.to_f/total
  }
  for i in 1..n-1
    for key in wtg[i-1].keys
      h = wtg[i].select{|k,v| k.rindex(key+" ") == 0}
      total = h.values.inject(0){|sum,x| sum+x}
      h.each{|k,v|
        h[k] = v.to_f/total
      }
      wt[i][key]=h
    end
  end

  puts "Calculating word model"
  w = Array.new(n) {Hash.new(0)}
  total = wg[0].values.inject(0){|sum,x| sum+x}
  wg[0].each{|k, v|
    w[0][k] = v.to_f/total
  }
  for i in 1..n-1
    for key in wg[i-1].keys
      h = wg[i].select{|k,v| k.rindex(key+" ") == 0}
      total = h.values.inject(0){|sum,x| sum+x}
      h.each{|k,v|
        h[k] = v.to_f/total
      }
      w[i][key]=h
    end
  end

  puts "Calculating tag model"
  t = Array.new(n) {Hash.new(0)}
  total = tg[0].values.inject(0){|sum,x| sum+x}
  tg[0].each{|k, v|
    t[0][k] = v.to_f/total
  }
  for i in 1..n-1
    for key in tg[i-1].keys
      h = tg[i].select{|k,v| k.rindex(key+" ") == 0}
      total = h.values.inject(0){|sum,x| sum+x}
      h.each{|k,v|
        h[k] = v.to_f/total
      }
      t[i][key]=h
    end
  end

  return wt,w,t
end

def sentences(hwt,n)
  puts("//////////////////SENTENCES")
  for i in 1..n
    puts "####order #{i}"
    5.times do
      c = (i==1) ? "##/##" : "##/## ##/##"
      s = []
      while(!c.include?("./."))
        begin
          words = hwt[i][c].keys.random(hwt[i][c].values)
          words = words.split(" ")
          s << words[i]
          words.shift
          c = words.join(" ")
        rescue
          c = "./."
        end
      end
      puts "#{s.join(" ")}\n\n"
    end
  end
end

def hmm_prob(hw,ht,sw,st)
  p1 = p2 = 0.0
  for i in 1..st.size-1
    pw = hw[0].include?(sw[i]) ? hw[0][sw[i]] : 0.001
    t1 = ht[1][st[i-1]]["#{st[i-1]} #{st[i]}"]
    t1 = 0.001 if t1.nil?
    p1 += t1*pw

    t2 = (i>1) ? ht[2]["#{st[i-1]} #{st[i]}"]["#{st[i-2]} #{st[i-1]} #{st[i]}"] : 0.0
    t2 = 0.001 if t2.nil?
    p2 += (t1+t2)*pw
  end
  puts p1
  puts p2

end

def hmm_viterbi(hwt,ht,s)
  #  puts hwt[1]['##/##']
  #  exit
  tags = ['##']
  for i in 1..s.size-1
    t = hwt[0].select{|k,v| k.rindex(s[i]+"/") == 0}
    if t.size == 0
      tags << "??"
    elsif t.size == 1
      tags << t.keys[0].split("/")[1]
    else
      p = 0.0
      for key in t.keys
        tag = key.split("/")[1]
        begin
          h = ht[1][tags[i-1]].select{|k,v| k.rindex(tag) == 0}
          for key in h.keys
            if h[key] > p
              tag = key
              p = h[key]
            end
          end
          tags << tag
        rescue
          tags << "??"
        end
      end
    end
  end
  puts tags
end

# run it
nc = 1000
nw = 200
cn = 21
wn = 7
mm = false

if(mm)
  if ARGV[1]
    ch,wo = prob("#{doc}/#{ARGV[0]}.txt",cn,wn)
    File.open("#{doc}/#{ARGV[0]}C.txt", "wb") {|f| Marshal.dump(ch, f)}
    File.open("#{doc}/#{ARGV[0]}W.txt", "wb") {|f| Marshal.dump(wo, f)}
  else
    ch = File.open("#{doc}/#{ARGV[0]}C.txt", "rb") {|f| Marshal.load(f)}
    wo = File.open("#{doc}/#{ARGV[0]}W.txt", "rb") {|f| Marshal.load(f)}
  end

  # #words(wo,nw) #chars(ch,nc) #perplexity("#{doc}/#{ARGV[0]}.txt",ch,wo)
  # #accuracy(ch,wo,20,100000)
else
  if ARGV[1]
    hwt,hw,ht = hmm("#{doc}/#{ARGV[0]}.txt",3)
    File.open("#{doc}/#{ARGV[0]}WT.txt", "wb") {|f| Marshal.dump(hwt, f)}
    File.open("#{doc}/#{ARGV[0]}W.txt", "wb") {|f| Marshal.dump(hw, f)}
    File.open("#{doc}/#{ARGV[0]}T.txt", "wb") {|f| Marshal.dump(ht, f)}
  else
    hwt = File.open("#{doc}/#{ARGV[0]}WT.txt", "rb") {|f| Marshal.load(f)}
    hw = File.open("#{doc}/#{ARGV[0]}W.txt", "rb") {|f| Marshal.load(f)}
    ht = File.open("#{doc}/#{ARGV[0]}T.txt", "rb") {|f| Marshal.load(f)}
  end
  
  #  sentences(hwt,2)
  s1 = ['##','COLORLESS','GREEN','IDEAS','SLEEP','FURIOUSLY','.']
  t1 = ['##','JJ','JJ','NN','VB','RB','.']
  hmm_prob(hw,ht,s1,t1)

  s1 = ['##','FURIOUSLY','SLEEP','IDEAS','GREEN','COLORLESS','.']
  t1 = ['##','RB','VB','NN','JJ','JJ','.']
  hmm_prob(hw,ht,s1,t1)

  # #VISITING/VBG RELATIVES/NNS CAN/NNP BE/VB BORING/VBG ./.
  s1 = ['##','CONSIDERING','RELATIVES','CAN','BE','BORING','.']
  t1 = ['##','VBG','NNS','NNP','VB','VBG','.']
  hmm_prob(hw,ht,s1,t1)

  # #FLYING/VBG PLANES/NNS CAN/NNP BE/VB DANGEROUS/JJ ./.

  s2 = ['##','FLYING','PLANES','CAN','BE','DANGEROUS','.']
  t2 = ['##','VBG','NNS','NNP','VB','JJ','.']
  hmm_prob(hw,ht,s2,t2)

  # #TIME/NNP FLIES/NNPS LIKE/NNP AN/DT ARROW/NN ./.

  s3 = ['##','TIME','FLIES','LIKE','AN','ARROW','.']
  t3 = ['##','NNP','NNP','NNP','DT','NN','.']
  hmm_prob(hw,ht,s3,t3)

  hmm_viterbi(hwt,ht,s1)
  hmm_viterbi(hwt,ht,s2)
  hmm_viterbi(hwt,ht,s3)
end
