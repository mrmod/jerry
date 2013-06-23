base_path = '/Users/bruce/Documents/Jerry'
$: << base_path
require 'jerry'
require 'capybara/rspec'
# require 'rspec/rails'


node = 'marlin.mock.com'
collective = 'mcollective'
config_file = File.join(base_path, 'mcollective','client.cfg')
db_url = 'http://localhost:5984/whitelist'
create_pacecar = Proc.new {
  pacecar = Object.new()
  pacecar.stub(:discover_nodes).with(config_file, collective) { {:agents => true, :statistics => true}}
  # pacecar.stub(:discover_nodes) { raise 'ArgumentError'}
  pacecar.stub(:node_details).with(node, config_file, collective) { {:node => {:sender => node}}} 
  pacecar.stub(:run_node).with(node, config_file, collective) { MCollective::RPC::Stats.new }
  pacecar.stub(:add_node).with(node) { {'ok' => true, 'id' => node}}
  # pacecar.stub(:add_node).with() { {'error' => true}}
  pacecar.stub(:delete_node).with(node) {{'ok' => true, 'id' => node}}
  # pacecar.stub(:delete_node).with() { {'error' => true}}
  pacecar.stub(:authorized_nodes) { [node]}
  pacecar
}

Capybara.app = Jerry
features = ['authorize','discover','inventory','run']
nav_bar = ['Start'] + features.reduce([]){|a,f| a << f.capitalize}
# Crosses over a bit into an enviroment validation
# Pacecar is pure stubs
describe RacecarDriver do 
  before(:each) {
    @racecar = RacecarDriver.new(db_url)
    @pacecar  = create_pacecar.call
    # @pacecar = Object.new()
    # @pacecar.stub(:discover_nodes).with(config_file, collective) { {:agents => true, :statistics => true}}
    # # @pacecar.stub(:discover_nodes) { raise 'ArgumentError'}
    # @pacecar.stub(:node_details).with(node, config_file, collective) { {:node => {:sender => node}}} 
    # @pacecar.stub(:run_node).with(node, config_file, collective) { MCollective::RPC::Stats.new }
    # @pacecar.stub(:add_node).with(node) { {'ok' => true, 'id' => node}}
    # # @pacecar.stub(:add_node).with() { {'error' => true}}
    # @pacecar.stub(:delete_node).with(node) {{'ok' => true, 'id' => node}}
    # # @pacecar.stub(:delete_node).with() { {'error' => true}}
    # @pacecar.stub(:authorized_nodes) { [node]}

  }
  def cb_validator(dn, node)
    dn.should be_a_kind_of(Hash)
    dn.should have_key('ok')
    dn.should have_key('id')
    dn['ok'].should be_true
    dn['id'].should eql(node)
  end
  context 'basic operation' do
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
end

# View/Controller testing
describe 'Jerry to controller', :type => :feature do

  it 'should not explode' do
    visit '/'
    status_code.should eql(200)
  end
  context 'and all features wont explode' do
    before(:each) {
      @features = features
      @nav_bar = nav_bar
    }    
    features.each do |feature|
      it "should have the #{feature} GET /#{feature}" do
        visit '/' << feature
        status_code.should eql(200)
      end
      it "should have the nav_bar with all features at /#{feature}" do
        visit '/' << feature
        nav_bar.each do |link|
          page.should have_content(link)
        end
      end
    end
  end
end

# /discover
describe 'Finding nodes in a collective', :type => :feature do
  it 'should let a user discover all nodes without putting in any input',:js => true do
    visit '/discover'
    find('#discover-submit').click
    page.should have_content('loading...')
  end
end

# /inventory
describe 'Inventory a node in a collective', :type => :feature do
  it 'should let a user inventory a specific node', :js => true do
    visit '/inventory'
    # fill_in 'node', :with => 'node.mock.com'
    find('#inventory-submit').click
    page.should have_content('No details found')
  end
end

# /authorize
describe 'Authorize a node in a collective', :type => :feature do
  it 'should display the added node with an option to delete', :js => true do
    visit '/authorize'
    fill_in('node', :with => 'a.b.com')
    find('#authorize-submit').click
    page.should have_content('a.b.com delete')
  end
  it 'should be able to delete a node that exists', :js => true do
    pending
    visit '/authorize'
    fill_in('node', :with => 'a.b.com')
    find('#authorize-submit').click
    find('#delete_a.b.com').click
    page.should have_content('No authorized nodes')
  end
end

# /run
describe 'Run Puppet given a specific target style', :type => :feature do
  # Little bit of element navigation weirdness. This works in hand testing
  it 'should update the placeholder value with "host.site.com" when radio:node is active', :js => true do
    visit '/run'
    si_ph = '"host.site.com"'
    find('#lbl_node_type0').click
    # si_ph = find('#node_type0ph').value
    find('#search_input')[:placeholder].should eql(si_ph)
  end
  it 'should update the placeholder value with "/^web\d+\.site2\.com/" when radio:regex is active', :js => true do
    visit '/run'
    si_ph = '"/^web\\\\d+\\\\.site2\\\\.com/"'
    find('#lbl_node_type1').click
    find('#search_input')[:placeholder].should eql(si_ph)
  end
  it 'should update the placeholder value with "fact=value" when radio:fact is active', :js => true do
    visit '/run'
    si_ph = '"fact=value"'
    find('#lbl_node_type2').click
    find('#search_input')[:placeholder].should eql(si_ph)
  end  
  it 'should update the placeholder value with "-- dt 30 -F llama=\"loose\" runall 3" when radio:options is active', :js => true do
    visit '/run'
    si_ph = '"--dt 30 -F llama=\"loose\" runall 3"'
    find('#lbl_node_type3').click
    find('#search_input')[:placeholder].should eql(si_ph)
  end
end

# /classify
# This isn't stubbed out yet
describe 'Classify a node marlin.mock.com', :type => :feature do
  it 'should display the current classes for the node', :js => true do
    pending
    visit '/classify'
    fill_in('node', :with => 'marlin.mock.com')
    find('#classify-submit').click
    page.should have_content('default')
  end
  it 'should display the available modules excluding ones assigned', :js => true do
    pending
    visit '/classify'
    fill_in('node', :with => 'marlin.mock.com')
    find('#classify-submit').click
    page.should have_content('anotherclass')
  end
  it 'should bring up a module selected for assignent with input fields for each parameter, if available',:js => true do
    pending
    visit '/classify'
    fill_in('node', :with => 'marlin.mock.com')
    find('#classify-submit').click
    # page.should have_content('anotherclass')
    find('#class_anotherclass').click
    page.should have_content('edit anotherclass')
    find_field('#param_msg').visible?.should be_true
    find_field('#param_location').visible?.should be_true
  end
end

