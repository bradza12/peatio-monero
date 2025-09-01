# Monero Client for interacting with Monero RPC
    class Client
      def initialize(rpc_endpoint)
        @rpc = RPC.new(rpc_endpoint)
      end

      def json_rpc(method, params = [])
        response = @rpc.call(method, params)
        raise ResponseError, response['error']['message'] if response['error']
        response['result']
      rescue StandardError => e
        raise ConnectionError, "Failed to connect to Monero RPC: #{e.message}"
      end
    end