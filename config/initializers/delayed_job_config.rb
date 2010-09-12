#silence_warnings do
#  Delayed::Job.const_set("MAX_ATTEMPTS", 3)
#  Delayed::Job.const_set("MAX_RUN_TIME", 5.minutes)
#end
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 5
Delayed::Worker.max_attempts = 1
Delayed::Worker.max_run_time = 20.minutes
