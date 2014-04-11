class Array
  # Returns false if any element of the array is not a number
  def all_numeric?
    self.each do |value|
      if not value.kind_of? Numeric
        return false
      end
    end
    return true
  end 

  # Returns the amount of elements there are in the array
  # that fall under the centile. Centile = 1-5
  def centile(centile)
    return 0 if centile > 5 or centile < 1
    return 0 if self.empty?

    max  = self.max
    min  = self.min
    size = (max - min) / 5.0

    # If everyone is in the same percentile,
    # let's just say is the one in the middle
    if min == max
      if centile == 3
        return self.size
      else
        return 0
      end
    end

    lower_limit = min + size * (centile-1)
    upper_limit = min + size * centile

    self.reject do |val|
      is_upper_value = (val == upper_limit and centile == 5)
      not (val >= lower_limit and (val < upper_limit or is_upper_value))
    end.size
  end
end