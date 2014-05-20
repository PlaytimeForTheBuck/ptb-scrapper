require 'net/http'
require 'nokogiri'

class Scrapper
  attr_reader :subjects, :index, :group_index, :games, :last_page, :last_page_url, :group_data

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
  end

  def scrap
    scrapping_groups.each_index do |i|
      @group_index = i
      @index = 0
      group = scrapping_groups[@group_index]
      group_data = nil

      finish = false
      doc = nil
      while not finish
        url = get_url(doc, @index, @group_index)

        @last_page = @index
        @last_page_url = url

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
            group_data = parse_page(doc, group, group_data)
            yield group, group_data, index if block_given?
            save_data(group_data, group)

            finish = ! keep_scrapping_after?(doc)
            if not finish
              @index += 1
            end
          end
        end
      end

      save_group_data(group_data, group)
    end
    
  end

  private

  # Abstract
  # @returns Parsed data hash
  def parse_page(doc)
    raise 'parse_page method missing'
  end

  # Probably abstract
  # @param parsed_data: Hash returned by #parse_page
  # @param group: Current group scrapped
  def save_data(parsed_data, group)

  end

  # Probably abstract
  # @param group_data: Hash returned by #parse_page
  # @param group: Current group scrapped
  def save_group_data(group_data, group)

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

  def scrapping_groups
    [subjects]
  end

  def get_by_id(id)
    @subjects_by_id[Integer id]
  end

  def add_subject(subject)
   @subjects.push subject
   @subjects_by_id[subject.id] = subject
  end
end