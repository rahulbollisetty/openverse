#!/bin/bash
set -e
PLAUSIBLE_SERVICE_NAME="${PLAUSIBLE_SERVICE_NAME:-plausible}"
PLAUSIBLE_DB_SERVICE_NAME="${PLAUSIBLE_DB_SERVICE_NAME:-plausible_db}"

# Create Plausible user
docker-compose exec -T "$PLAUSIBLE_SERVICE_NAME" \
  /app/bin/plausible rpc \
  "Plausible.Auth.User.new(%{name: \"Deploy\", email: \"deploy@example.com\", password: \"deploy\", password_confirmation: \"deploy\"}) |> Plausible.Repo.insert"

# Create an API key with '{sites:provision:*}' scope
# API key: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa (that's 64 times 'a')
# Key hash: SHA256(`SECRET_KEY_BASE` + API key)
docker-compose exec -T "$PLAUSIBLE_DB_SERVICE_NAME" /bin/bash -c "psql -U deploy -d plausible <<-EOF
	INSERT INTO api_keys
	  (id, user_id, name, key_prefix, key_hash, inserted_at, updated_at, scopes, hourly_request_limit)
	VALUES
	  (1, 1, 'Development', 'aaaaaa', '332015ffc9f0e1f475c0fadb1e1a14d2eb09774249f71961f5a2c477efc0a0fc', now(), now(), '{sites:provision:*}', 1000)
  ON CONFLICT (id) DO NOTHING
	EOF"

authorization_header="Authorization: Bearer aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
local_plausible="http://localhost:50288"

# Create site using API key
RES=$(curl \
  -X POST \
  -H "$authorization_header" \
  -F 'domain="localhost"' \
  -F 'timezone="UTC"' \
  "$local_plausible/api/v1/sites")

if [[ "$RES" == *"\"error\":\"domain This domain has already been taken"* ]]; then
  echo "Domain already exists."
elif [[ "$RES" == *"\"domain\":\"localhost\""* ]]; then
  echo "Domain created."
else
  echo "Error: $RES"
  exit 1
fi

# Setup custom events
custom_events=$(node ./frontend/bin/get-custom-event-names.js)

echo "Verifying custom events:"

for eventName in $custom_events;
do
  echo "$eventName"
  curl \
    -X PUT \
    -s --output /dev/null \
    -H "$authorization_header" \
    -F 'site_id=localhost' \
    -F 'goal_type=event' \
    -F "event_name=$eventName" \
    "$local_plausible/api/v1/sites/goals"
done
