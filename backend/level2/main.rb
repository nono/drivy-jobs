require "json"
require "date"

class Drivy
  def initialize(json)
    data     = JSON.parse json
    @cars    = data['cars'].map { |c| Car.build(c) }
    @rentals = data['rentals'].map { |r| Rental.build(r, @cars) }
  end

  def to_json
    JSON.generate rentals: @rentals.map(&:as_json)
  end

  Car = Struct.new(:car_id, :price_per_day, :price_per_km) do
    def self.build(data)
      new data['id'], data['price_per_day'], data['price_per_km']
    end
  end

  Rental = Struct.new(:rental_id, :car, :start_date, :end_date, :distance) do
    def self.build(data, cars)
      car = cars.find { |c| c.car_id == data['car_id'] }
      new data['id'],
          car,
          Date.parse(data['start_date']),
          Date.parse(data['end_date']),
          data['distance']
    end

    def duration
      (start_date..end_date).map.with_index do |_, index|
        case index
        when 0    then 1
        when 1..3 then 0.9
        when 4..9 then 0.7
        else 0.5
        end
      end.inject(0, :+)
    end

    def price
      (price_time + price_distance).to_i
    end

    def price_time
      duration * car.price_per_day
    end

    def price_distance
      distance * car.price_per_km
    end

    def as_json
      {
        id: rental_id,
        price: price,
      }
    end
  end
end

puts Drivy.new(ARGF.read).to_json
