class Tax
  attr_reader :time, :type, :value

  def initialize(attrs)
    @time = attrs[:time].is_a?(Time) ? attrs[:time] : Time.parse(attrs[:time])
    @type = attrs[:type]
    @value = attrs[:value]
  end

  def ==(tix)
    @time == tix.time && @type == tix.type && @value == tix.value
  end
end