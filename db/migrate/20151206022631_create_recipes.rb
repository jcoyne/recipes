class CreateRecipes < ActiveRecord::Migration
  def change
    create_table :recipes do |t|
      t.string :link
      t.string :title, :thumbnail, :servings
      t.text :ingredients, :preparation_steps

      t.timestamps null: false
    end

    add_index :recipes, :link, unique: true
  end
end
