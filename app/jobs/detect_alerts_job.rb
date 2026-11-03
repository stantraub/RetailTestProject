# Runs the alert detector in the background. The detector already does the
# work in one idempotent SQL statement (ON CONFLICT DO NOTHING), so the job
# is just a thin wrapper: a retry or a double run can't create duplicates.
class DetectAlertsJob < ApplicationJob
  queue_as :default

  # Two writers touching the same rows can deadlock; Postgres kills one, so retry.
  retry_on ActiveRecord::Deadlocked, wait: 30.seconds, attempts: 3

  def perform
    Alerts::Detector.new.call
  end
end
