class AddGeolocationToAddresses < ActiveRecord::Migration[8.1]
  def change
    add_column :addresses, :latitude, :decimal, precision: 10, scale: 8
    add_column :addresses, :longitude, :decimal, precision: 11, scale: 8
    add_column :addresses, :geocoded_at, :datetime
    add_column :addresses, :geocode_source, :string
  end
end
