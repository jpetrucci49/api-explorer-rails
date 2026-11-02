require 'redis'

REDIS = Redis.new(
  host: ENV.fetch("REDIS_HOST", "localhost"),
  port: ENV.fetch("REDIS_PORT", 6379).to_i,
  password: ENV["REDIS_PASSWORD"],
  timeout: 3,
  reconnect_attempts: 0
)