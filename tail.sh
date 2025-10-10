#!/bin/bash
set -e

curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up --ssh --auth-key=tskey-auth-kAjFM3aKjG11CNTRL-Kscb2mpjpqXRxv4ZgYzoqXANLw5EeYiR7
