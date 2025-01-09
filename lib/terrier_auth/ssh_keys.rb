require 'colorize'
require 'ssh_data'
require 'ed25519'
require 'ap'

# Manages the SSH keys on this machine.
class TerrierAuth::SshKeys

  def log_timestamp
    Time.now.strftime("%Y-%m-%d %H:%M:%S")
  end

  def debug(message)
    puts "[DEBUG #{log_timestamp}] #{message}"
  end

  def info(message)
    puts "[INFO #{log_timestamp}] #{message}"
  end

  def warn(message)
    puts "[WARN #{log_timestamp}] #{message}"
  end

  # @return [String] the absolute directory to the ssh files on this machine.
  def ssh_dir
    File.expand_path("~/.ssh")
  end

  # Gets the private key for this machine.
  # Assumes it's in ~/.ssh and has a standard name like id_rsa or id_ed25519.
  # @return [SSHData::PrivateKey::Base]
  def load_private_key
    # compute the file path
    private_key_files = Dir.glob(ssh_dir + '/*').select do |file|
      File.file?(file) && File.readable?(file) && file.match(/id_(rsa|dsa|ecdsa|ed25519)$/)
    end
    raise "No private keys found in #{ssh_dir}" if private_key_files.empty?
    private_key_path = private_key_files.first

    raw_key = File.read(private_key_path).strip
    debug "Raw private key from #{private_key_path.yellow}:\n#{raw_key.yellow}"
    SSHData::PrivateKey.parse_openssh(raw_key).first || raise("No private keys parsed from #{private_key_path}")
  end

  # Loads the public key for this machine.
  # Assumes it's in ~/.ssh and has a standard name like id_rsa.pub or id_ed25519.pub.
  # @return [String]
  def load_public_key
    public_key_files = Dir.glob(ssh_dir + '/*').select do |file|
      File.file?(file) && File.readable?(file) && file.match(/id_(rsa|dsa|ecdsa|ed25519).pub$/)
    end
    raise "No public keys found in #{ssh_dir}" if public_key_files.empty?
    public_key_path = public_key_files.first

    raw_key = File.read(public_key_path).strip
    debug "Raw public key from #{public_key_path.green}:\n#{raw_key.green}"
    raw_key
  end

  # Loads the valid public keys on this machine from ~/.ssh/authorized_keys and any local public key files.
  # @return [Array<String>]
  def load_all_public_keys
    # read from the authorized keys file
    authorized_keys_path = File.join(ssh_dir, 'authorized_keys')
    authorized_keys = []
    if File.exist?(authorized_keys_path)
      authorized_keys = File.readlines(authorized_keys_path).map(&:strip)
      debug "Read #{authorized_keys.count} public keys from #{authorized_keys_path}"
    end

    # add the machine's own public key
    public_key = load_public_key

    [public_key.to_s] + authorized_keys
  end

  # Validates that the given public key is included in this machine's authorized_keys file.
  # Only compares the second component - the actual key - since the trailing user string is arbitrary.
  # @param other_key [String] a raw public key string to compare
  # @return [Boolean]
  def has_public_key?(other_key)
    other_raw = other_key.split(/\s+/)[1]
    unless other_raw
      warn "has_public_key? was passed a public key without a second component: #{other_key}"
      return false
    end
    public_keys = load_all_public_keys
    debug "has_public_key? loaded #{public_keys.count} public keys"
    public_keys.each do |key|
      this_raw = key.split(/\s+/)[1]
      if this_raw == other_raw
        info "has_public_key? matched public key #{this_raw}"
        return true
      end
    end
    false
  end

  # @return [Hash] with:
  #   - :ssh_challenge [String] a timestamp string
  #   - :ssh_signature [String] the challenge string encrypted
  #   - :ssh_public_key [String] the public key used for encryption
  def generate_challenge

    # load the keys
    ssh_private_key = load_private_key
    ssh_public_key = load_public_key.to_s

    # generate and encrypt the challenge
    ssh_challenge = Time.now.to_i.to_s # Current UNIX timestamp
    ssh_signature = Base64.strict_encode64 ssh_private_key.sign(ssh_challenge)
    debug "Encrypted challenge #{ssh_challenge.blue} as #{ssh_signature.green}"

    {
      ssh_challenge:,
      ssh_signature:,
      ssh_public_key:
    }
  end

  # the amount of time that a challenge is valid
  CHALLENGE_DURATION_SECONDS = 5

  # Validates that a signed challenge string is valid,
  # that the challenge timestamp is recent enough,
  # and that the public key is in the authorized keys file for this machine.
  # @return [Boolean] true if the signed challenge is valid
  def validate_challenge!(data)
    raw_key = data[:ssh_public_key] || raise("Must pass a ssh_public_key")
    challenge = data[:ssh_challenge] || raise("Must pass a ssh_challenge")
    raw_signature = data[:ssh_signature] || raise("Must pass a ssh_signature")

    # ensure that the challenge is recent enough
    timestamp = Time.at(challenge.to_i)
    if timestamp < (Time.now - CHALLENGE_DURATION_SECONDS)
      raise "Challenge #{challenge} is #{timestamp}, which is too old!"
    end

    # verify that the signature matches the challenge
    binary_signature = Base64.decode64 raw_signature
    public_key = SSHData::PublicKey.parse_openssh raw_key
    unless public_key.verify challenge, binary_signature
      raise "Challenge does not match signature"
    end

    # verify that the public key is on this machine
    unless has_public_key?(raw_key)
      raise "Public key #{raw_key} is not on this machine!"
    end

    true
  end
end