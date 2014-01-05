require 'time'
require 'bigdecimal'
require 'csv'

class Statement
  attr_reader :time, :action, :txid, :amount, :price, :link

  def initialize(values)
    if values.is_a?(CSV::Row) || values.is_a?(Array)
      load_csv(values)
    elsif values.is_a?(Hash)
      load_json(values)
    else
      raise "unknown values of #{values.class.name}"
    end
  end

  def load_csv(row)
    #@id = row[0]
    @time = Time.parse(row[1])
    @action = row[2]
    info = row[3]
    detail = info_parse(@action, info)
    @amount = detail[:amount]
    @price = detail[:price]
    @txid = detail[:tid]
    #@value = BigDecimal.new(row[4])
    #@balance = BigDecimal.new(row[5])
  end

  def load_json(json)
    @time = json[:time].is_a?(Time) ? json[:time] : Time.parse(json[:time])
    @amount = BigDecimal.new(json[:amount])
    @price = BigDecimal.new(json[:price])
  end

  def info_parse(action, info)
    case action
    when "earned", "spent"
      buysell_info_parse(info)
    end
  end

  def buysell_info_parse(info)
    #"BTC sold: [tid:1362024956429632] 1.20000000 BTC at $32.13310"
    info_match = /(\w+) (bought|sold): \[tid:(\d+)\] (\d+\.\d+).(\w+) at \$((\d+,)?\d+\.\d+)/
    matches = info_match.match(info)
    {currency: matches[1], buysell: matches[2], tid: matches[3],
     amount: BigDecimal.new(matches[4]), price: BigDecimal.new(matches[6])}
  end

  def amount=(new_amount)
    @amount = new_amount
  end

  def value
    @amount * @price
  end

  def ==(s)
    time == s.time && amount == s.amount && price == s.price
  end

  def value_display
    "%9.4f" % @value.to_f
  end
end
