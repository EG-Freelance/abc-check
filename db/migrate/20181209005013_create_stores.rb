class CreateStores < ActiveRecord::Migration
  def change
    create_table :stores do |t|
      t.integer :store_id
      t.string :city
      t.string :address
      t.string :lat
      t.string :long
      t.string :phone

      t.timestamps null: false
    end
  end
end
