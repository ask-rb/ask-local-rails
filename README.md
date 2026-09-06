> **DEPRECATED — fully superseded, nothing needed from this gem.**
>
> - ask-local core injects `RAILS_DEVELOPMENT_HOSTS` per process, so Rails
>   apps boot behind ask-local with zero config — no hosts patch needed.
> - Action Cable works by default behind ask-local: Rails 7+
>   `allow_same_origin_as_host` (default true) accepts the connection when
>   the browser's Origin matches the proxied Host — no origins patch needed.
> - `ask-local init` already generates `config/local.yml` — no generator needed.
> - `Ask::Local::Rails.url` was only a wrapper around `ENV["ASK_LOCAL_URL"]`,
>   which ask-local injects into every process.
>
> Archived at `deprecated/ask-local-rails` for history. No further
> development. Remove this gem from any Gemfile.

# ask-local-rails

[![Gem Version](https://badge.fury.io/rb/ask-local-rails.svg)](https://badge.fury.io/rb/ask-local-rails)

Rails integration for [ask-local](https://github.com/ask-rb/ask-local).
Railtie, install generator, and helpers wiring a Rails app into stable
`https://<app>.localhost` URLs. Requires Rails 7.1+.

## Installation

```ruby
gem "ask-local-rails"
```

```bash
bundle install
rails generate ask_local:install
```

The generator:

- creates `config/initializers/ask_local.rb`
- allows `.localhost` hosts + Cable origins in `development.rb`
- rewrites hardcoded `-p 3000` to `-p $PORT` in `Procfile.dev`/`Procfile`
  (compound lines it cannot classify are left alone with a warning)
- creates an empty `ask-local.json` if missing

## Helpers

```ruby
Ask::Local::Rails.url    # => "https://fix-ui.myapp.localhost" (or fallback)
Ask::Local::Rails.host   # => "fix-ui.myapp.localhost"
Ask::Local::Rails.proxied?  # => true when booted through ask-local
```

Use `url` for mailer hosts, OmniAuth callbacks, and webhook targets —
never hardcode `localhost:3000`.

## Agent skill

Ships `local_dev` under `ask/skills/` (auto-discovered by ask-skills):
boot via `ask-local`, wire via `ask-local get`, callbacks from
`ASK_LOCAL_URL`, `doctor`/`list`/`prune` for troubleshooting.

## Development

```bash
bundle install
bundle exec rake test
```

## License

MIT
