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
        client = HCPPacker::Client.new
        data = client.get("/images/#{bucket_name}/channels")
        channels = data.fetch("channels")

        if json
          puts JSON.dump(channels)
          return
        end

        cols2data = [
          {
            name: "Channel",
            finder: -> { _1.fetch("slug") }
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
            name: "Assigned By",
            finder: -> { _1.dig("pointer", "author_id") }
          },
          {
            name: "Assigned At",
            finder: -> { 
              pointer = _1.dig("pointer")
              assigned_at = Time.parse(pointer.dig("created_at"))
              assigned_at.strftime("%Y-%m-%d %H:%M:%S")
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
