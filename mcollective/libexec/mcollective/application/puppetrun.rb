module MCollective
  MCollective::Applications.load_application('puppet')
  class Application::Puppetrun < Application::Puppet
    alias run_old run
    alias halt_old halt
    alias printrpcstats_old printrpcstats
    alias printrpc_old printrpc
    alias client_old client
    alias main_old main
    alias summary_command_old summary_command

    # Alias around halt for each action
    def halt(result=''); result ;end
    def printrpcstats(a={}) ; end
    def printrpc(result=''); result; end

    def summary_command
      client.progress = false
      # puts "#{self.class}:#{__method__} : Client : #{client.class} #{client.client.methods.sort}\n"
      client.last_run_summary
    end
    def status_command
      display_results_single_field(client.status, :message)
      printrpcstats :summarize => true
      client.stats
    end    
    def client
      @client ||= rpcclient("puppetrun")
    end
    def main
      impl_method = "%s_command" % configuration[:command]

      if respond_to?(impl_method)
        send(impl_method)
      else
        raise_message(6, configuration[:command])
      end
    end
    # Alias around default run model
    def run
      application_parse_options
      validate_configuration(configuration) if respond_to?(:validate_configuration)
      Util.setup_windows_sleeper if Util.windows?
      main
    end
  end
end