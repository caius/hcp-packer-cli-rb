# frozen_string_literal: true

require "net/http"
require "json"

module HCPPacker
  class Client
    def initialize
      @client_id = ENV.fetch("HCP_CLIENT_ID")
      @client_secret = ENV.fetch("HCP_CLIENT_SECRET")
      @organization_id = ENV.fetch("HCP_ORGANIZATION_ID")
      @project_id = ENV.fetch("HCP_PROJECT_ID")
    end

    # @param path [String] path on end of API to request
    # @raise [RuntimeError] error if !200 response
    # @return [Hash] parsed JSON object from API
    def get(path)
      # Auth if we need to
      # FIXME: check expiration time of token - if we ran that long
      unless @token
        p "fetching token"
        @token = fetch_token
      end

      p @token

      url = URI("https://api.cloud.hashicorp.com/packer/2021-04-30/organizations/#{@organization_id}/projects/#{@project_id}/#{path}")

      res = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        req = Net::HTTP::Get.new(url)
        req["Authorization"] = "Bearer #{@token}"
        req["Content-Type"] = "application/json"
        http.request(req)
      end

      unless res.is_a?(Net::HTTPSuccess)
        raise "Error making request #{res.body.inspect}"
      end

      JSON.parse(res.body)
    end

    def fetch_token
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

      JSON.parse(res.body).fetch("access_token")
    end
  end
end
