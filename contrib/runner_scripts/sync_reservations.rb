Reservation.find(:all, :conditions => "historical = 0").each do |reservation|
  begin
    reservation.sync
  rescue Exception => e
    puts "Failed to sync reservation: #{reservation.id}"
  end
end
