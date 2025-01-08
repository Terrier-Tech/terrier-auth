namespace :ssh do

  desc "Generates a challenge and signature pair for this client"
  task :generate_challenge do
    keys = TerrierAuth::SshKeys.new
    data = keys.generate_challenge
    ap data
    keys.validate_challenge! data
    puts "Challenge successfully validated!".green
  end

end