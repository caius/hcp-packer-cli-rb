# frozen_string_literal: true

require "time"
require "tty/table"

module HCPPacker
  module CLI
    class ListBuckets < Dry::CLI::Command
      desc "List buckets (images)"

      option :json, type: :boolean, default: false, desc: "Output JSON"

      def call(json:)
        client = HCPPacker::Client.new
        data = client.get("/images")
        buckets = data.fetch("buckets")

        if json
          puts JSON.dump(buckets)
          return
        end

        cols2data = [
          {
            name: "Image ID",
            finder: -> { _1.fetch("slug") }
          },
          {
            name: "Latest Iteration",
            finder: -> {
              version = _1.fetch("latest_version")
              if version.zero?
                "Incomplete"
              else
                "#{version} (#{_1.dig("latest_iteration", "fingerprint")[0..8]})"
              end
            }
          },
          {
            name: "Status",
            finder: -> {
              statuses = _1.dig("latest_iteration", "builds").map { |b| b["status"].downcase }.flatten.sort.uniq
              if statuses == %w[done]
                "Active"
              else
                "Failed"
              end
            }
          },
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
    end
  end
end
