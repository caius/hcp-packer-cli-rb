# frozen_string_literal: true

require "json"
require "net/http"
require "time"
require "tty/table"

module HCPPacker
  module CLI
    class ListBuckets < Dry::CLI::Command
      desc "List buckets (images)"

      option :json, type: :boolean, default: false, desc: "Output JSON"

      def call(json:)

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

        buckets = JSON.parse(res.body).fetch("buckets")

        if json
          puts JSON.dump(buckets)
          return
        end

        cols2data = [
          {
            name: "Image ID",
            finder: -> { "#{_1.fetch("slug")} [#{_1.fetch("id")}]" }
          },
          {
            name: "Latest Iteration",
            finder: -> { _1.fetch("latest_version") }
          },
          # {
          #   name: "Status",
          #   finder: -> { _1.dig("???") }
          # },
          # {
          #   name: "Parents",
          #   finder: -> { _1.dig("parents") || "-" }
          # }
          {
            name: "Platforms",
            finder: -> { 
              _1.dig("platforms").
                tap { |arr| arr << "-" if arr.empty? }.
                join(", ")
            }
          },
          {
            name: "Updated At",
            finder: -> { Time.parse(_1.fetch("updated_at")).to_s }
          },
        ]

        table = TTY::Table.new(header: cols2data.map { |d| d[:name] })

        buckets.each do |data|
          table << cols2data.map { |d| d[:finder].call(data) }
        end

        puts table.render(:unicode, padding: [0, 1, 0, 1])
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
