require 'rubygems'
require 'haml'
require 'sinatra/base'
require 'couchrest'
require 'mcollective'
require 'logger'


# Data interface
class RacecarDriver
  DEFAULT_OPTS = ['--dt','5','-t' ,'5', ]
  # Create a new racecar driver
  def initialize(db_url = 'http://localhost:5984/default')
    @db = CouchRest.database(db_url)
    @logger = Logger.new(File.join(Dir.pwd, "racecardriver.log"))
    @logger.level = Logger::DEBUG
  end

  # Get a node
  # @param [String] node node name
  def get_node(node)
    @db.get(node).to_hash
  end

  # Add a node
  # @param [String] node Node name
  def add_node(node)
    @db.save_doc({'_id' => node})
  end

  # Provide currently authorized nodes
  # @param [String] view View to find all nodes in
  # @param [String] key Row key to locate as the set
  # @return [Array]
  def authorized_nodes(view = 'default/all_nodes', key = 'id')
    @db.view(view)['rows'].reduce([]){|a,r| a << r[key] }
  end

  # Run an mcollective action
  # @param [String] config_file
  # @param [String] plugin MCollective plugin/action (ping, puppetd)
  # @param [String] collective
  # @param [Array] opts
  def mco_action(config_file, plugin, collective = 'mcollective', opts = DEFAULT_OPTS)
    @logger.debug("MCollective action : #{config_file} with opts #{opts.inspect}")
    mco_result = ''
    opts = ["-T", collective] + opts
    mco = MCollective::Config.instance
    mco.loadconfig(config_file) unless mco.configured
    
    @logger.debug("Loaded configuration #{config_file}")

    ARGV.dup.each {ARGV.pop}
    opts.each {|e| ARGV << e}
    @logger.debug("Running #{plugin}")
    begin
      mco_result = MCollective::Applications.run(plugin)
    rescue => e
      @logger.error(e)
    end
    @logger.debug("MCO result is : #{mco_result.inspect}")
    mco_result
  end

  # Ping all nodes
  def discover_nodes(config_file,collective, opts=DEFAULT_OPTS)
    @logger.debug("Running #{__method__} using config #{config_file}")
    mco_action(config_file, 'discover',collective,opts)
  end
  # Get details for a node
  def node_details(node, config_file, collective,opts=DEFAULT_OPTS)
    @logger.debug("Running #{__method__} for #{node}")
    mco_action(config_file, 'details', collective,opts << node)
  end
  # Do a puppet run
  def run_node(node, config_file, collective, opts=DEFAULT_OPTS)
    @logger.debug("Running #{__method__} for #{node}")
    opts << '-I'
    opts << node
    opts << 'runonce'
    mco_action(config_file, 'puppetrun',collective, opts)
  end
end


# Strong as any man alive
class Jerry < Sinatra::Base

  DEFAULT_OPTIONS = ['--dt','5','-t' ,'5', ]
  DEFAULT_COLLECTIVE = 'mcollective'

	set :haml, :format => :html5
  
  before do 
    @racecar = RacecarDriver.new('http://localhost:5984/whitelist')
    @mco_config = File.join(File.dirname(File.expand_path(__FILE__)),'mcollective','client.cfg')
    @logger = Logger.new(File.join(File.dirname(File.expand_path(__FILE__)),'sinatra.log'))
    @logger.level = Logger::DEBUG
  end

  helpers do
    # Find stuff
    # @param [String] collective
    # @param [Array] opts Options array
    def discover_nodes(collective = DEFAULT_COLLECTIVE, opts = DEFAULT_OPTIONS)
      collective = DEFAULT_COLLECTIVE if collective.empty?
      @logger.debug("#{self.class}:#{__method__}: Collective: #{collective}, opts: #{opts.inspect}")
      begin
        discovered = @racecar.discover_nodes(@mco_config,collective)
        @collective = collective
        @node_count = discovered[:agents]
        @statistics = discovered[:statistics]
        @nodes = discovered.delete_if{|k,v| [:agents,:statistics].include?k }
        @logger.debug("Rendering #{discovered.inspect}")
      rescue => e
        @logger.debug("No nodes found : #{e}")
        @node_count = @statistics = @nodes = 0
      end
      
    end
    # Get node details
    # @param [String] node Node FQDN
    def node_details(node, collective = DEFAULT_COLLECTIVE, opts = DEFAULT_OPTIONS)
      @logger.debug("Getting node details for #{node}")
      @racecar.node_details(node,@mco_config, collective, opts)
    end

    # Run a node using the puppetd agent
    # @param [String] node Node fqdn
    def run_node(node, collective = DEFAULT_COLLECTIVE, opts = DEFAULT_OPTIONS)
      @logger.debug("Starting run for #{node}")
      @racecar.run_node(node,@mco_config,collective,opts)
    end
  end


	# Here.I.Am
	get '/' do
		@choices = ['Authorize','Discover','Inventory']
		haml :index
	end

	# Authorize a host to be in the environment
  get '/authorize' do
  	@authorized_nodes = @racecar.authorized_nodes
  	haml :authorize
  end

  post '/authorize' do
    @authorized_nodes = @racecar.authorized_nodes
    @racecar.add_node(params[:node]) # match pattern could be here
    haml :authorize
  end

  # Filter the list down to just the node and show the serial for the cert
  post '/authorize/find' do
    @authorized_nodes = @racecar.authorized_nodes
    haml :authorize
  end

  post '/discover/results' do
    @logger.debug("Calling discover_nodes with #{params[:collective]}")
    discover_nodes(params[:collective])
    haml :discovery_results, :layout => false
  end
  # Discover nodes that are in the collective
  get '/discover/results' do
    discover_nodes
    haml :discovery_results, :layout => false
  end
  # Discover layout
  get '/discover' do
  	haml :discover
  end

  # Inventory of any running node in the collective
  get '/inventory' do
  	@inventory = "Inventory"
  	haml :inventory
  end

  post '/inventory' do
    @inventory = node_details(params[:node])
    @logger.debug("Model provided: #{@inventory.inspect}")
    haml :inventory_results, :layout => false
  end

  get '/run/:collective/:node' do
    @node = params[:node]
    @collective = params[:collective]
    @logger.debug("Run request for #{@node}@#{@collective}")
    @node_run = run_node(@node, @collective)
    haml :run_results
  end

	run! if $0 == app_file
end




