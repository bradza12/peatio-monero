    # Blockchain implementation for Monero
    class Blockchain < Peatio::Blockchain::Abstract
      def initialize
        @client = Client.new(ENV['MONERO_RPC_ENDPOINT'] || 'http://localhost:18081/json_rpc')
      end

      def configure(settings)
        # Configure currency settings (e.g., case sensitivity for addresses)
        settings[:currencies].each do |currency|
          currency[:case_sensitive] = false # Monero addresses are case-insensitive
        end
      end

      def latest_block_number
        json_rpc('get_block_count')['count']
      end

      def fetch_block!(block_number)
        block_hash = json_rpc('get_block_hash', [block_number])['block_hash']
        block = json_rpc('get_block', ['block_hash' => block_hash])
        # Map Monero block transactions to Peatio's expected format
        transactions = block['tx_hashes'].map do |txid|
          tx = json_rpc('get_transaction', ['txid' => txid])
          {
            txid: txid,
            from_address: tx['from_address'],
            to_address: tx['to_address'],
            amount: tx['amount'].to_i / 1_000_000_000_000, # Convert piconero to XMR
            confirmations: tx['confirmations'],
            status: tx['status']
          }
        end
        transactions
      end

      def load_balance_of_address!(address)
        balance = json_rpc('get_balance', ['address' => address])['unlocked_balance']
        balance.to_i / 1_000_000_000_000 # Convert piconero to XMR
      end
    end