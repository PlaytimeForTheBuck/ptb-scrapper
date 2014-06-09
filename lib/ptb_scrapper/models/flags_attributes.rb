module PtbScrapper
  module Models
    module FlagsAttributes
      def flags_attribute(attr_name, flags_attr_name, flags_list = nil)
        flags_list = flags_list || const_get(attr_name.to_s.upcase + '_FLAGS')

        define_method attr_name do
          flags = read_attribute flags_attr_name
          flags_list.each_pair.inject([]){|all, v| (flags & v[1] != 0) ? (all << v[0]) : all}
        end

        define_method "#{attr_name}=" do |symbol_flags|
          write_attribute flags_attr_name, symbol_flags.map{|f| flags_list[f]}.compact.reduce(:|) || 0
        end
      end
    end
  end
end