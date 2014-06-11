module PtbScrapper
  module Scrappers
    class NoServerConnection < StandardError; end
    class InvalidGame < StandardError; end
    class InvalidReview < StandardError; end
    class TooManyRedirects < StandardError; end
    class UnexpectedResponse < StandardError; end

    class InvalidHTML < StandardError
      attr_reader :url, :html

      def initialize(message = '', url = '', html = '')
        @url = url
        @html = html
        super message
      end
    end
  end
end