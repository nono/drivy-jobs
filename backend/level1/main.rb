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
      (end_date - start_date).to_i + 1
    end

    def price
      price_time + price_distance
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
