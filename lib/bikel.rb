require 'rubygems'
require 'fileutils'

prefix = "/Users/jameson/Desktop/classes/ling581"
dbprefix = "#{prefix}/dbparser"
wkdir = "#{prefix}/assignment2"

trains = ['01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21','22']
t = []
while trains.size > 0 do
  t << trains.delete_at(rand(trains.size-1))
  puts "Training on #{t.join(",")}"

  for n in t
    system "cp #{wkdir}/cat/wsj-#{n}.mrg #{wkdir}/train"
  end
  puts "Creating training file"
  system "cat #{wkdir}/train/wsj-*.mrg > #{wkdir}/train/train.mrg"
  puts "Training system"
  system "#{dbprefix}/bin/train 800 #{dbprefix}/settings/collins.properties #{wkdir}/train/train.mrg"

  #system "#{prefix}/jmx/mxpost #{prefix}/jmx/tagger.project < #{prefix}/assignment2/ #{prefix}/"
  puts "Parsing section 23"
  system "#{dbprefix}/bin/parse 400 #{dbprefix}/settings/collins.properties #{wkdir}/train/train.obj.gz #{wkdir}/wsj-23.lsp"

  puts "Evaluating"
  system "#{dbprefix}/scorer/evalb -p #{dbprefix}/scorer/sample.prm #{wkdir}/wsj-23.mrg #{wkdir}/wsj-23.lsp.parsed > #{wkdir}/results.#{t.size}.#{t.join("_")}.txt"

  system "rm -f #{wkdir}/train/*"
  #  system "rm -f #{wkdir}/wsj-23.lsp.parsed"
  puts "-------------------------Phew-------------------------"
  sleep(5)
end