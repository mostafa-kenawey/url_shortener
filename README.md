# UrlShortener

A URL shortening service with real-time analytics dashboard built with Elixir, Phoenix and LiveView.

## Features

* Shorten URLs securely with admin authentication.
* Real-time dashboard showing metrics like user locations and browser types.
* Scalable and reliable architecture with PubSub and GenServer.
* CI/CD pipeline for automated testing and deployment.

## Setup

### Prerequisites

* Elixir and Erlang installed
* PostgreSQL installed and running
* direnv used to manage environment variables locally

### Installation

#### Clone the repo

* Run `git clone` to clone the repo from github

#### Environment Setup

* Run `cp .envrc.example .envrc` to create .envrc file
* Update .envrc with the required variables
* Run `direnv allow` to export variables

#### Install dependencies

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


#### Run the tests

* Run `mix test` to run the tests
* Run `mix coveralls.html` to check the test coverage using the coverage tool



## Development Tools

### Email Preview

In development mode, you can preview sent emails by visiting:

[http://localhost:4000/dev/mailbox](http://localhost:4000/dev/mailbox)

This allows you to test email content (like confirmation links) without actually sending them.
