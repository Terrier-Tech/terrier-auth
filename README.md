# TerrierAuth

This gem contains some common utilities for managing authentication across terrier apps.

## SSH Keys

The `Terrier::SshKeys` class manages the ssh keys installed on the machine.


### SSH Challenge

SSH key pairs can be used to authenticate that one machine has access to another when sending a request.
If the client machine's public key is present in the authorized_keys file on the server machine, it inherently should be granted access to it.

In order to prove that the client has the corresponding private key, we generate a challenge string and compute the signature on the client using the private key. 
This challenge and signature are verified on the server using the public key.

To prevent re-using the same challenge (without needing two round trips), the challenge string is a timestamp and the server will only authenticate very recent challenges (that happened in e.g. the last 5 seconds).

Use `TerrierAuth::SshKeys#generate_challenge` to generate a challenge/signature pair on the client and
`TerrierAuth::SshKeys#validate_challenge!` to validate the pair on the server:

```ruby
keys = TerrierAuth::SshKeys.new

# generate the challenge,
data = keys.generate_challenge
# {
#   ssh_challenge: '12343251', 
#   ssh_signature: 'AAAAB3NzaC1yc2EAAAIAg5BiUw7Kt...', 
#   ssh_public_key: 'ssh-rsa AAAAB3NzaC1yc2EA...'
# }

# validate the challenge
keys.validate_challenge! data
```

