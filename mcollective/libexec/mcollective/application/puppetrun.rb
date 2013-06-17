module MCollective
  MCollective::Applications.load_application('puppet')
  class Application::Puppetrun < Application::Puppet
    alias run_old run
    alias halt_old halt
    alias printrpcstats_old printrpcstats
    alias printrpc_old printrpc

    # Alias around halt for each action
    def halt(result=''); result ;end
    def printrpcstats ; end
    def printrpc(result=''); result; end

    # Alias around default run model
    def run
      application_parse_options
      validate_configuration(configuration) if respond_to?(:validate_configuration)
      Util.setup_windows_sleeper if Util.windows?
      main
    end
  end
end