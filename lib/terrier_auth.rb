# Define the main module
module TerrierAuth
end

# Dynamically load all Ruby files in the terrier_auth/ subdirectory
Dir.glob(File.expand_path('terrier_auth/**/*.rb', __dir__)).sort.each do |file|
  require_relative file
end