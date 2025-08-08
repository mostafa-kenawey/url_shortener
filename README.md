# URL Shortener

A modern URL shortener application built with Elixir and Phoenix, featuring real-time analytics and caching.

**Live Demo**: [https://url-shortener-shy-fire-2164.fly.dev/](https://url-shortener-shy-fire-2164.fly.dev/)


### For a detailed explanation of the technical choices, refer to the [Decision Log](./DECISIONS.md).


## Features

* URL shortening with custom slugs
* Real-time metrics collection
* Admin dashboard with Phoenix LiveView
* High-performance caching with Cachex
* Rate limiting protection
* Admin authentication

## Setup

### Prerequisites

* Elixir and Erlang installed
* PostgreSQL installed and running
* direnv used to manage environment variables locally

### Installation

#### Clone the repo

* Run `git clone git@github.com:mostafa-kenawey/url_shortener.git` to clone the repo from github

#### Environment Setup

* Run `cp .envrc.example .envrc` to create .envrc file
* Update .envrc with the required variables
* Run `direnv allow` to export variables

#### Install dependencies

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

#### Sample Data

Create sample analytics data for testing the dashboard

* Run `mix run create_sample_data.exs`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

### Docker Setup

For a simplified setup using Docker, you can run the application with PostgreSQL in containers:

#### Quick Start with Docker

2. **Build and start the application**:
   ```bash
   # Using Docker Compose directly
   docker-compose up --build
   
   # OR test the setup automatically
   ./test-docker.sh
   ```

3. **Access the application**:
   - Open your browser and visit [http://localhost:4000](http://localhost:4000)
   - The database will be automatically created and migrations will run
   - Health check endpoint: [http://localhost:4000/api/health](http://localhost:4000/api/health)

#### Docker Commands

Useful Docker commands for development:

```bash
# Build images
make build

# Start services in background
make up

# Stop services
make down

# Clean up (remove volumes and containers)
make clean
```

#### Configuration

**Production Environment Variables:**
- `DATABASE_URL`: PostgreSQL connection string (automatically set in docker-compose)
- `SECRET_KEY_BASE`: Secret key for cookies and sessions (pre-configured)

## Testing

```bash
# Run tests
mix test

# Run tests with coverage
mix test --cover

# Format code
mix format

# Static analysis
mix credo
```

## Development Tools

### Email Preview

In development mode, you can preview sent emails by visiting:

* [http://localhost:4000/dev/mailbox](http://localhost:4000/dev/mailbox)

This allows you to test email content (like confirmation links) without actually sending them.


### LiveDashboard

Phoenix LiveDashboard is available in development mode at:

* [http://localhost:4000/dev/dashboard/home](http://localhost:4000/dev/dashboard/home)

It provides insights into application performance, system metrics, and more.