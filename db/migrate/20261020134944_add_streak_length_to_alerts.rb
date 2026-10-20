class AddStreakLengthToAlerts < ActiveRecord::Migration[7.1]
  def change
    # How many "no inventory" checks in a row created the alert. Existing alerts
    # were all made with the original rule of two.
    add_column :alerts, :streak_length, :integer, null: false, default: 2
  end
end
