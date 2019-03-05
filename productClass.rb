class Products
  attr_accessor :name, :cost, :image_source, :showInfo

  def initialize(name, cost, image_source)
    @name = name
    @cost = cost
    @image_source = image_source
  end

  def showInfo
    puts "Найден продукт #{@name} со стоимостью #{@cost}"
  end
end

