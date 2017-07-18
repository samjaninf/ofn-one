namespace :openfoodnetwork do

  namespace :dev do

    desc 'load sample data'
    task :load_sample_data => :environment do
      require_relative '../../spec/factories'
      require_relative '../../spec/support/spree/init'
      task_name = "openfoodnetwork:dev:load_sample_data"

      # -- Shipping / payment information
      unless Spree::Zone.find_by_name 'United States'
        puts "[#{task_name}] Seeding shipping / payment information"
        zone = FactoryGirl.create(:zone, :name => 'United States', :zone_members => [])
        country = Spree::Country.find_by_name('United States')
        Spree::ZoneMember.create(:zone => zone, :zoneable => country)
        FactoryGirl.create(:shipping_method, :zone => zone)
      end

      # -- Taxonomies
      unless Spree::Taxonomy.find_by_name 'Products'
        puts "[#{task_name}] Seeding taxonomies"
        taxonomy = Spree::Taxonomy.find_by_name('Products') || FactoryGirl.create(:taxonomy, :name => 'Products')
        taxonomy_root = taxonomy.root

        ['Vegetables', 'Fruit', 'Oils', 'Preserves and Sauces', 'Dairy', 'Meat and Fish'].each do |taxon_name|
          FactoryGirl.create(:taxon, :name => taxon_name, :parent_id => taxonomy_root.id)
        end
      end

      # -- Addresses
      unless Spree::Address.find_by_zipcode "04937"
        puts "[#{task_name}] Seeding addresses"

        FactoryGirl.create(:address, :address1 => "230 Skowhegan Road", :zipcode => "04937", :city => "Fairfield", :state => "ME")
      end

      # -- Enterprises
      unless Enterprise.count > 1
        puts "[#{task_name}] Seeding enterprises"

        3.times { FactoryGirl.create(:supplier_enterprise, :address => Spree::Address.find_by_zipcode("04937")) }

        
        FactoryGirl.create(:distributor_enterprise, :name => "PEGAS Technology Solutions", :address => Spree::Address.find_by_zipcode("04937"))
      end

      # -- Enterprise users
      unless Spree::User.count > 1 
        puts "[#{task_name}] Seeding enterprise users"

        pw = "spree123"

        u = FactoryGirl.create(:user, email: "sup@example.com", password: pw, password_confirmation: pw)
        u.enterprises << Enterprise.is_primary_producer.first
        u.enterprises << Enterprise.is_primary_producer.second
        puts "  Supplier User created:    #{u.email}/#{pw}  (" + u.enterprise_roles.map{ |er| er.enterprise.name}.join(", ") + ")"

        u = FactoryGirl.create(:user, email: "dist@example.com", password: pw, password_confirmation: pw)
        u.enterprises << Enterprise.is_distributor.first
        u.enterprises << Enterprise.is_distributor.second
        puts "  Distributor User created: #{u.email}/#{pw} (" + u.enterprise_roles.map{ |er| er.enterprise.name}.join(", ") + ")"
      end

      # -- Enterprise fees
      unless EnterpriseFee.count > 1
        Enterprise.is_distributor.each do |distributor|
          FactoryGirl.create(:enterprise_fee, enterprise: distributor)
        end
      end

      # -- Enterprise Payment Methods
      unless Spree::PaymentMethod.count > 1
        Enterprise.is_distributor.each do |distributor|
          FactoryGirl.create(:payment_method, distributors: [distributor], name: "Cheque (#{distributor.name})", :environment => 'development')
        end
      end

      # -- Products
      unless Spree::Product.count > 0
        puts "[#{task_name}] Seeding products"

        prod1 = FactoryGirl.create(:product,
                           :name => 'Garlic', :price => 20.00,
                           :supplier => Enterprise.is_primary_producer[0],
                           :taxons => [Spree::Taxon.find_by_name('Vegetables')])

        ProductDistribution.create(:product => prod1,
                                   :distributor => Enterprise.is_distributor[0],
                                   :enterprise_fee => Enterprise.is_distributor[0].enterprise_fees.first)


        prod2 = FactoryGirl.create(:product,
                           :name => 'Fuji Apple', :price => 5.00,
                           :supplier => Enterprise.is_primary_producer[1],
                           :taxons => [Spree::Taxon.find_by_name('Fruit')])

        ProductDistribution.create(:product => prod2,
                                   :distributor => Enterprise.is_distributor[1],
                                   :enterprise_fee => Enterprise.is_distributor[1].enterprise_fees.first)

        prod3 = FactoryGirl.create(:product,
                           :name => 'Beef - 5kg Trays', :price => 50.00,
                           :supplier => Enterprise.is_primary_producer[2],
                           :taxons => [Spree::Taxon.find_by_name('Meat and Fish')])

        ProductDistribution.create(:product => prod3,
                                   :distributor => Enterprise.is_distributor[2],
                                   :enterprise_fee => Enterprise.is_distributor[2].enterprise_fees.first)

        prod4 = FactoryGirl.create(:product,
                                   :name => 'Carrots', :price => 3.00,
                                   :supplier => Enterprise.is_primary_producer[2],
                                   :taxons => [Spree::Taxon.find_by_name('Meat and Fish')])

        ProductDistribution.create(:product => prod4,
                                   :distributor => Enterprise.is_distributor[2],
                                   :enterprise_fee => Enterprise.is_distributor[2].enterprise_fees.first)

        prod5 = FactoryGirl.create(:product,
                                   :name => 'Potatoes', :price => 2.00,
                                   :supplier => Enterprise.is_primary_producer[2],
                                   :taxons => [Spree::Taxon.find_by_name('Meat and Fish')])

        ProductDistribution.create(:product => prod5,
                                   :distributor => Enterprise.is_distributor[2],
                                   :enterprise_fee => Enterprise.is_distributor[2].enterprise_fees.first)

        prod6 = FactoryGirl.create(:product,
                                   :name => 'Tomatoes', :price => 2.00,
                                   :supplier => Enterprise.is_primary_producer[2],
                                   :taxons => [Spree::Taxon.find_by_name('Meat and Fish')])

        ProductDistribution.create(:product => prod6,
                                   :distributor => Enterprise.is_distributor[2],
                                   :enterprise_fee => Enterprise.is_distributor[2].enterprise_fees.first)

        prod7 = FactoryGirl.create(:product,
                                   :name => 'Potatoes', :price => 2.00,
                                   :supplier => Enterprise.is_primary_producer[2],
                                   :taxons => [Spree::Taxon.find_by_name('Meat and Fish')])

        ProductDistribution.create(:product => prod7,
                                   :distributor => Enterprise.is_distributor[2],
                                   :enterprise_fee => Enterprise.is_distributor[2].enterprise_fees.first)

      end
    end
  end
end
