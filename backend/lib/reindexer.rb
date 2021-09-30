require 'uri'
require 'net/http'

module ArchivesSpace
  module Reindexer
    class File
      def initialize(data_directory:)
        @data_directory = data_directory
        self
      end

      def run
        indexer_files_path = ::File.join(@data_directory, "indexer*state", "*")
        FileUtils.rm Dir.glob(indexer_files_path)
      end
    end

    class Solr
      MAX_WAIT_ATTEMPTS = 120

      def initialize(solr_url:)
        @ran = false
        @solr_url = solr_url
        self
      end

      def count
        uri = URI("#{@solr_url}/select")
        uri.query = URI.encode_www_form({ q: '*:*' })
        res = Net::HTTP.get_response(uri)
        raise 'Error getting Solr index count' unless res.is_a?(Net::HTTPSuccess)

        JSON.parse(res.body)["response"]["numFound"].to_i
      end

      def ran?
        @ran
      end

      def run
        uri = URI.parse("#{@solr_url}/update?commit=true")
        http = Net::HTTP.new(uri.host, uri.port)
        request = prepare_request(uri: uri)
        res = http.request(request)
        raise "Error reindexing Solr: #{res.body}" unless res.is_a?(Net::HTTPSuccess)

        @ran = true
      end

      private

      def prepare_request(uri:)
        request = Net::HTTP::Post.new(uri.request_uri)
        request["Accept"] = "application/json"
        request.content_type = "application/json"
        request.body = { delete: { query: '*:*' } }.to_json
        request
      end
    end

    def self.run
      solr_reindexer = ArchivesSpace::Reindexer::Solr.new(
        solr_url: AppConfig[:solr_url]
      )

      total   = solr_reindexer.count
      attempt = 1
      puts "Deleting Solr documents: #{total}" unless total.zero?

      while total.positive? && !solr_reindexer.count.zero?

        solr_reindexer.run unless solr_reindexer.ran?

        if attempt == ArchivesSpace::Reindexer::Solr::MAX_WAIT_ATTEMPTS
          raise "Max attempts to wait on Solr reset exceeded, aborting mission"
        end

        puts "Waiting on Solr to confirm no documents found in index"
        sleep 1
        attempt += 1
      end

      puts "Solr reset complete, now deleting ArchivesSpace indexer data files"
      ArchivesSpace::Reindexer::File.new(
        data_directory: AppConfig[:data_directory],
      ).run
      puts "ArchivesSpace indexer data files deleted, reindexing should begin soon"
    end
  end
end
