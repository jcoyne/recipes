class Recipe < ActiveRecord::Base
  serialize :ingredients, JSON
  serialize :preparation_steps, JSON

  def self.from_json(json)
    self.new JSON.parse(json)
  end
end
