#!/bin/bash
set -e

curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up --ssh --auth-key=tskey-auth-ktNazoGrQE11CNTRL-nJNawmE9TJTNtRSs65UHJTCXaXkzHGxH
