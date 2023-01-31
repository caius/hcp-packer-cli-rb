# frozen_string_literal: true

require "net/http"
require "json"
require "pp"

module HCPPacker
  module CLI
    class ListBuckets < Dry::CLI::Command
      def call

        url = URI("https://api.cloud.hashicorp.com/packer/2021-04-30/organizations/#{organization_id}/projects/#{project_id}/images")

        res = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          req = Net::HTTP::Get.new(url)
          req["Authorization"] = "Bearer #{access_token}"
          req["Content-Type"] = "application/json"
          http.request(req)
        end

        unless res.is_a?(Net::HTTPSuccess)
          raise "Error making request #{res.body.inspect}"
        end

        pp JSON.parse(res.body).fetch("buckets")
      end

      def access_token
        HCPPacker.config[:auth]["access_token"]
      end

      def organization_id
        ENV.fetch("HCP_ORGANIZATION_ID")
      end

      def project_id
        ENV.fetch("HCP_PROJECT_ID")
      end
    end
  end
end
