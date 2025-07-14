class CreateSeeds < ActiveRecord::Migration[7.2]
  def change
    create_table :seeds do |t|
      t.string :name
      t.string :scientific_name
      t.string :family
      t.text :description
      t.text :nutritional_benefits
      t.text :medicinal_benefits
      t.text :error
      t.integer :quality, default: 2 
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
