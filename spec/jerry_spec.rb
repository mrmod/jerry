base_path = '/Users/bruce/Documents/Jerry'
$: << base_path
require 'jerry'

node = 'marlin.mock.com'
collective = 'mcollective'
config_file = File.join(base_path, 'mcollective','client.cfg')
db_url = 'http://localhost:5984/whitelist'


# Crosses over a bit into an enviroment validation
# Pacecar is pure stubs
describe RacecarDriver do 
  before(:each) {
    @racecar = RacecarDriver.new(db_url)
    @pacecar = Object.new()
    

    @pacecar.stub(:discover_nodes).with(config_file, collective) { {:agents => true, :statistics => true}}
    # @pacecar.stub(:discover_nodes) { raise 'ArgumentError'}
    @pacecar.stub(:node_details).with(node, config_file, collective) { {:node => {:sender => node}}} 
    @pacecar.stub(:run_node).with(node, config_file, collective) { MCollective::RPC::Stats.new }
    @pacecar.stub(:add_node).with(node) { {'ok' => true, 'id' => node}}
    # @pacecar.stub(:add_node).with() { {'error' => true}}
    @pacecar.stub(:delete_node).with(node) {{'ok' => true, 'id' => node}}
    # @pacecar.stub(:delete_node).with() { {'error' => true}}
    @pacecar.stub(:authorized_nodes) { [node]}

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
    dn = @pacecar.discover_nodes(config_file,collective)
    dn.should be_a_kind_of(Hash)
    [:agents,:statistics].each do |k|
      dn.should have_key(k)
    end
  end
  it 'should be able to inventory a node' do
    dn = @pacecar.node_details(node, config_file,collective)
    dn.should have_key(:node)
    dn[:node].should have_key(:sender)
    dn[:node][:sender].should eql(node)
  end
  it 'should be able to run puppet' do
    @pacecar.run_node(node, config_file,collective).should be_a_kind_of(MCollective::RPC::Stats)
  end
  it 'should be able to authorize a node' do
    dn = @pacecar.add_node(node)
    cb_validator(dn, node)
  end
  it 'should be able to delete a node' do
    dn = @pacecar.delete_node(node) 
    cb_validator(dn, node)
  end

  it 'should be able to list authorized nodes' do
    @pacecar.add_node(node)
    @pacecar.authorized_nodes.should include(node)
    @pacecar.delete_node(node)
  end
end

# Web actions tests?