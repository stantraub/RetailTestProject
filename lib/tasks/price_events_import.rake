namespace :price_events do
  desc "Import price events from price_events.csv in the app root (or pass a path)"
  task :import, [:path] => :environment do |_task, args|
    path = args[:path] ? Pathname.new(args[:path]) : Rails.root.join("price_events.csv")

    unless File.exist?(path)
      puts "ERROR: File not found: #{path}"
      puts "Columns expected: Address, Product Name, Date, Price"
      exit 1
    end

    puts "Importing price events from #{path}..."
    result = PriceEvents::CsvImporter.new(path).call

    puts "Rows read:          #{result.rows}"
    puts "Created:            #{result.created}"
    puts "Skipped unchanged:  #{result.unchanged}"
    puts "Skipped unknown:    #{result.unknown} (store or product not found)"
    puts "Skipped invalid:    #{result.invalid} (bad date or price)"
  end
end
