require "rack"
require "rack/test"

module Merb
  module Test
    module MakeRequest

      def request(uri, env = {})
        if env.has_key?(:jar) && env[:jar].nil?
          jar = nil
        else
          jar = env.delete(:jar) || :default
        end
        
        response = get_session(jar).request(uri.to_s, env)

        Merb::Dispatcher.work_queue.size.times do
          Merb::Dispatcher.work_queue.pop.call
        end

        response
      end
      
      def get_session(name = :default)
        return ::Rack::Test::Session.new(Merb::Config[:app]) unless name
        @__sessions__ ||= {}
        @__sessions__[name] ||= ::Rack::Test::Session.new(Merb::Config[:app])
      end
    end
    
    module RequestHelper
      include MakeRequest

      def describe_request(rack)
        "a #{rack.original_env[:method] || rack.original_env["REQUEST_METHOD"] || "GET"} to '#{rack.url}'"
      end

      def describe_input(input)
        if input.respond_to?(:controller_name)
          "#{input.controller_name}##{input.action_name}"
        elsif input.respond_to?(:original_env)
          describe_request(input)
        else
          input
        end
      end
      
      def status_code(input)
        input.respond_to?(:status) ? input.status : input
      end
      
      def requesting(*args)   request(*args) end
      def response_for(*args) request(*args) end
    end
  end
end
