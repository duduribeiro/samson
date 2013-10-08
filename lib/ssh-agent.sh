#!/bin/bash

if [[ ! -e tmp/auth_sock ]]; then
  eval `ssh-agent`
  mkdir -p tmp
  ln -sf $SSH_AUTH_SOCK tmp/auth_sock
  echo "$DEPLOY_KEY" > tmp/id_rsa
  echo -e "#!/bin/bash\necho $1" > tmp/passphrase.sh
  chmod +x tmp/passphrase.sh
  export SSH_ASKPASS=./tmp/passphrase.sh
  export DISPLAY=:bogus:1
  setsid ssh-add tmp/id_rsa < /dev/null
fi
