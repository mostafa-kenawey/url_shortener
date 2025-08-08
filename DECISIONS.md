# Decision Log

This document outlines the key design and infrastructure decisions made while building the URL shortener project, along with alternatives considered and the rationale for chosen solutions.

## Programming Language & Framework

### Decision

Elixir with Phoenix Framework

### Reason

Phoenix is highly performant, fault-tolerant, and built on Elixir's concurrency model (Erlang VM), making it ideal for handling high throughput and real-time applications like a URL shortener.

### Alternative Considered 

Ruby on Rails
Why Discarded: While Rails has fast development cycles, it lacks the lightweight concurrency and real-time pub/sub capabilities Elixir/Phoenix provides out of the box.

## Database

### Decision

PostgreSQL

### Reason

PostgreSQL provides strong consistency, indexing support, and robust performance for write-heavy workloads. Also integrates smoothly with Ecto in Phoenix.

### Alternative Considered

SQLite
Why Discarded: SQLite isn't suited for multi-user or production environments due to concurrency limitations and in-memory storage by default.


## Metrics Storage & Processing

### Decision

Asynchronous PubSub event broadcasting to collect redirect metrics

### Reason

Prevents blocking the redirect response. Collected metrics (IP, user agent, timestamp) are persisted separately for analytics.

### Alternative Considered

Synchronous metric logging within redirect controller
Why Discarded: Risk of slowing down the user experience due to DB write latency.

## Infrastructure & Deployment

### Decision

Deployed to Fly.io via GitHub Actions or Fly CTL

### Reason

Fly.io provides global deployments, easy Postgres add-ons, and a developer-friendly CLI. GitHub Actions allows smooth CI/CD integration.

### Alternative Considered: 

Deploying on Heroku
Why Discarded: Heroku's free tier was deprecated, and Fly.io provides better performance and flexibility for Elixir apps.

## External Database

### Decision

Use Supabase for external PostgreSQL in production

### Reason

Supabase offers a generous free-tier with hosted Postgres and simplified access via connection strings.

### Alternative Considered

Managed Postgres on Fly.io
Why Discarded: Fly.io’s Postgres offering incurs a minimum cost of $38/month. Supabase is more cost-effective for initial development/demo.

## User Agent Logging

### Decision

Store truncated user agents (first part only, e.g., "Mozilla/5.0")

### Reason

Reduces storage cost and avoids storing overly verbose or PII-sensitive info.

### Alternative Considered

Storing the full user agent string
Why Discarded: Not useful for most analytics and increases DB storage unnecessarily.