class JobHelper

  def self.handle_retry(&code)
    5.times do
      begin
        code.call
        break
      rescue ActiveRecord::RecordNotFound, ActiveRecord::StatementInvalid
        sleep 1
      end
    end
  end

end
