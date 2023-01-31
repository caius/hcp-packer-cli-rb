# frozen_string_literal: true

require "json"
require "net/http"
require "time"
require "tty/table"

module HCPPacker
  module CLI
    class ListChannels < Dry::CLI::Command
      desc "List channels for bucket"

      argument :bucket_name, type: :string, required: true, desc: "Bucket Name"

      option :json, type: :boolean, default: false, desc: "Output JSON"

      def call(bucket_name:, json:)

        url = URI("https://api.cloud.hashicorp.com/packer/2021-04-30/organizations/#{ENV["HCP_ORGANIZATION_ID"]}/projects/#{ENV["HCP_PROJECT_ID"]}/images/#{bucket_name}/channels")

        res = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          req = Net::HTTP::Get.new(url)
          req["Authorization"] = "Bearer #{access_token}"
          req["Content-Type"] = "application/json"
          http.request(req)
        end

        unless res.is_a?(Net::HTTPSuccess)
          raise "Error making request #{res.body.inspect}"
        end

        channels = JSON.parse(res.body).fetch("channels")

        if json
          puts JSON.dump(channels)
          return
        end

        cols2data = [
          {
            name: "Channel",
            finder: -> { "#{_1.fetch("slug")} [#{_1.fetch("id")}]" }
          },
          {
            name: "Active Iteration",
            finder: -> {
              iteration = _1.dig("pointer", "iteration")
              version = iteration.dig("incremental_version")
              fingerprint = iteration.dig("fingerprint")[0..8]
              "#{version} (#{fingerprint})"
            }
          },
          {
            name: "Assigned",
            finder: -> { 
              pointer = _1.dig("pointer")
              assigned_at = Time.parse(pointer.dig("created_at"))
              author = pointer.dig("author_id")
              "#{assigned_at.strftime("%Y-%m-%d %H:%M:%s")} by #{author}"
            }
          },
        ]

        table = TTY::Table.new(header: cols2data.map { |d| d[:name] })

        channels.each do |data|
          table << cols2data.map { |d| d[:finder].call(data) }
        end

        puts table.render(:unicode, padding: [0, 1, 0, 1])
      end

      def access_token
        HCPPacker.config[:auth]["access_token"]
      end
    end
  end
end
