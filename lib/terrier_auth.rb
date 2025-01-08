module TerrierAuth

end

# load all files in subdirectories
Dir.glob(File.expand_path('terrier_auth/*.rb', __dir__)).sort.each do |file|
  require file
end