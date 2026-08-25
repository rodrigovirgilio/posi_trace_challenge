# PosiTrace Challenge — Geolocation API

A RESTful JSON:API service that registers, retrieves, and deletes geolocation data for IP addresses or hostnames, backed by the [ipstack](https://ipstack.com) geolocation provider.

The provider integration is swappable — add a new adapter to `GeolocationProviders` and point `GEOLOCATION_PROVIDER` at it.

## Tech stack

- **Rails 8.1** (API mode)
- **PostgreSQL** database
- **Faraday** for the ipstack HTTP client
- **jsonapi-serializer** for JSON:API output
- **RSpec** + **WebMock** for the test suite
- **rswag** for OpenAPI 3.1 documentation (Swagger UI at `/api-docs`)
- **Bullet** for N+1 query detection in tests
- **Docker Compose** for local development

## Quick start (Docker)

### 1. Clone & configure environment

```bash
# Clone the repository
git clone https://github.com/rodrigovirgilio/posi_trace_challenge.git
cd posi_trace_challenge

# Copy the sample environment file
cp .env.sample .env

# Edit .env and set your credentials (see "Environment variables" below)
# At minimum, set a strong API_TOKEN for production use.
# For local development the defaults work out of the box.
```

### 2. Obtain an ipstack API key (required for live lookups)

1. Sign up for a free account at **https://ipstack.com/signup/free** (1,000 requests/month)
2. After confirming your email, copy **Your API Access Key** from the dashboard
3. Paste it into `.env` as `IPSTACK_ACCESS_KEY=your_key_here`

> **Note:** The free plan only works over **HTTP** (not HTTPS). The application already uses `http://api.ipstack.com`.
> Without this key, `POST /geolocations` returns `502 Bad Gateway` with `"IPSTACK_ACCESS_KEY is not configured"`.

### 3. Start the application

```bash
# Build and start containers (PostgreSQL + Rails)
docker compose up -d --build

# Prepare the database (creates DB, runs migrations, loads seed data)
docker compose exec web bin/rails db:prepare db:seed
```

### 4. Verify it works

- **API base:** http://localhost:3000
- **Swagger UI:** http://localhost:3000/api-docs

#### Test via Swagger UI

1. Open http://localhost:3000/api-docs
2. Click **Authorize** (🔒 top-right)
3. In the `bearer_auth` field, enter: `Bearer YOUR_API_TOKEN`
   - For local dev with defaults: `Bearer posi-trace-dev-token`
   - Or use the value you set in `.env` for `API_TOKEN`
4. Click **Authorize** → **Close**
5. Expand any endpoint (e.g., `POST /api/v1/geolocations`), click **Try it out**, provide a payload, and **Execute**

#### Test via curl

```bash
# Register a geolocation (by IP)
curl -X POST http://localhost:3000/api/v1/geolocations \
  -H "Authorization: Bearer posi-trace-dev-token" \
  -H "Content-Type: application/vnd.api+json" \
  -H "Accept: application/vnd.api+json" \
  -d '{"data":{"type":"geolocations","attributes":{"ip_or_url":"8.8.8.8"}}}'

# Retrieve by IP
curl -H "Authorization: Bearer posi-trace-dev-token" \
     -H "Accept: application/vnd.api+json" \
     http://localhost:3000/api/v1/geolocations/8.8.8.8

# Retrieve by hostname (falls back to DNS → IP if not found by url)
curl -H "Authorization: Bearer posi-trace-dev-token" \
     -H "Accept: application/vnd.api+json" \
     http://localhost:3000/api/v1/geolocations/google.com

# Delete
curl -X DELETE -H "Authorization: Bearer posi-trace-dev-token" \
     http://localhost:3000/api/v1/geolocations/8.8.8.8
```

## Environment variables

Create a `.env` file from the sample:

```bash
cp .env.sample .env
```

| Variable | Required? | Default | Description |
|---|---|---|---|
| `API_TOKEN` | **yes** | `posi-trace-dev-token` (dev) | Bearer token required on every request. **Set a strong secret in production.** |
| `IPSTACK_ACCESS_KEY` | for live lookups | — | Free key from [ipstack.com](https://ipstack.com). Only needed for `POST /api/v1/geolocations`. |
| `GEOLOCATION_PROVIDER` | no | `ipstack` | Switch the geolocation provider by registering a new adapter. |
| `DATABASE_URL` | no | from `config/database.yml` | Override the database connection (used in CI). |

### Example `.env`

```dotenv
# Required: bearer token for API authentication
# Generate a strong one for production: openssl rand -hex 32
API_TOKEN=posi-trace-dev-token

# Optional: get a free key at https://ipstack.com/signup/free
# Only needed for POST /geolocations (live provider calls)
IPSTACK_ACCESS_KEY=

# Optional: switch provider (ipstack is the only built-in)
GEOLOCATION_PROVIDER=ipstack
```

## API reference

All endpoints require the `Authorization: Bearer <token>` header and speak **JSON:API** (`application/vnd.api+json`).

Base path: `/api/v1`

| Method | Path | Description |
|---|---|---|
| `POST` | `/geolocations` | Register a geolocation (fetches from provider if new) |
| `GET` | `/geolocations/:location` | Retrieve a geolocation by IP or hostname |
| `DELETE` | `/geolocations/:location` | Delete a geolocation by IP or hostname |

### Register a geolocation

```bash
curl -X POST http://localhost:3000/api/v1/geolocations \
  -H "Authorization: Bearer posi-trace-dev-token" \
  -H "Content-Type: application/vnd.api+json" \
  -H "Accept: application/vnd.api+json" \
  -d '{
        "data": {
          "type": "geolocations",
          "attributes": {
            "ip_or_url": "8.8.8.8"
          }
        }
      }'
```

Response `201 Created` (truncated):

```json
{
  "data": {
    "id": "1",
    "type": "geolocation",
    "attributes": {
      "ip": "8.8.8.8",
      "url": null,
      "ip_type": "ipv4",
      "continent_code": "NA",
      "continent_name": "North America",
      "country_code": "US",
      "country_name": "United States",
      "region_code": "CA",
      "region_name": "California",
      "city": "Mountain View",
      "zip": "94043",
      "latitude": 37.386,
      "longitude": -122.0838
    }
  }
}
```

Accepts either an IP address (`8.8.8.8`, `2606:4700:4700::1111`) or a hostname/URL (`google.com`, `https://github.com/path`).

### Retrieve a geolocation

```bash
# by IP
curl -H "Authorization: Bearer posi-trace-dev-token" \
     -H "Accept: application/vnd.api+json" \
     http://localhost:3000/api/v1/geolocations/8.8.8.8

# by hostname (looks up the stored record by `url`, falls back to DNS → IP)
curl -H "Authorization: Bearer posi-trace-dev-token" \
     -H "Accept: application/vnd.api+json" \
     http://localhost:3000/api/v1/geolocations/google.com
```

### Delete a geolocation

```bash
curl -X DELETE -H "Authorization: Bearer posi-trace-dev-token" \
     http://localhost:3000/api/v1/geolocations/8.8.8.8
```

### Error format (JSON:API)

```json
{
  "errors": [
    {
      "status": "422",
      "title": "Unprocessable Entity",
      "detail": "8.8.8.8 is not a valid IP address or URL"
    }
  ]
}
```

| Status | Title | Meaning |
|---|---|---|
| 400 | Bad Request | Malformed JSON or missing `data` envelope |
| 401 | Unauthorized | Missing or invalid bearer token |
| 404 | Not Found | No geolocation stored for the given IP/URL |
| 409 | Conflict | Geolocation for that IP already exists |
| 422 | Unprocessable Entity | Invalid input, DNS failure, or provider rejected the lookup |
| 502 | Bad Gateway | Provider unavailable / unexpected response |

## Running tests

### Unit / Request specs (fast, headless)

```bash
# Inside the web container (sets test env vars automatically)
docker compose exec -e RAILS_ENV=test web bundle exec rspec
```

Runs 82 examples: unit specs, request specs, rswag specs.

### System specs (browser-based, with Firefox/Selenium)

```bash
# Inside the web container
docker compose exec -e RAILS_ENV=test web bundle exec rspec spec/system/
```

Runs 2 system specs that launch **headless Firefox** via Selenium to verify:
- Swagger UI loads at `/api-docs`
- API endpoints are listed in the Swagger UI

> **Note:** System specs require Firefox + geckodriver (installed in the Docker image). They run headless by default. Screenshots on failure are saved to `tmp/capybara/`.

### All tests (84 examples)

```bash
docker compose exec -e RAILS_ENV=test web bundle exec rspec
```

The test suite covers:
- Input parsing (`GeolocationInput`, `IpResolver`)
- Provider abstraction & ipstack adapter (stubbed HTTP)
- Register / Locator services
- All API endpoints (200, 201, 204, 400, 401, 404, 409, 422, 502)
- Bearer token authentication
- Swagger/OpenAPI document generation (rswag)
- Swagger UI rendering in real browser (system specs)

## Swapping the geolocation provider

1. Create a new adapter under `app/services/geolocation_providers/` that implements `#fetch(ip)` returning the same normalized attributes hash.
2. Register it in `GeolocationProviders::PROVIDERS`.
3. Set `GEOLOCATION_PROVIDER=my_new_provider` (or override in `config/application.rb`).

No other code changes required.

## Project structure (selected)

```
app/
├── controllers/
│   ├── api/
│   │   ├── base_controller.rb          # auth + JSON:API error rendering
│   │   └── v1/geolocations_controller.rb
├── serializers/
│   └── geolocation_serializer.rb       # jsonapi-serializer
├── services/
│   ├── geolocation_input.rb            # parses "ip or url"
│   ├── ip_resolver.rb                  # DNS → IP
│   ├── geolocation_providers.rb        # registry (ipstack + future adapters)
│   │   └── ipstack.rb                  # ipstack HTTP client + normalization
│   ├── geolocations/
│   │   ├── register.rb                 # fetch & store
│   │   ├── locator.rb                  # find by ip / url (+ DNS fallback)
│   │   └── *.rb                        # domain errors
│   └── api_token.rb                    # bearer token verification
config/
├── initializers/
│   ├── json_api.rb                     # vnd.api+json mime type
│   ├── rswag_api.rb / rswag_ui.rb      # Swagger UI at /api-docs
├── routes.rb
db/
├── migrate/...
├── seeds.rb                            # offline demo data
spec/
├── requests/api/v1/
│   ├── geolocations_spec.rb            # hand-written request specs
│   └── geolocations_swagger_spec.rb    # rswag specs → openapi.yaml
├── services/                           # unit specs for each service
├── support/
│   ├── capybara.rb                     # Capybara + Selenium (Firefox) config
│   └── ipstack_stub.rb                 # shared WebMock stubs
├── system/
│   └── geolocations_spec.rb            # system specs (headless Firefox)
└── swagger_helper.rb                   # rswag config (OpenAPI 3.1 + bearer auth)
```

## License

Challenge submission — all rights reserved.