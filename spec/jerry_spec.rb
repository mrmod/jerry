base_path = '/Users/bruce/Documents/Jerry'
$: << base_path
require 'jerry'

config_file = File.join(base_path, 'mcollective','client.cfg')
describe RacecarDriver do 
  it 'should not explode' do
    RacecarDriver.new
  end
  it 'should be able to ping a collective' do
    puts RacecarDriver.new.discover_nodes(config_file).inspect
  end
end