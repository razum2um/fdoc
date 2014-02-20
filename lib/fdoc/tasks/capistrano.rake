namespace :deploy do

  desc 'Runs rake db:migrate if migrations are set'
  task :generate_fdoc do
    on roles(:web) do
      within release_path do
        fdoc_path = 'fdoc'
        execute :bundle, %Q{exec fdoc convert fdoc --output=./public/#{fdoc_path} -u "/#{fdoc_path}"}
      end
    end
  end

  after :finishing, 'deploy:generate_fdoc'
end
