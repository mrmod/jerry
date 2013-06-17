module MCollective
  class Application::Details < Application
    alias run_old run
    def run
      application_parse_options
      validate_configuration(configuration) if respond_to?(:validate_configuration)
      Util.setup_windows_sleeper if Util.windows?
      main
    end

    def post_option_parser(configuration)
      configuration[:node] = ARGV.shift if ARGV.size > 0
    end

    def main
      client = MCollective::Client.new(options[:config])
      client.options = options
      node = configuration[:node]
      Log.debug("Getting details for #{node}")
      util = rpcclient("rpcutil")
      util.identity_filter node
      util.progress = false
      Log.debug("Collecting node statistics")
      daemon_stats = util.custom_request("daemon_stats", {}, node, {'identity' => node}).first      
      node_inventory = util.custom_request("inventory", {}, node, {'identity' => node}).first      
      Log.debug("Node: #{node_inventory}")
      {:node => node_inventory.results, :daemon => daemon_stats.results}
    end
  end
end