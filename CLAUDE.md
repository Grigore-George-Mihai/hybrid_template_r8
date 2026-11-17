# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hybrid Rails 8.1 template combining a standard Rails app (controllers/views) with a Grape-based JSON API mounted at `/api/v1`. Ruby 3.4.12. Authentication is Devise with JWT for the API surface (`devise-jwt`, JTI revocation strategy on `User`).

## Common Commands

**Development**
- `bin/setup` — install gems, prepare DB, start dev server (Procfile.dev runs `rails server` + `tailwindcss:watch`)
- `bin/setup --skip-server` — same as above without launching the server
- `bin/dev` — start the dev server (wraps `rails server`)
- `bin/rails setup:rename_app` — rename the app module/DB/cable prefixes everywhere
- `bin/rails setup:copy_env` — copy `.env.*.template` → `.env.*` (run by `bin/setup`; deliberately has no `:environment` dependency, because booting requires `DEVISE_JWT_SECRET_KEY` from the file it creates)

**Tests (RSpec — no fixtures, FactoryBot only)**
- `bundle exec rspec` — full suite
- `bundle exec rspec spec/path/to/file_spec.rb` — single file
- `bundle exec rspec spec/path/to/file_spec.rb:42` — single example by line
- `bundle exec rspec --only-failures` — rerun failures (status in `spec/examples.txt`; order is random, reproduce with `--seed`)
- System specs use the built `app/assets/builds/tailwind.css` (not committed). Run `bin/rails tailwindcss:build` (or `test:prepare`) after changing classes, or keep `bin/dev` running, or layout specs fail against stale CSS.

**Lint / security / CI**
- `bin/ci` — full CI pipeline locally (setup → rubocop → bundler-audit → importmap audit → brakeman → rspec → seeds replant). Definition in `config/ci.rb`.
- `bin/rubocop` — linter (uses `rubocop-rails-suite`; cache at `tmp/rubocop`)
- `bin/brakeman --no-pager` — static security analysis
- `bin/bundler-audit` — gem CVE scan
- `bin/importmap audit` — JS dependency audit

**Scaffolding API endpoints**
- `rails generate grape_resource <Name> field:type ...` — generates resource, entity, spec; auto-mounts into `app/api/v1/api.rb` and registers entity in `app/api/api_root.rb` Swagger models. Optionally also runs `rails g model`.

## Architecture

**Dual app surface**
- Web (Rails): `app/controllers/`, `app/views/`, root `home#index`. `ApplicationController` requires auth for everything via `before_action :authenticate_user!` and permits `first_name`/`last_name` for Devise sign-up/account-update.
- API (Grape): mounted at `/` via `mount ApiRoot => "/"` in `config/routes.rb`. `ApiRoot` (`app/api/api_root.rb`) mounts `V1::Api` (which sets `version "v1", using: :path`, `format :json`, `prefix :api`, so endpoints live under `/api/v1/...`) and configures Swagger docs at `/swagger_doc`. Swagger UI is mounted at `/swagger` in development only.

**API error handling**
- `app/controllers/concerns/error_handler.rb` is `include`d into `ApiRoot` and uses Grape's `rescue_from` to map `ActiveRecord::RecordNotFound/RecordInvalid`, `Grape::Exceptions::ValidationErrors`, JWT errors, and a catch-all to JSON error bodies. All new Grape resources inherit this automatically through the mount hierarchy — don't re-implement rescue logic per resource.

**API auth**
- `ApiAuthHelpers` (`app/helpers/api_auth_helpers.rb`) is registered via `helpers ApiAuthHelpers` in `V1::Api`. `current_user` decodes the `Authorization: Bearer <jwt>` header using `Warden::JWTAuth::UserDecoder`; `authenticate_user!` calls `error!("401 Unauthorized", 401)` when missing. Login/register in `V1::Resources::Auth` uses `env["warden"].set_user(user, store: false)` then reads `request.env["warden-jwt_auth.token"]` — this is the pattern for issuing JWTs without creating a session.
- `User` includes `Devise::JWT::RevocationStrategies::JTIMatcher` (self-referential — the `jti` column on the users table tracks revocation).

**Pagination**
- `ApiAuthHelpers#paginated_response(collection, entity)` wraps Pagy. Returns `{ <plural model name> => [...], pagy: {...} }`. Use this in every index action rather than rolling your own.

**Admin-gated mounts**
- `/sidekiq` and `/pghero` are wrapped in `authenticate :user, ->(user) { user.admin? }`. `User#role` is an enum `{ user: 0, admin: 1 }` with `validate: true`.

**Background jobs**
- Sidekiq with queues `%w[critical default mailers maintenance]`, concurrency 5. Redis URL from `REDIS_SIDEKIQ_URL` (default `redis://localhost:6379/1`).
- `sidekiq-scheduler` config in `config/scheduler/production.yml`. Scheduled jobs live in `app/sidekiq/` (e.g. `pg/capture_query_stats_job.rb` for PgHero).
- Active Job is routed to Sidekiq (`config.active_job.queue_adapter = :sidekiq` in `config/application.rb`), overridden to `:test` in `config/environments/test.rb`; `deliver_later` mail goes to the `mailers` queue. Queues for `app/sidekiq/` jobs come from their `sidekiq_options`, not the scheduler YAML.
- Solid Queue is installed but opt-in (commented lines in the environment files; see README "Switching to Solid Queue"). Production Kamal runs Sidekiq as the `job` role with a `redis` accessory.
- Development mail is delivered to Letter Opener Web at `/letter_opener`.

**Content Security Policy**
- Enforced in `config/initializers/content_security_policy.rb` (`script-src 'self'` + nonce). The nonce is stored in the session so it is present on a visitor's first request and stable across sign-in. It is skipped for `/api/` paths so the stateless JWT API never gets a session cookie. Third-party scripts need their host added to `script-src`.

**Test setup**
- `spec/rails_helper.rb` auto-requires everything in `spec/support/**/*.rb`. That directory wires up FactoryBot, Shoulda Matchers, Bullet, SimpleCov, Capybara, and `Sidekiq::Job.clear_all` before each example. Don't redeclare these per-spec.
- Request specs get both helper sets: Devise's `sign_in user` (session, for web routes) and `HelpersConfig` (`spec/support/helpers_config.rb`) for the API: `api_sign_in(user)` returns a JWT, `authenticate_request(user)` returns the `Authorization` header, plus `response_body`.
- System specs run in headless Chrome; tag a spec `:mobile` to run it at phone size (`spec/support/capybara_config.rb`).
- Spec tree mirrors source: `spec/api/v1/...`, `spec/requests/`, `spec/system/`, `spec/sidekiq/pg/...`, `spec/models/`, `spec/helpers/`.

## Conventions

- `.rubocop.yml` inherits from `rubocop-rails-suite` and targets Ruby 3.4. Use hash enums (`{ user: 0, admin: 1 }`) so reordering values can't change stored integers.
- Frozen string literals at the top of every `.rb` file (see existing files).
- When adding a new API endpoint, prefer the `grape_resource` generator over hand-writing files — it keeps the mount list and Swagger models registry consistent.
- New Grape entities go in `app/api/v1/entities/` and must be added to `ApiRoot`'s `models:` array to appear in Swagger (the generator does this automatically).
