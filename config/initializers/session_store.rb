# Be sure to restart your server when you modify this file.

# Fusefm::Application.config.session_store :cookie_store, key: '_fusefm_session'
Rails.application.config.session_store ActionDispatch::Session::CacheStore, :expire_after => 1.year

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Fusefm::Application.config.session_store :active_record_store
