require 'time'
require 'bigdecimal'
require 'csv'

class Statement
  attr_reader :time, :action, :txid, :amount, :price, :link
  attr_accessor :reduced

  def initialize(values)
    @reduced = 0
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
    if detail
      @amount = detail[:amount]
      @price = detail[:price]
      @txid = detail[:txid]
    end
  end

  def load_json(json)
    @time = json[:time].is_a?(Time) ? json[:time] : Time.parse(json[:time])
    @amount = BigDecimal.new(json[:amount])
    @price = BigDecimal.new(json[:price])
    @reduced = json[:reduced] if json[:reduced]
    @txid = json[:txid]
    @link = json[:link]
  end

  def info_parse(action, info)
    case action
    when "earned", "spent"
      buysell_info_parse(info)
    end
  end

  def buysell_info_parse(info)
    #"BTC sold: [tid:1362024956429632] 1.20000000 BTC at $32.13310"
    info_match = /(\w+) (bought|sold): \[tid:(\d+)\] (\d+\.\d+).(\w+) at \$((\d+,)*\d+\.\d+)/
    matches = info_match.match(info)
    price = matches[6].gsub(',','')
    {currency: matches[1], buysell: matches[2], txid: matches[3],
     amount: BigDecimal.new(matches[4]), price: BigDecimal.new(price)}
  end

  def value
    reduced_amount * @price
  end

  def reduced_amount
    wa = @amount-@reduced
    raise "Negative reduced amount for #{this}" if wa < 0
    wa
  end

  def original_value
    @amount * @price
  end

  def ==(s)
    time == s.time && amount == s.amount && price == s.price && reduced == s.reduced
  end

  def value_display
    "%9.4f" % @value.to_f
  end

  def inspect
    if time.year == Time.now.year
      date = time.strftime("%b-%d")
    else
      date = time.strftime("%Y-%b-%d")
    end

    "#{date} #{action} #{"%0.5f"%amount.to_f} (#{"%0.5f"%reduced.to_f}) @#{"%0.3f"%price.to_f} = #{"%0.3f"%value} orig:#{"%0.3f"%original_value} ##{txid}"
  end
end
