module MerbMonkey
  module Constants
    RE_DIGITS = /^\d+\.?\d*$/.freeze
    RE_OPERATORS = /^(>=|<=|>|<|not\s+)/.freeze
    RE_TRUE = /^true$/i.freeze
    RE_FALSE = /^false$/i.freeze
    OPERATORS = %w(gte lte gt lt not).freeze
    PASSED = %w(>= <= > < not).freeze
  end
end