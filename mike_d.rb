require 'mcollective'

# config = File.join(Dir.pwd, 'mcollective','client.cfg')
# mco = MCollective::Config.instance
# mco.loadconfig(config) unless mco.configured
# ARGV.each{ARGV.pop}
['summary'].each do |e|
  ARGV << e
end

r = MCollective::Applications.run('puppetrun')

puts "r: #{r.inspect}"

#stats
# stats_m = [:discovered_nodes, :discovered, :failcount, :noresponsefrom, :okcount, :starttime, :responses, :responsesfrom, :totaltime]

# Summary
# stats_m = [:discovered_nodes, :discovered, :failcount, :noresponsefrom, :okcount, :starttime, :responses, :responsesfrom, :totaltime]
# ddl_m = [:entities]
# get_stuff = Proc.new{|iv,m|puts "#{m.to_s.capitalize}: #{iv.send(m).inspect}\n"  }


# stats_m.each {|m| get_stuff.call(r, m)}

# ddl_m.each {|m| get_stuff.call(r.ddl, m)}

# puts "Discovered: #{r.discovered_nodes.inspect}"

# puts r.constants.sort


