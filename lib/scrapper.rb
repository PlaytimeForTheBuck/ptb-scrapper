require 'net/http'
require 'nokogiri'

class Scrapper
  attr_reader :subjects, :index, :games

  class NoServerConnection < StandardError; end
  class InvalidHTML < StandardError; end
  class InvalidGame < StandardError; end
  class InvalidReview < StandardError; end

  def initialize(subjects)
    @subjects = subjects
    @subjects_by_id = {}
    @subjects.each do |subject|
      @subjects_by_id[subject.id] = subject
    end

    @index = 0
  end

  def scrap
    finish = false
    doc = nil
    while not finish
      url = get_url(doc, @index)
      finish = true if not url
      if not finish
        begin
          raw_page = Net::HTTP.get(URI url)
          doc = Nokogiri::HTML raw_page
        rescue
          raise NoServerConnection, @index
        end

        finish = ! keep_scrapping_before?(doc)
        if not finish
          parsed_data = parse_page(doc)
          yield parsed_data if block_given?
          save_data(parsed_data)

          finish = ! keep_scrapping_after?(doc)
          if not finish
            @index += 1
          end
        end
      end
    end
    
  end

  # Abstract
  # @returns Parsed data hash
  def parse_page(doc)
    raise 'parse_page method missing'
  end

  # Probably abstract
  # @param parsed_data: Hash returned by #parse_page
  def save_data(parsed_data)

  end

  # Abstract
  # @returns String|false: Returns the next URL or false if no more URLs
  def get_url(doc, index)
    raise 'get_next_url method missing'
  end

  # @param doc: Nokogiri doc
  def keep_scrapping_before?(doc)
    not doc.root.nil?
  end

  # @param doc: Nokogiri doc
  def keep_scrapping_after?(doc)
    true
  end

  private

  def get_by_id(id)
    @subjects_by_id[Integer id]
  end

  def add_subject(subject)
   @subjects.push subject
   @subjects_by_id[subject.id] = subject
  end
end