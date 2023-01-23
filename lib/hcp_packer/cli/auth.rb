# frozen_string_literal: true

module HCPPacker
  module CLI
    class Auth < Dry::CLI::Command
      def initialize
        @client_id = ENV.fetch("HCP_CLIENT_ID")
        @client_secret = ENV.fetch("HCP_CLIENT_SECRET")
      end

      def call
        puts "TODO: implement authentication"
      end
    end
  end
end
