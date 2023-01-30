# frozen_string_literal: true

require "net/http"
require "json"

module HCPPacker
  module CLI
    class Auth < Dry::CLI::Command
      def initialize
        @client_id = ENV.fetch("HCP_CLIENT_ID")
        @client_secret = ENV.fetch("HCP_CLIENT_SECRET")
      end

      def call

        url = URI("https://auth.hashicorp.com/oauth/token")
        Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          req = Net::HTTP::Post.new(url)
          req["Content-Type"] = "application/json"
          req.body = JSON.dump({
            audience: "https://api.hashicorp.cloud",
            grant_type: "client_credentials",
            client_id: ENV.fetch("HCP_CLIENT_ID"),
            client_secret: ENV.fetch("HCP_CLIENT_SECRET"),
          })

          res = http.request(req)
          p res, res.body
        end

      end
    end
  end
end
