module PtbScrapper
  module Scrappers
    class NoServerConnection < StandardError; end
    class InvalidHTML < StandardError; end
    class InvalidGame < StandardError; end
    class InvalidReview < StandardError; end
    class TooManyRedirects < StandardError; end
    class UnexpectedResponse < StandardError; end
  end
end