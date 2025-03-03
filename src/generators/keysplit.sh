#!/bin/bash

# Define the owner address (hardcoded as specified)
OWNER_ADDRESS="0x000000633b68f5D8D3a86593ebB815b4663BCBe0"
OUTPUT_PATH="out.json"
NONCE="0"

# Extract validator public key from the directory structure
# Using the first key as an example
VALIDATOR_KEY=$(ls ../keystores/keys/ | head -1)

# Extract password from the secrets file corresponding to the validator key
PASSWORD=$(cat ../keystores/secrets/$VALIDATOR_KEY)

# Determine keystore path - using the voting-keystore.json for the validator
KEYSTORE_PATH="../keystores/keys/$VALIDATOR_KEY/voting-keystore.json"

# Extract operator IDs directly from the JSON - must force to numbers
OPERATOR_IDS=$(cat ../operator_data/operator_data.json | jq -r '.operators[].id' | tr '\n' ',' | sed 's/,$//')
echo "Operator IDs: $OPERATOR_IDS"

# Extract the public keys from operator_data.json
PUBLIC_KEYS=""
for ID in $(echo $OPERATOR_IDS | tr ',' ' '); do
  # Convert ID to number for jq
  KEY=$(cat ../operator_data/operator_data.json | jq -r ".operators[] | select(.id == $ID) | .publicKey")
  
  if [ -z "$PUBLIC_KEYS" ]; then
    PUBLIC_KEYS="$KEY"
  else
    PUBLIC_KEYS="$PUBLIC_KEYS,$KEY"
  fi
done

echo "First 50 chars of Public Keys: ${PUBLIC_KEYS:0:50}..."

# Run the command
echo "Running command with:"
echo "Keystore: $KEYSTORE_PATH"
echo "Password: $PASSWORD"
echo "Operators: $OPERATOR_IDS"

../app keysplit manual \
  --keystore-path "$KEYSTORE_PATH" \
  --password "$PASSWORD" \
  --owner "$OWNER_ADDRESS" \
  --output-path "$OUTPUT_PATH" \
  --operators "$OPERATOR_IDS" \
  --nonce "$NONCE" \
  --public-keys "$PUBLIC_KEYS"
