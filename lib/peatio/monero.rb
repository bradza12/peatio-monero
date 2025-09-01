require 'peatio'

module Peatio
  module Monero
    require 'peatio/monero/blockchain'
    require 'peatio/monero/client'
    require 'peatio/monero/wallet'
    require 'peatio/monero/hooks'
    require 'peatio/monero/railtie' if defined?(Rails)
    require 'peatio/monero/version'
