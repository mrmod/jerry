module MCollective
  class Application::Discover < Application
    alias run_old run
    def run
      application_parse_options
      validate_configuration(configuration) if respond_to?(:validate_configuration)
      Util.setup_windows_sleeper if Util.windows?
      main
    end
    def main
      client = MCollective::Client.new(options[:config])
      client.options = options
      start = Time.now.to_f
      times = []
      results = {}
      client.req('ping','discovery') do |r|
        # RTT in MS
        rtt = (Time.now.to_f - start)*1000
        times << rtt
        results[r[:senderid]] = rtt
      end
      results[:agents] = times.size
      times = [0.0] unless times.size > 0
      results[:statistics] ={
        :average => times.reduce(0.0){|a,t| a+t}/times.size.to_f,
        :max => times.dup.sort.pop,
        :min => times.dup.sort.shift,
        :data => times,
      }

      results
    end
  end
end