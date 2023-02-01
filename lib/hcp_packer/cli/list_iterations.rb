# frozen_string_literal: true

module HCPPacker
  module CLI
    class ListIterations < Dry::CLI::Command
      desc "List iterations for a bucket"

      argument :bucket_name, type: :string, required: true, desc: "Bucket Name"

      option :json, type: :boolean, default: false, desc: "Output JSON"

      def call(bucket_name:, json:)

        url = URI("https://api.cloud.hashicorp.com/packer/2021-04-30/organizations/#{ENV["HCP_ORGANIZATION_ID"]}/projects/#{ENV["HCP_PROJECT_ID"]}/images/#{bucket_name}/iterations")

        res = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          req = Net::HTTP::Get.new(url)
          req["Authorization"] = "Bearer #{access_token}"
          req["Content-Type"] = "application/json"
          http.request(req)
        end

        unless res.is_a?(Net::HTTPSuccess)
          raise "Error making request #{res.body.inspect}"
        end

        iterations = JSON.parse(res.body).fetch("iterations")

        if json
          puts JSON.dump(iterations)
          return
        end

        # Grab channels for that column

        channel_url = URI("https://api.cloud.hashicorp.com/packer/2021-04-30/organizations/#{ENV["HCP_ORGANIZATION_ID"]}/projects/#{ENV["HCP_PROJECT_ID"]}/images/#{bucket_name}/channels")

        channel_res = Net::HTTP.start(channel_url.host, channel_url.port, use_ssl: true) do |http|
          req = Net::HTTP::Get.new(channel_url)
          req["Authorization"] = "Bearer #{access_token}"
          req["Content-Type"] = "application/json"
          http.request(req)
        end

        unless channel_res.is_a?(Net::HTTPSuccess)
          raise "Error making request #{channel_res.body.inspect}"
        end

        channels = JSON.parse(channel_res.body).fetch("channels")

        # Show the data

        cols2data = [
          {
            name: "Iteration",
            finder: -> {
              version = _1.fetch("incremental_version")
              if version.zero?
                "Incomplete"
              else
                "#{version} (#{_1.fetch("fingerprint")[0..8]})"
              end
            }
          },
          {
            name: "Build Statuses",
            finder: -> {
              statuses = _1.fetch("build_statuses").map { |n| n.last.downcase }.flatten.sort.uniq
              statuses == %w[done] ? "Active" : "Failed"
            }
          },
          {
            name: "Channels",
            finder: -> {
              fingerprint = _1.dig("fingerprint")
              channels = channels.select { |c| c.dig("pointer", "iteration", "fingerprint") == fingerprint }
              channels.map { |c| c.dig("slug") }.join(", ")
            }
          },
          {
            name: "Published At",
            finder: -> { Time.parse(_1.fetch("updated_at")).strftime("%Y-%m-%d %H:%M:%S") }
          }
        ]

        table = TTY::Table.new(header: cols2data.map { |d| d[:name] })

        iterations.each do |data|
          table << cols2data.map { |d| d[:finder].call(data) }
        end

        puts "Bucket: #{iterations.first.dig("bucket_slug")}"
        puts table.render(:unicode, padding: [0, 1, 0, 1])
      end

      def access_token
        HCPPacker.config[:auth]["access_token"]
      end

    end
  end
end
