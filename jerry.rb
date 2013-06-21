require 'rubygems'
require 'sinatra/base'
require 'sinatra/config_file'
require 'haml'

# RacecarDriver
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
    @logger.debug("Getting #{node}")
    begin 
      @db.get(node).to_hash
    rescue => e
      @logger.error("Failed to get #{node}")
      raise e
    end
  end

  # Add a node
  # @param [String] node Node name
  def add_node(node)
    @logger.debug("Adding #{node}")
    begin
      @db.save_doc({'_id' => node})
    rescue => e
      @logger.error("Failed to add #{node}")
      raise e
    end
  end

  # Provide currently authorized nodes
  # @param [String] view View to find all nodes in
  # @param [String] key Row key to locate as the set
  # @return [Array]
  def authorized_nodes(view = 'default/all_nodes', key = 'id')
    @logger.debug("Rendering view: #{view}")
    @db.view(view)['rows'].reduce([]){|a,r| a << r[key] }
  end

  # Delete anode
  # @param [String] node Node to delete
  def delete_node(node)
    @logger.info("Deleting #{node}")
    n = get_node(node)
    @logger.debug("Retrieved #{n.inspect}")
    begin
      @db.delete_doc({'_id' => node, '_rev' => n['_rev']})
    rescue => e
      @logger.error("Failed to delete #{node} : #{e.inspect}")
    end
  end

  # Run an mcollective action
  # @param [String] config_file
  # @param [String] plugin MCollective plugin/action (ping, puppetd)
  # @param [String] collective
  # @param [Array] opts
  def mco_action(config_file, plugin, collective = 'mcollective', opts = DEFAULT_OPTS.dup)
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
  def discover_nodes(config_file,collective, opts=DEFAULT_OPTS.dup)
    @logger.debug("Running #{__method__} using config #{config_file}")
    mco_action(config_file, 'discover',collective,opts)
  end
  # Get details for a node
  def node_details(node, config_file, collective,opts=DEFAULT_OPTS.dup)
    @logger.debug("Running #{__method__} for #{node}")
    mco_action(config_file, 'details', collective,opts << node)
  end
  # Do a puppet run
  def run_node(config_file, collective, opts=DEFAULT_OPTS.dup)
    @logger.debug("Running #{__method__} for #{node}")
    mco_action(config_file, 'puppetrun',collective, opts)
  end
end


# Strong as any man alive
# Config file is by default jerry.yaml in the same dir as jerry.rb
# = Helpers
# == discovery_nodes
# Discover nodes using mco's ping plugin
# [collective]
#  [String] collective
# [opts]
#  [Array] opts Options array
# == node_details
# Get node details
# [node]
#  [String] node Node fqdn
# [collective]
#  [String] collective
# [opts]
#  [Array] opts Options array
# == run_node
# Run a node using the puppetd agent
# [node]
#  [String] node Node fqdn
# [collective]
#  [String] collective
# [opts]
#  [Array] opts Options array
class Jerry < Sinatra::Base
  register Sinatra::ConfigFile
  config_file(File.join(File.dirname(__FILE__), 'jerry.yaml'))
  set :haml, :format => :html5
  set :port => settings.port

  DEFAULT_OPTIONS = ['--dt',settings.mco_settings['discover_time'], '-t' , settings.mco_settings['timeout']]
  DEFAULT_COLLECTIVE = settings.collective
  before do 
    @racecar = RacecarDriver.new(settings.whitelist)
    @mco_config = settings.mco_config
    @logger = Logger.new(settings.logfile)
    @logger.level = settings.log_level
  end
  helpers do
    def discover_nodes(collective = DEFAULT_COLLECTIVE, opts = DEFAULT_OPTIONS.dup)
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

    
    def node_details(node, collective = DEFAULT_COLLECTIVE, opts = DEFAULT_OPTIONS.dup)
      @logger.debug("Getting node details for #{node} in #{collective}, opts: #{opts.inspect}")
      @racecar.node_details(node,@mco_config, collective, opts)
    end

    def run_node(collective = DEFAULT_COLLECTIVE, opts = DEFAULT_OPTIONS.dup)
      @logger.debug("Starting run for #{node}")
      @racecar.run_node(@mco_config,collective,opts)
    end
  end
	# Here.I.Am
	get '/' do
		@choices = ['Authorize','Discover','Inventory', 'Run']
		haml :index
	end
	# Authorize index
  get '/authorize' do
  	@authorized_nodes = @racecar.authorized_nodes
  	haml :authorize
  end
  # Authorized nodes list
  get '/authorize/nodes' do
    @authorized_nodes = @racecar.authorized_nodes
    @logger.debug("Displaying #{@authorized_nodes.inspect} ")
     # match pattern could be here
    haml :authorize_results, :layout => false
  end
  # Authorize a given node
  post '/authorize' do
    node = params[:node]
    @logger.debug("Authorizing #{node}")
    begin 
      @racecar.add_node(node)
    rescue RestClient::Conflict => e
      @logger.error("#{e.class}: #{e.inspect}")
      @authorize_error= {:message => "#{node} already exists"}
      # haml :authorize_errors, :layout => false
    rescue => e
      @logger.error("#{e.class}: #{e.inspect}")
      @authorize_error = {:message => node + " " + e.inspect}
      # haml :authorize_errors, :layout => false
    end
    @authorized_nodes = @racecar.authorized_nodes
    @logger.debug("Displaying #{@authorized_nodes.inspect} ")
    haml :authorize_results, :layout => false
  end
  # Delete an authorized node
  # @todo Delete verb?
  post '/authorize/delete/:node' do
    @logger.debug("Deleting #{params[:node]}")
    @racecar.delete_node(params[:node])
    @authorized_nodes = @racecar.authorized_nodes
    haml :authorize_results, :layout => false
  end
  # Discover index
  get '/discover' do
    haml :discover
  end
  # Discover results
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
  # Inventory index
  get '/inventory' do
  	@inventory = "Inventory"
  	haml :inventory
  end
  # Inventory a node
  post '/inventory' do
    @inventory = node_details(params[:node])
    @logger.debug("Model provided: #{@inventory.inspect}")
    haml :inventory_results, :layout => false
  end
  # Run index
  get '/run' do
    haml :run
  end

  # Run and report back
  post '/run' do
    @node = params[:node]
    @collective = params[:collective]
    @logger.debug("Run request for #{@node}@#{@collective}")
    opts = DEFAULT_OPTIONS.dup
    case params[:node_type]
      when 'regex'
        opts = opts + ["-F","fqdn='@node'","runonce"]
      when 'fact'
        opts = opts + ["-F", @node, "runonce"]
      when 'options'
        opts =  @node.split(' ')
      else
        opts = opts + ['-I', @node, 'runonce']
      end
    @node_run = run_node(@collective, opts.flatten)
    haml :run_results, :layout => false
  end
  # Run a specific node for curl-based scripts
  get '/run/:collective/:node' do
    @node = params[:node]
    @collective = params[:collective]
    @logger.debug("Run request for #{@node}@#{@collective}")
    @node_run = run_node(@node, @collective)
    haml :run_results
  end

	run! if $0 == app_file
end




