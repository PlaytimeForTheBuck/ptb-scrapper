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

  def scrap(&block)
    concurrent = 10
    slices_sizes = (scrapping_groups.size / concurrent + 1).floor

    concurrent_scrapping_groups = scrapping_groups.each_slice(slices_sizes)

    threads = []

    data_to_be_saved = []

    concurrent_scrapping_groups.each do |concurrent_scrapping_group|
      thread = Thread.new do
        concurrent_scrapping_group.each do |group|
          index = 0
          group_data = nil

          finish = false
          doc = nil
          while not finish
            url = get_url(doc, index, group)

            @last_page = index
            @last_page_url = url

            finish = true if not url
            if not finish
              begin
                uri = URI url
                request = Net::HTTP::Get.new(uri)
                request.add_field 'Cookie', 'birthtime=724320001'
                res = Net::HTTP.new(uri.host, uri.port).start do |http|
                  http.request(request)
                end
                raw_page = res.body
                doc = Nokogiri::HTML raw_page
              rescue
                raise NoServerConnection, index
              end

              finish = ! keep_scrapping_before?(doc)
              if not finish
                group_data = parse_page(doc, group, group_data, &block)
                save_data(group_data, group, &block)

                finish = ! keep_scrapping_after?(doc, group_data)
                if not finish
                  index += 1
                end
              end
            end
          end

          save_group_data(group_data, group, &block)
        end
        ActiveRecord::Base.connection.close
      end

      threads.push thread
    end

    threads.each(&:join)
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