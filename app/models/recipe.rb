class Recipe < ActiveRecord::Base
  serialize :ingredients, JSON
  serialize :preparation_steps, JSON

  def self.from_json(json)
    self.new JSON.parse(json)
  end

  def normalized_ingredients
    return ingredients unless ingredients.first.is_a? Hash

    # The older schema deconstructed ingredients a bit more.
    ingredients.map do |i|
      i.slice('quantity', 'unit', 'name')
       .select { |_k, v| v.present? }
       .values
       .join(' ')
    end
  end
end
