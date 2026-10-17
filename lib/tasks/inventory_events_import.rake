namespace :inventory_events do
    desc "Import inventory events from tracking_events.csv located in the app root"
    task import: :environment do
      path = Rails.root.join("tracking_events.csv")
  
      unless File.exist?(path)
        puts "ERROR: File not found:"
        puts "  #{path}"
        puts ""
        puts "Place tracking_events.csv in the top-level directory of the Rails app."
        exit 1
      end
  
      puts "Importing inventory events from #{path}..."
      
      InventoryEvents::CsvImporter.new(path).call
  
      puts "Done."
    end
  end