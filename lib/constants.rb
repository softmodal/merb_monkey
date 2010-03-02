module MerbMonkey
  module Constants
    RE_DIGITS = /^\d+\.?\d*$/.freeze
    RE_OPERATORS = /^(>=|<=|>|<|not\s+)/.freeze
    RE_TRUE = /^true$/i.freeze
    RE_FALSE = /^false$/i.freeze
    RE_DATE = /\d{4}\-\d{2}\-\d{2}/.freeze
    OPERATORS = %w(gte lte gt lt not).freeze
    PASSED = %w(>= <= > < not).freeze
  end
end