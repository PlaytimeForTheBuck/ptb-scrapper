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
end