# FoundryTerraform
Personal terraform template for foundryVTT server on AWS




# to run:
## Generate a keypair for ssh access to the server
```ssh-keygen -f keys/foundry-ssh```

## put foundry release to deploy in foundry folder (and change vars file)

# Tail cloud init logs on foundry instance
```tail -f /var/log/cloud-init-output.log```