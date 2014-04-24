class Scrapper
  attr_reader :games

  class NoServerConnection < StandardError; end
  class InvalidHTML < StandardError; end
  class InvalidGame < StandardError; end
  class InvalidReview < StandardError; end
end