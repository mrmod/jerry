base_path = '/Users/bruce/Documents/Jerry'
$: << base_path
require 'jerry'

node = 'marlin.mock.com'
collective = 'mcollective'
config_file = File.join(base_path, 'mcollective','client.cfg')
db_url = 'http://localhost:5984/whitelist'


# Crosses over a bit into an enviroment validation
describe RacecarDriver do 
  before(:each) {
    @racecar = RacecarDriver.new(db_url)
  }
  def cb_validator(dn, node)
    dn.should be_a_kind_of(Hash)
    dn.should have_key('ok')
    dn.should have_key('id')
    dn['ok'].should be_true
    dn['id'].should eql(node)
  end
  it 'should not explode' do
    RacecarDriver.new(db_url)
  end
  it 'should be able to discover nodes' do
    dn = @racecar.discover_nodes(config_file,collective)
    dn.should be_a_kind_of(Hash)
    [:agents,:statistics].each do |k|
      dn.should have_key(k)
    end
  end
  it 'should be able to inventory a node' do
    dn = RacecarDriver.new.node_details(node, config_file,collective)
    dn.should have_key(:node)
    dn[:node].should have_key(:sender)
    dn[:node][:sender].should eql(node)
  end
  it 'should be able to run puppet' do
    RacecarDriver.new.run_node(node, config_file,collective).should be_a_kind_of(MCollective::RPC::Stats)
  end
  it 'should be able to authorize a node' do
    dn = @racecar.add_node(node)
    cb_validator(dn, node)
  end
  it 'should be able to delete a node' do
    dn = @racecar.delete_node(node) 
    cb_validator(dn, node)
  end

  it 'should be able to list authorized nodes' do
    @racecar.add_node(node)
    @racecar.authorized_nodes.should include(node)
    @racecar.delete_node(node)
  end
end