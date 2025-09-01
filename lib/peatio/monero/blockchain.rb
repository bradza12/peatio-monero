# frozen_string_literal: true

module Peatio
  module Monero
    # TODO: Processing of unconfirmed transactions from mempool isn't supported now.
    class Blockchain < Peatio::Blockchain::Abstract
      DEFAULT_FEATURES = {case_sensitive: true, cash_addr_format: false}.freeze

      def initialize(custom_features={})
        super
        @json_rpc_call_id  = 0
        @json_rpc_endpoint = URI.parse(blockchain.server + "/json_rpc")
      end

      def configure(settings={})
        # Clean client state during configure.
        @client = nil
        @settings.merge!(settings.slice(*SUPPORTED_SETTINGS))
      end

      def fetch_block!(block_number)
          # Don't start process if we didn't receive new blocks.
        if blockchain.height + blockchain.min_confirmations >= latest_block && !force
          Rails.logger.info { "Skip synchronization. No new blocks detected height: #{blockchain.height}, latest_block: #{latest_block}" }
          fetch_unconfirmed_deposits
          return
        end

        from_block   = blockchain.height || 0
        to_block     = [latest_block, from_block + blocks_limit].min

        (from_block..to_block).each do |block_id|
          Rails.logger.info { "Started processing #{blockchain.key} block number #{block_id}." }

          block_data = { id: block_id }
          block_data[:deposits]    = build_deposits(client.get_transfers(
                                                            block_id - 1,
                                                            block_id,
                                                            { account_index: deposit_wallet.account_index,
                                                              deposit: true }))

          block_data[:withdrawals] = build_withdrawals(client.get_transfers(
                                                                block_id - 1,
                                                                block_id,
                                                                { account_index: withdraw_wallet.account_index,
                                                                  withdraw: true }))

          save_block(block_data, latest_block)

          Rails.logger.info { "Finished processing #{blockchain.key} block number #{block_id}." }
        end
        
        Peatio::Block.new(block_number, block_txs)
      rescue Client::Error => e
        raise Peatio::Blockchain::ClientError, e
      end

      def latest_block_number
        Rails.cache.fetch "latest_#{self.class.name.underscore}_block_number", expires_in: 5.seconds do
          json_rpc({method: 'get_height', params: {}}).fetch('result').fetch('height')
        end
      rescue Client::Error => e
        raise Peatio::Blockchain::ClientError, e
      end

      def load_balance_of_address!(address, _currency_id)
        params = {account_index: options[:account_index], address_indices: [0]}
        json_rpc({method: 'get_balance', params: params})
          .fetch('balance')
          .yield_self { |amount| convert_from_base_unit(amount, currency) }

        raise Peatio::Blockchain::UnavailableAddressBalanceError, address if address_with_balance.blank?

        address_with_balance[1].to_d
      rescue Client::Error => e
        raise Peatio::Blockchain::ClientError, e
      end

      private

      def filter_vout(tx_hash)
        tx_hash.fetch("vout").select do |entry|
          entry.fetch("value").to_d.positive? && entry["scriptPubKey"].has_key?("addresses")
        end
      end

      def build_transaction(tx_hash)
        entries = tx.fetch('destinations').map.with_index do |destination, index|
        { amount:  convert_from_base_unit(destination.fetch('amount'), currency),
          address: normalize_address(destination.fetch("address")),
          txout:   index 
        }
        end

        { id:            normalize_txid(tx.fetch('txid')),
          block_number:  tx.fetch('height') == 0 ? nil : tx.fetch('height'),
          entries:       entries
        }
      end

      def client
        @client ||= Client.new(settings_fetch(:server))
      end

      def settings_fetch(key)
        @settings.fetch(key) { raise Peatio::Blockchain::MissingSettingError, key.to_s }
      end
    end
  end
end