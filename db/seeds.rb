# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require 'finnhub_ruby'
require 'net/http'
require 'json'

unless Rails.env.test?
  # Seeds the Countries table
  puts "Seeding country data from Finnhub..."
  ActiveRecord::Base.transaction do
    begin
      countries_data = nil
      FinnhubClient.try_request do |client|
        countries_data = client.country
      end

      puts "Populating countries table"
      countries_data.each do |country_data|
        country_code = country_data['code2']
        Country.find_or_create_by!(code: country_code) do |country|
          country.name = country_data['country']
          puts "Seeded country: #{country.name} (#{country.code})"
        end
      end
      puts "Countries table populated successfully."

    rescue StandardError => e
      if e.class.to_s == 'FinnhubRuby::ApiError'
        puts "Finnhub API Error: #{e.message}. Rolling back country creations."
      else
        puts "Failed to fetch country data. Aborting seed. Error: #{e.message}"
      end
      raise ActiveRecord::Rollback

    rescue => e
      puts "Error: #{e.message}"
      raise ActiveRecord::Rollback
    end
  end

  # Seeds the Producers table
  puts "Seeding Producers table..."
  addresses = [
    { unit_no: "2020", street_no: "26th Ave", barangay: "Bagumbayan", city: "Taguig", zipcode: "1244", country_id: "102" },
    { unit_no: "0110", street_no: "9th Roxas", barangay: "San Isidro", city: "Quezon", zipcode: "1499", country_id: "102" },
    { unit_no: "1430", street_no: "8th Cucumber", barangay: "Poblacion", city: "Metro Manila", zipcode: "1011", country_id: "102" },
    { unit_no: "310", street_no: "15th Centre", barangay: "San Nicolas", city: "Cavite", zipcode: "1802", country_id: "102" }
  ]

  address_records = addresses.map do |attrs|
    Address.find_or_create_by!(attrs)
  end

  producers = [
    { title: "Nestle Inc.", address: address_records[0] },
    { title: "Amazonia LLC", address: address_records[1] },
    { title: "Appollonia Inc.", address: address_records[2] },
    { title: "Johnsons & Johnsons", address: address_records[3] }
  ]

  producers.each do |attrs|
    Producer.find_or_create_by!(title: attrs[:title]) do |producer|
      producer.address = attrs[:address]
    end
  end

  # Seeds the Categories table
  puts "Seeding Categories table..."
  [ "men's clothing", "women's clothing", "jewelery", "electronics" ].each do |cat_title|
    ProductCategory.find_or_create_by!(title: cat_title)
  end

  # Seeds the Products table
  puts "Seeding product data from static array..."

  products = [
    { "id"=>1, "title"=>"Fjallraven - Foldsack No. 1 Backpack, Fits 15 Laptops", "price"=>109.95, "description"=>"Your perfect pack for everyday use and walks in the forest. Stash your laptop (up to 15 inches) in the padded sleeve, your everyday", "category"=>"men's clothing", "image"=>"https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_t.png" },
    { "id"=>2, "title"=>"Mens Casual Premium Slim Fit T-Shirts ", "price"=>22.3, "description"=>"Slim-fitting style, contrast raglan long sleeve, three-button henley placket, light weight & soft fabric for breathable and comfortable wearing. And Solid stitched shirts with round neck made for durability and a great fit for casual fashion wear and diehard baseball fans. The Henley style round neckline includes a three-button placket.", "category"=>"men's clothing", "image"=>"https://fakestoreapi.com/img/71-3HjGNDUL._AC_SY879._SX._UX._SY._UY_t.png" },
    { "id"=>3, "title"=>"Mens Cotton Jacket", "price"=>55.99, "description"=>"great outerwear jackets for Spring/Autumn/Winter, suitable for many occasions, such as working, hiking, camping, mountain/rock climbing, cycling, traveling or other outdoors. Good gift choice for you or your family member. A warm hearted love to Father, husband or son in this thanksgiving or Christmas Day.", "category"=>"men's clothing", "image"=>"https://fakestoreapi.com/img/71li-ujtlUL._AC_UX679_t.png" },
    { "id"=>4, "title"=>"Mens Casual Slim Fit", "price"=>15.99, "description"=>"The color could be slightly different between on the screen and in practice. / Please note that body builds vary by person, therefore, detailed size information should be reviewed below on the product description.", "category"=>"men's clothing", "image"=>"https://fakestoreapi.com/img/71YXzeOuslL._AC_UY879_t.png" },
    { "id"=>5, "title"=>"John Hardy Women's Legends Naga Gold & Silver Dragon Station Chain Bracelet", "price"=>695, "description"=>"From our Legends Collection, the Naga was inspired by the mythical water dragon that protects the ocean's pearl. Wear facing inward to be bestowed with love and abundance, or outward for protection.", "category"=>"jewelery", "image"=>"https://fakestoreapi.com/img/71pWzhdJNwL._AC_UL640_QL65_ML3_t.png" },
    { "id"=>6, "title"=>"Solid Gold Petite Micropave ", "price"=>168, "description"=>"Satisfaction Guaranteed. Return or exchange any order within 30 days.Designed and sold by Hafeez Center in the United States. Satisfaction Guaranteed. Return or exchange any order within 30 days.", "category"=>"jewelery", "image"=>"https://fakestoreapi.com/img/61sbMiUnoGL._AC_UL640_QL65_ML3_t.png" },
    { "id"=>7, "title"=>"White Gold Plated Princess", "price"=>9.99, "description"=>"Classic Created Wedding Engagement Solitaire Diamond Promise Ring for Her. Gifts to spoil your love more for Engagement, Wedding, Anniversary, Valentine's Day...", "category"=>"jewelery", "image"=>"https://fakestoreapi.com/img/71YAIFU48IL._AC_UL640_QL65_ML3_t.png" },
    { "id"=>8, "title"=>"Pierced Owl Rose Gold Plated Stainless Steel Double", "price"=>10.99, "description"=>"Rose Gold Plated Double Flared Tunnel Plug Earrings. Made of 316L Stainless Steel", "category"=>"jewelery", "image"=>"https://fakestoreapi.com/img/51UDEzMJVpL._AC_UL640_QL65_ML3_t.png" },
    { "id"=>9, "title"=>"WD 2TB Elements Portable External Hard Drive - USB 3.0 ", "price"=>64, "description"=>"USB 3.0 and USB 2.0 Compatibility Fast data transfers Improve PC Performance High Capacity; Compatibility Formatted NTFS for Windows 10, Windows 8.1, Windows 7; Reformatting may be required for other operating systems; Compatibility may vary depending on user’s hardware configuration and operating system", "category"=>"electronics", "image"=>"https://fakestoreapi.com/img/61IBBVJvSDL._AC_SY879_t.png" },
    { "id"=>10, "title"=>"SanDisk SSD PLUS 1TB Internal SSD - SATA III 6 Gb/s", "price"=>109, "description"=>"Easy upgrade for faster boot up, shutdown, application load and response (As compared to 5400 RPM SATA 2.5” hard drive; Based on published specifications and internal benchmarking tests using PCMark vantage scores) Boosts burst write performance, making it ideal for typical PC workloads The perfect balance of performance and reliability Read/write speeds of up to 535MB/s/450MB/s (Based on internal testing; Performance may vary depending upon drive capacity, host device, OS and application.)", "category"=>"electronics", "image"=>"https://fakestoreapi.com/img/61U7T1koQqL._AC_SX679_t.png" },
    { "id"=>11, "title"=>"Silicon Power 256GB SSD 3D NAND A55 SLC Cache Performance Boost SATA III 2.5", "price"=>109, "description"=>"3D NAND flash are applied to deliver high transfer speeds Remarkable transfer speeds that enable faster bootup and improved overall system performance. The advanced SLC Cache Technology allows performance boost and longer lifespan 7mm slim design suitable for Ultrabooks and Ultra-slim notebooks. Supports TRIM command, Garbage Collection technology, RAID, and ECC (Error Checking & Correction) to provide the optimized performance and enhanced reliability.", "category"=>"electronics", "image"=>"https://fakestoreapi.com/img/71kWymZ+c+L._AC_SX679_t.png" },
    { "id"=>12, "title"=>"WD 4TB Gaming Drive Works with Playstation 4 Portable External Hard Drive", "price"=>114, "description"=>"Expand your PS4 gaming experience, Play anywhere Fast and easy, setup Sleek design with high capacity, 3-year manufacturer's limited warranty", "category"=>"electronics", "image"=>"https://fakestoreapi.com/img/61mtL65D4cL._AC_SX679_t.png" },
    { "id"=>13, "title"=>"Acer SB220Q bi 21.5 inches Full HD (1920 x 1080) IPS Ultra-Thin", "price"=>599, "description"=>"21. 5 inches Full HD (1920 x 1080) widescreen IPS display And Radeon free Sync technology. No compatibility for VESA Mount Refresh Rate: 75Hz - Using HDMI port Zero-frame design | ultra-thin | 4ms response time | IPS panel Aspect ratio - 16: 9. Color Supported - 16. 7 million colors. Brightness - 250 nit Tilt angle -5 degree to 15 degree. Horizontal viewing angle-178 degree. Vertical viewing angle-178 degree 75 hertz", "category"=>"electronics", "image"=>"https://fakestoreapi.com/img/81QpkIctqPL._AC_SX679_t.png" },
    { "id"=>14, "title"=>"Samsung 49-Inch CHG90 144Hz Curved Gaming Monitor (LC49HG90DMNXZA) – Super Ultrawide Screen QLED ", "price"=>999.99, "description"=>"49 INCH SUPER ULTRAWIDE 32:9 CURVED GAMING MONITOR with dual 27 inch screen side by side QUANTUM DOT (QLED) TECHNOLOGY, HDR support and factory calibration provides stunningly realistic and accurate color and contrast 144HZ HIGH REFRESH RATE and 1ms ultra fast response time work to eliminate motion blur, ghosting, and reduce input lag", "category"=>"electronics", "image"=>"https://fakestoreapi.com/img/81Zt42ioCgL._AC_SX679_t.png" },
    { "id"=>15, "title"=>"BIYLACLESEN Women's 3-in-1 Snowboard Jacket Winter Coats", "price"=>56.99, "description"=>"Note:The Jackets is US standard size, Please choose size as your usual wear Material: 100% Polyester; Detachable Liner Fabric: Warm Fleece. Detachable Functional Liner: Skin Friendly, Lightweigt and Warm.Stand Collar Liner jacket, keep you warm in cold weather. Zippered Pockets: 2 Zippered Hand Pockets, 2 Zippered Pockets on Chest (enough to keep cards or keys)and 1 Hidden Pocket Inside.Zippered Hand Pockets and Hidden Pocket keep your things secure. Humanized Design: Adjustable and Detachable Hood and Adjustable cuff to prevent the wind and water,for a comfortable fit. 3 in 1 Detachable Design provide more convenience, you can separate the coat and inner as needed, or wear it together. It is suitable for different season and help you adapt to different climates", "category"=>"women's clothing", "image"=>"https://fakestoreapi.com/img/51Y5NI-I5jL._AC_UX679_t.png" },
    { "id"=>16, "title"=>"Lock and Love Women's Removable Hooded Faux Leather Moto Biker Jacket", "price"=>29.95, "description"=>"100% POLYURETHANE(shell) 100% POLYESTER(lining) 75% POLYESTER 25% COTTON (SWEATER), Faux leather material for style and comfort / 2 pockets of front, 2-For-One Hooded denim style faux leather jacket, Button detail on waist / Detail stitching at sides, HAND WASH ONLY / DO NOT BLEACH / LINE DRY / DO NOT IRON", "category"=>"women's clothing", "image"=>"https://fakestoreapi.com/img/81XH0e8fefL._AC_UY879_t.png" },
    { "id"=>17, "title"=>"Rain Jacket Women Windbreaker Striped Climbing Raincoats", "price"=>39.99, "description"=>"Lightweight perfet for trip or casual wear---Long sleeve with hooded, adjustable drawstring waist design. Button and zipper front closure raincoat, fully stripes Lined and The Raincoat has 2 side pockets are a good size to hold all kinds of things, it covers the hips, and the hood is generous but doesn't overdo it.Attached Cotton Lined Hood with Adjustable Drawstrings give it a real styled look.", "category"=>"women's clothing", "image"=>"https://fakestoreapi.com/img/71HblAHs5xL._AC_UY879_-2t.png" },
    { "id"=>18, "title"=>"MBJ Women's Solid Short Sleeve Boat Neck V ", "price"=>9.85, "description"=>"95% RAYON 5% SPANDEX, Made in USA or Imported, Do Not Bleach, Lightweight fabric with great stretch for comfort, Ribbed on sleeves and neckline / Double stitching on bottom hem", "category"=>"women's clothing", "image"=>"https://fakestoreapi.com/img/71z3kpMAYsL._AC_UY879_t.png" },
    { "id"=>19, "title"=>"Opna Women's Short Sleeve Moisture", "price"=>7.95, "description"=>"100% Polyester, Machine wash, 100% cationic polyester interlock, Machine Wash & Pre Shrunk for a Great Fit, Lightweight, roomy and highly breathable with moisture wicking fabric which helps to keep moisture away, Soft Lightweight Fabric with comfortable V-neck collar and a slimmer fit, delivers a sleek, more feminine silhouette and Added Comfort", "category"=>"women's clothing", "image"=>"https://fakestoreapi.com/img/51eg55uWmdL._AC_UX679_t.png" },
    { "id"=>20, "title"=>"DANVOUY Womens T Shirt Casual Cotton Short", "price"=>12.99, "description"=>"95%Cotton,5%Spandex, Features: Casual, Short Sleeve, Letter Print,V-Neck,Fashion Tees, The fabric is soft and has some stretch., Occasion: Casual/Office/Beach/School/Home/Street. Season: Spring,Summer,Autumn,Winter.", "category"=>"women's clothing", "image"=>"https://fakestoreapi.com/img/61pHAEJ4NML._AC_UX679_t.png" }
  ]

  ActiveRecord::Base.transaction do
    begin
      producer = Producer.first
      unless producer
        puts "No producers found. Please seed producers first."
        raise ActiveRecord::Rollback
      end

      products.each do |product_data|
        # Find or create category
        category = ProductCategory.find_or_create_by!(title: product_data['category'])

        # Create product
        Product.find_or_create_by!(title: product_data['title']) do |product|
          product.product_category = category
          product.producer = producer
          product.description = product_data['description']
          product.price = product_data['price']
          product.product_image_url = product_data['image']
        end
        puts "Seeded product: #{product_data['title']}"
      end

      puts "Products table seeded successfully"
    rescue StandardError => e
      puts "Failed to seed products. Error: #{e.message}"
      raise ActiveRecord::Rollback
    end
  end

  # Seeds the Company Sites for development
  puts "Seeding Company Sites table..."
  ph_country = Country.find_by(code: "PH")
  sg_country = Country.find_by(code: "SG")
  company_addresses = [
    { unit_no: "110", street_no: "87 Cucumber St", barangay: "Geylang", city: "Singapore", zipcode: "1557330", country_id: sg_country.id  },
    { unit_no: "332", street_no: "9th Roxas", barangay: "San Vicente", city: "Tarlac", zipcode: "5650", country_id: ph_country.id  },
    { unit_no: "090", street_no: "8th Linkway", barangay: "Dakila", city: "Malolos", zipcode: "8110", country_id: ph_country.id  },
    { unit_no: "3101-A", street_no: "99th Ave", barangay: "San Roque", city: "Antipolo", zipcode: "6602", country_id: ph_country.id  }
  ]

  company_site_records = company_addresses.map do |attrs|
    Address.find_or_create_by!(attrs)
  end

  company_site = [
    { title: "JPB Management - HQ", address: company_site_records[0], site_type: "management" },
    { title: "JPB Warehouse A", address: company_site_records[1], site_type: "warehouse" },
    { title: "JPB Warehouse B", address: company_site_records[2], site_type: "warehouse" },
    { title: "JPB Warehouse C", address: company_site_records[3], site_type: "warehouse" }
  ]

  company_site.each do |attrs|
    CompanySite.find_or_create_by!(title: attrs[:title]) do |site|
      site.address = attrs[:address]
      site.site_type = attrs[:site_type]
    end
  end

  # Seeds the Admin User for development
  puts "Seeding Admin Users for development..."

  admin_email = ENV['ADMIN_EMAIL']
  admin_password = ENV['ADMIN_PASSWORD']

  warehouse_email = ENV['WAREHOUSE_EMAIL']
  warehouse_password = ENV['WAREHOUSE_PASSWORD']

  ActiveRecord::Base.transaction do
    begin
      # Management Admin
      management_admin = AdminUser.find_or_create_by!(email: admin_email) do |admin|
        admin.password = admin_password
        admin.password_confirmation = admin_password
        admin.admin_role = 'management'
        admin.skip_detail_validation = true  # Skip validation during seed
        admin.confirmed_at = Time.current  # Auto-confirm admin users
      end

      # Ensure admin is confirmed (for existing records)
      management_admin.update!(confirmed_at: Time.current) unless management_admin.confirmed?

      unless management_admin.admin_detail
        management_admin.create_admin_detail!(
          first_name: 'Admin',
          last_name: 'User',
          dob: Date.new(1990, 1, 1)
        )
      end

      AdminAddress.find_or_create_by!(
        admin_user: management_admin,
        address: company_site_records.first,
        is_default: true
      )

      AdminUsersCompanySite.find_or_create_by!(
        admin_user: management_admin,
        company_site: CompanySite.find_by(title: company_site.first[:title])
      )

      # Warehouse Admin
      warehouse_admin = AdminUser.find_or_create_by!(email: warehouse_email) do |admin|
        admin.password = warehouse_password
        admin.password_confirmation = warehouse_password
        admin.admin_role = 'warehouse'
        admin.skip_detail_validation = true  # Skip validation during seed
        admin.confirmed_at = Time.current  # Auto-confirm admin users
      end

      # Ensure admin is confirmed (for existing records)
      warehouse_admin.update!(confirmed_at: Time.current) unless warehouse_admin.confirmed?

      unless warehouse_admin.admin_detail
        warehouse_admin.create_admin_detail!(
          first_name: 'Warehouse',
          last_name: 'Admin',
          dob: Date.new(1995, 1, 1)
        )
      end

      AdminAddress.find_or_create_by!(
        admin_user: warehouse_admin,
        address: company_site_records.second,
        is_default: true
      )

      AdminUsersCompanySite.find_or_create_by!(
        admin_user: warehouse_admin,
        company_site: CompanySite.find_by(title: company_site.second[:title])
      )

      puts "Admin users seeded successfully."
    rescue StandardError => e
      puts "Failed to seed admin users. Error: #{e.message}"
      raise ActiveRecord::Rollback
    end
  end

  # Seeds Inventories for all warehouse company sites
  puts "Seeding Inventories for warehouse sites..."
  ActiveRecord::Base.transaction do
    begin
      # Get all warehouse sites
      warehouse_sites = CompanySite.where(site_type: 'warehouse')

      # Get all products
      all_products = Product.all

      if warehouse_sites.empty?
        puts "No warehouse sites found. Please seed company sites first."
        raise ActiveRecord::Rollback
      end

      if all_products.empty?
        puts "No products found. Please seed products first."
        raise ActiveRecord::Rollback
      end

      # Create inventory for each product in each warehouse with 100 items
      inventory_count = 0
      warehouse_sites.each do |warehouse|
        all_products.each do |product|
          Inventory.find_or_create_by!(
            product: product,
            company_site: warehouse
          ) do |inventory|
            inventory.qty_in_stock = 100
          end
          inventory_count += 1
        end
        puts "Created inventories for #{warehouse.title}"
      end

      puts "Successfully seeded #{inventory_count} inventory records across #{warehouse_sites.count} warehouses."
    rescue StandardError => e
      puts "Failed to seed inventories. Error: #{e.message}"
      raise ActiveRecord::Rollback
    end
  end

end
