# API Explorer Rails Backend

A RESTful API built with Ruby on Rails to fetch and cache GitHub user data. Integrates with the [API Explorer Frontend](https://github.com/jpetrucci49/api-explorer-frontend).

## Features

- Endpoint: `/github?username={username}`
- Returns GitHub user details (e.g., login, id, name, repos, followers).
- Redis caching with 30-minute TTL.
- Structured logging with Lograge (cache status).

## Setup

1. **Clone the repo**  
   ```bash
   git clone https://github.com/jpetrucci49/api-explorer-rails.git
   cd api-explorer-rails
   ```
2. **Install dependencies**  
   ```bash
   bundle install
   ```
3. **Run locally**  
   ```bash
   make dev
   ```
   Runs on `http://localhost:3004`. Requires Redis at `redis:6379`.  
   *Note*: If `make` isn’t installed:  
   ```bash
   rails server -b 0.0.0.0 -p 3004
   ```

## Usage

- GET `/github?username=octocat` to fetch data for "octocat".
- Test with `curl -v` (check `X-Cache`) or the frontend.

## Example Response

```json
{
  "login": "octocat",
  "id": 583231,
  "name": "The Octocat",
  "public_repos": 8,
  "followers": 17529
}
```

## Production

The process reads `PORT` (default 3004), `GITHUB_TOKEN`, `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`, and `FRONTEND_ORIGIN` (default `http://localhost:3000`). Set `RAILS_MASTER_KEY` from your local `config/master.key`. Never commit `config/master.key`. Leave `RAILS_ENV` unset. Redis must be plain TCP, with TLS off. Copy `.env.example` to `.env` and do not commit `.env`.

```bash
rails s -b 0.0.0.0 -p $PORT
```

`GET /health` and `GET /up` return 200 for the host health check. Deploy steps live in the [umbrella README](https://github.com/jpetrucci49/fullstack-api-explorer).

## Next Steps

- Add `/analyze` endpoint for profile insights (e.g., language stats).
- Add `/network` endpoint for collaboration mapping.
- Deploy to Render or Heroku.

---
Built by Joseph Petrucci | March 2025