# posi_trace_challenge

## Description
Rails project automatically generated with Docker, PostgreSQL and RSpec.

## Prerequisites
- Docker
- Docker Compose

## Setup

### 1. Build and start the containers
```bash
docker compose up --build
```

### 2. Create and migrate the database
```bash
docker compose exec web bundle exec rails db:create
docker compose exec web bundle exec rails db:migrate
```

### 3. Access the application
Open http://localhost:3000 in your browser.

## Useful commands

### Run tests
```bash
docker compose exec web bundle exec rspec
```

### Run Rails console
```bash
docker compose exec web bundle exec rails console
```

### Stop containers
```bash
docker compose down
```

## Project structure
- Dockerfile.dev: Development environment configuration
- docker-compose.yml: Service orchestration (web and database)
- PostgreSQL: Database configured for development and test
- RSpec: Configured testing framework
- Factory Bot: For creating test data
- Faker: For generating fake data

## Versions
- Ruby: 4.0.6
- Rails: 8.1.3
- PostgreSQL: 16
