#!/usr/bin/env bash

# -e: Exit on error.
# -u: Exit when using unset variables.
# -o pipefail: Fail if any command in a pipeline fails.
set -euo pipefail

# Switch to the directory containing this script.
cd "$(dirname "$0")"

# Create the directory if it doesn't already exist.
mkdir -p .secrets

# 700 = rwx------: Full access for the owner, no access for others.
chmod 700 .secrets

# Iterate over constants for our database and admin passwords plus WordPress keys and salts.
for item in db_password wp_admin_password AUTH_KEY SECURE_AUTH_KEY LOGGED_IN_KEY NONCE_KEY AUTH_SALT SECURE_AUTH_SALT LOGGED_IN_SALT NONCE_SALT; do
  # Do not overwrite existing non-empty secret files.
  if [[ ! -s ".secrets/$item" ]]; then
    # Generate 32 random bytes (64 hex characters) and save them to a file.
    # Restrict newly created files to owner-only access with "umask 077" (600 = rw-------).
    (umask 077; openssl rand -hex 32 > ".secrets/$item")
  fi
done

printf '%s\n' 'Secret files are in the .secrets/ directory.'
