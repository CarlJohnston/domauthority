Devise.setup do |config|
  config.secret_key = ENV['SECRET_KEY_BASE'] if Rails.env.production?
end
