require 'net/http'
require 'nokogiri'

module PtbScrapper
  module Scrappers
    class Scrapper
      include Logger
      attr_reader :subjects, :index, :group_index, :games, :last_page, :last_page_url, :group_data

      def initialize(subjects, subjects_class)
        @to_save = []
        @subjects = subjects
        @subjects_class = subjects_class
        @subjects_by_id = {}
        @subjects.each do |subject|
          @subjects_by_id[subject.id] = subject
        end
      end

      def scrap(autosave = false, concurrency = 5, &block)
        @autosave = autosave
        slices_sizes = (scrapping_groups.size / concurrency + 1).floor

        concurrent_scrapping_groups = scrapping_groups.each_slice(slices_sizes)
        threads = []

        Thread.abort_on_exception = true
        begin
          concurrent_scrapping_groups.each do |concurrent_scrapping_group|
            thread = create_scrapping_thread(concurrent_scrapping_group, &block)
            threads.push thread
          end
        rescue NoServerConnection => e
          # Restart the thread?
          raise NoServerConnection
        end

        # Thread.abort_on_exception = true

        # concurrent_scrapping_groups.each do |concurrent_scrapping_group|

        if @autosave
          while threads.map(&:alive?).any?
            sleep 3
            save_from_queue
          end
          save_from_queue
        end

        # threads.join

          #   ActiveRecord::Base.clear_active_connections!
          # end

        #   threads.push thread
        # end

        threads.each(&:join)
      end

      def queue_save(subject)
        @to_save.push subject
      end

      def save_from_queue
        begin
          while @to_save.size > 0
            @to_save.first.save!
            @to_save.shift
          end
        rescue ActiveRecord::StatementInvalid => e
          # I run this thing on a virtual machine
          # and SQLite is on a network folder
          # so it's really unstable. So we just try again.
          sleep 0.25
          save_from_queue
        end
      end

      def create_scrapping_thread(concurrent_scrapping_group, &block)
        Thread.new do
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
                raw_page = get_page(url)
                doc = Nokogiri::HTML raw_page

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
            ActiveRecord::Base.clear_active_connections!
          end
        end
      end

      private

      def get_page(url, redirectLimit = 10, retriesLimit = 10)
        raise TooManyRedirects if redirectLimit == 0
        raise NoServerConnection if retriesLimit == 0

        begin
          uri = URI url
          request = Net::HTTP::Get.new(uri)
          request.add_field 'Cookie', 'birthtime=724320001'
          response = Net::HTTP.new(uri.host, uri.port).start do |http|
            http.request(request)
          end
        rescue Errno::ETIMEDOUT, Timeout::Error => e
          logger.warn e.class.inspect
          seconds = 10 + (10 - retriesLimit)*3
          logger.warn 'NO SERVER CONNECTION! Retrying in 10 seconds'
          sleep seconds if PtbScrapper.env != 'test'
          return get_page(url, redirectLimit, retriesLimit - 1)
        end

        case response
        when Net::HTTPSuccess then response.body
        when Net::HTTPRedirection then get_page(response['location'], redirectLimit - 1, retriesLimit)
        else
          raise UnexpectedResponse
        end
      end

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
      def keep_scrapping_after?(doc, group_data)
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
  end
end