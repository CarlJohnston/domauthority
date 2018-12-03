Devise.setup do |config|
  config.secret_key = ENV.fetch('SECRET_KEY_BASE') { 'devise_secret' }
end
