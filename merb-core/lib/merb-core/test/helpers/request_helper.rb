require "rack"
require "rack/test"

module Merb
  module Test
    module MakeRequest
      include ::Rack::Test::Methods

      def app
        Merb::Config[:app]
      end

      def build_rack_mock_session
        mock_session = super

        mock_session.after_request do
          process_work_queue
        end

        return mock_session
      end

      def request(uri, env = {})
        with_session_for_jar(env) do |session|
          session.request(uri.to_s, env)
        end
      end
      
      def with_session_for_jar(env, &block)
        if env.has_key?(:jar) && env[:jar].nil?
          session_name = false
        else
          session_name = env.delete(:jar) || :default
        end
        
        with_session(session_name, &block)
      end

      def process_work_queue
        Merb::Dispatcher.work_queue.size.times do
          Merb::Dispatcher.work_queue.pop.call
        end
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
