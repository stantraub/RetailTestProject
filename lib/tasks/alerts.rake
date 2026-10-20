namespace :alerts do
  desc "Create alerts for N 'no inventory' events in a row for a product (default 2; e.g. alerts:detect[3])"
  task :detect, [:streak_length] => :environment do |_task, args|
    detector = args[:streak_length] ? Alerts::Detector.new(streak_length: args[:streak_length]) : Alerts::Detector.new

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    created = detector.call
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

    puts "Created #{created} alerts for #{detector.streak_length} in a row in #{elapsed.round(2)}s (#{Alert.count} total)."
  end
end
