# API Explorer Rails Backend

A RESTful API built with Ruby on Rails to fetch GitHub user data. Integrates with the [API Explorer Frontend](https://github.com/jpetrucci49/api-explorer-frontend).

## Features
- Endpoint: `/github?username={username}`
- Returns GitHub user details (e.g., login, id, name, repos, followers)

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
   Runs on `http://localhost:3004`.  
   *Note*: If `make` isn’t installed (e.g., some Windows users), use:  
   ```bash
   rails server -b 0.0.0.0 -p 3004
   ```

## Usage
- GET `/github?username=octocat` to fetch data for "octocat"
- Test with `curl` or the frontend

## Example Response
```json
{
  "login": "octocat",
  "id": 583231,
  "name": "The Octocat",
  "public_repos": 8,
  "followers": 12345
}
```

## Next Steps
- Add caching for GitHub API calls
- Deploy to a hosting service (e.g., Render)

---
Built by Joseph Petrucci | March 2025