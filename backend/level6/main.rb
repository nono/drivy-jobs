require "json"
require "date"

class Drivy
  def initialize(json)
    data     = JSON.parse json
    @cars    = data['cars'].map { |c| Car.build(c) }
    @rentals = data['rentals'].map { |r| Rental.build(r, @cars) }
    @modifs  = data['rental_modifications'].map { |m| Modification.build(m, @rentals) }
  end

  def to_json
    JSON.generate rental_modifications: @modifs.map(&:as_json)
  end

  Car = Struct.new(:car_id, :price_per_day, :price_per_km) do
    def self.build(data)
      new data['id'], data['price_per_day'], data['price_per_km']
    end
  end

  Modification = Struct.new(:modification_id, :before, :after) do
    def self.build(data, rentals)
      before = rentals.find { |r| r.rental_id == data['rental_id'] }
      after = before.dup
      after.start_date = Date.parse(data['start_date']) if data['start_date']
      after.end_date   = Date.parse(data['end_date'])   if data['end_date']
      after.distance   = data['distance']               if data['distance']
      new data['id'], before, after
    end

    def rental_id
      after.rental_id
    end

    def actions
      %w(driver owner insurance assistance drivy).map do |who|
        type = "credit"
        amount = after.send("amount_for_#{who}") - before.send("amount_for_#{who}")
        if amount < 0
          amount = -amount
          type = "debit"
        end
        {
          who: who,
          type: type,
          amount: amount,
        }
      end
    end

    def as_json
      {
        id: modification_id,
        rental_id: rental_id,
        actions: actions,
      }
    end
  end

  Rental = Struct.new(:rental_id, :car, :start_date, :end_date, :distance, :deductible) do
    def self.build(data, cars)
      car = cars.find { |c| c.car_id == data['car_id'] }
      new data['id'],
          car,
          Date.parse(data['start_date']),
          Date.parse(data['end_date']),
          data['distance'],
          data['deductible_reduction']
    end

    def nb_days
      (end_date - start_date).to_i + 1
    end

    def weighted_duration
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
      weighted_duration * car.price_per_day
    end

    def price_distance
      distance * car.price_per_km
    end

    def commission
      price * 0.3
    end

    def insurance_fee
      (commission * 0.5).to_i
    end

    def assistance_fee
      nb_days * 100
    end

    def drivy_fee
      (commission - insurance_fee - assistance_fee).to_i
    end

    def deductible_reduction
      return 0 unless deductible
      nb_days * 400
    end

    def amount_for_driver
      -(price + deductible_reduction)
    end

    def amount_for_owner
      price - commission
    end

    def amount_for_insurance
      insurance_fee
    end

    def amount_for_assistance
      assistance_fee
    end

    def amount_for_drivy
      drivy_fee + deductible_reduction
    end
  end
end

puts Drivy.new(ARGF.read).to_json
