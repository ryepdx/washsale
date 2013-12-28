require 'time'
require 'bigdecimal'

class Statement
  attr_reader :time, :action, :value, :balance, :detail

  def initialize(values)
    load_csv(values) if values.is_a?(CSV::Row)
    load_json(values) if values.is_a?(Hash)
  end

  def load_csv(row)
    @id = row[0]
    @time = Time.parse(row[1])
    @action = row[2]
    @info = row[3]
    @detail = info_parse(@action, @info)
    @value = BigDecimal.new(row[4])
    @balance = BigDecimal.new(row[5])
  end

  def load_json(json)
    @time = Time.parse(json["time"])
    @detail = {}
    @detail[:amount] = BigDecimal.new(json["amount"])
    @detail[:price] = BigDecimal.new(json["price"])
    @value = amount * price
  end

  def info_parse(action, info)
    #"BTC sold: [tid:1362024956429632] 1.20000000 BTC at $32.13310"
    case action
    when "earned", "spent"
      earned_info_parse(info)
    end
  end

  def earned_info_parse(info)
    info_match = /(\w+) (bought|sold): \[tid:(\d+)\] (\d+\.\d+).(\w+) at \$((\d+,)?\d+\.\d+)/
    matches = info_match.match(info)
    {currency: matches[1], buysell: matches[2], tid: matches[3],
     amount: matches[4], price: matches[6]}
  end

  def amount
    @detail[:amount]
  end

  def price
    @detail[:price]
  end

  def value_display
    "%9.4f" % @value.to_f
  end
end
