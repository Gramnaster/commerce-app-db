namespace :solid_queue do
  task :start_worker do
    SolidQueue::Supervisor.start(mode: :worker)
  end
end
