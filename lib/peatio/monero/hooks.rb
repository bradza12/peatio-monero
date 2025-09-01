# frozen_string_literal: true

module Peatio
  module Monero
    module Hooks
      BLOCKCHAIN_VERSION_REQUIREMENT = "~> 0.18.4.2"
      WALLET_VERSION_REQUIREMENT = "~> 0.18.4.2"

      class << self
        def check_compatibility
          unless Gem::Requirement.new(BLOCKCHAIN_VERSION_REQUIREMENT)
                                 .satisfied_by?(Gem::Version.new(Peatio::Blockchain::VERSION))
            [
              "Monero blockchain version requiremnt was not suttisfied by Peatio::Blockchain.",
              "Monero blockchain requires #{BLOCKCHAIN_VERSION_REQUIREMENT}.",
              "Peatio::Blockchain version is #{Peatio::Blockchain::VERSION}"
            ].join('\n').tap {|s| Kernel.abort s }
          end

          unless Gem::Requirement.new(WALLET_VERSION_REQUIREMENT)
                                 .satisfied_by?(Gem::Version.new(Peatio::Wallet::VERSION))
            [
              "Monero wallet version requiremnt was not suttisfied by Peatio::Wallet.",
              "Monero wallet requires #{WALLET_VERSION_REQUIREMENT}.",
              "Peatio::Wallet version is #{Peatio::Wallet::VERSION}"
            ].join('\n').tap {|s| Kernel.abort s }
          end
        end

        def register
          Peatio::Blockchain.registry[:monero] = Monero::Blockchain
          Peatio::Wallet.registry[:monero] = Monero::Wallet
        end
      end

      if defined?(Rails::Railtie)
        require "peatio/monero/railtie"
      else
        check_compatibility
        register
      end
    end
  end
end