require 'mcollective'

# config = File.join(Dir.pwd, 'mcollective','client.cfg')
# mco = MCollective::Config.instance
# mco.loadconfig(config) unless mco.configured
# ARGV.each{ARGV.pop}
['--json','-I','marlin.mock.com','runonce'].each do |e|
  ARGV << e
end

r = MCollective::Applications.run('puppetrun')
puts "r: #{r.inspect}"

