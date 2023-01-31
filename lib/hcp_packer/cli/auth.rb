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
        # Check if we have valid auth saved
        if (auth = config[:auth])
          valid_until = auth[:acquired_at] + auth["expires_in"]
          if Time.now.to_i < valid_until
            puts "Access still valid until #{Time.at(valid_until)}, all good"
            return
          else
            config[:auth] = nil
            puts "Access invalid, obtaining new token"
          end
        end

        url = URI("https://auth.hashicorp.com/oauth/token")
        res = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          req = Net::HTTP::Post.new(url)
          req["Content-Type"] = "application/json"
          req.body = JSON.dump({
            audience: "https://api.hashicorp.cloud",
            grant_type: "client_credentials",
            client_id: @client_id,
            client_secret: @client_secret,
          })

          http.request(req)
        end

        unless res.is_a?(Net::HTTPSuccess)
          raise "Error authenticating: #{res.body.inspect}"
        end

        data = JSON.parse(res.body)
        data[:acquired_at] = Time.now.to_i
        config[:auth] = data

        puts "Authenticated successfully"
      end

      def config
        HCPPacker.config
      end
    end
  end
end
