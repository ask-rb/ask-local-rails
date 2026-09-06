# frozen_string_literal: true

# ask-local integration for this Rails app.
#
# When booted through ask-local, the runner injects ASK_LOCAL_URL
# (e.g. https://fix-ui.myapp.localhost). Use Ask::Local::Rails.url
# anywhere the app must know its own address instead of hardcoding
# localhost:3000:
#
#   # config/environments/development.rb
#   config.action_mailer.default_url_options = {
#     host: Ask::Local::Rails.host
#   }
#
# Nothing to configure here — this file documents the integration.
# See Ask::Local::Rails.host_patterns / .cable_origins for the entries
# the install generator added to config/environments/development.rb.
#
# --- Asset dev servers (Vite-Ruby / Shakapacker) --------------------------
# Run the dev server through ask-local as its own service and let Rails
# assets point at it, avoiding mixed-content and cert juggling:
#
#   ask-local --service webpack -- bin/shakapacker-dev-server
#     -> https://webpack.<app>.localhost
#
#   # config/environments/development.rb
#   config.action_controller.asset_host =
#     proc { |src| "//webpack.#{Ask::Local::Rails.host}" if src.start_with?("/packs") }
#
#   # config/shakapacker.yml (or vite.json): set dev_server.public to
#   # webpack.<app>.localhost and https: false — the proxy terminates TLS.
