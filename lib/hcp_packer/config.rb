# frozen_string_literal: true

require "pathname"
require "pstore"

module HCPPacker
  class Config

    def initialize
      @store = PStore.new(config_path)
    end

    def [](name)
      @store.transaction(true) do
        @store[name]
      end
    end

    def []=(name, value)
      @store.transaction do
        @store[name] = value
      end
    end

    private

    def config_path
      dir = Pathname.new(ENV["HOME"]).join(".config", "hcp-packer-cli").expand_path
      unless dir.exist?
        dir.mkpath
      end
      dir.join("config.pstore")
    end
  end
end
