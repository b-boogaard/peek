require 'peek/adapters/base'
require 'elasticsearch'

module Peek
  module Adapters
    class Elasticsearch < Base
      def initialize(options = {})
        @client = options.fetch(:client, ::Elasticsearch::Client.new)
        @expires_in = Integer(options.fetch(:expires_in, 60 * 30) * 1000)
        @index = options.fetch(:index, 'peek_requests_index')
        @type = options.fetch(:type, 'peek_request')
      end

      def get(request_id)
        begin
          result = @client.get_source index: @index, type: @type, id: "#{request_id}"
        rescue ::Elasticsearch::Transport::Transport::Errors::NotFound
          result = false
        end

        if result
          result.to_json
        else
          nil
        end
      end

      def save
        @client.index index: @index,
                      type: @type,
                      id: "#{Peek.request_id}",
                      body: Peek.results.to_json,
                      ttl: @expires_in
      rescue ::Elasticsearch::Transport::Transport::Errors::BadRequest
        false
      end

    end
  end
end
