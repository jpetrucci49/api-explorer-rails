class GithubController < ApplicationController
  include HTTParty
  base_uri 'https://api.github.com'

  before_action :set_default_headers

  def show
    username = params[:username]
    unless username
      render json: { detail: 'Username is required' }, status: :bad_request
      return
    end

    cache_key = "github:#{username}"
    redis = Redis.new(host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'], password: ENV['REDIS_PASSWORD'])
    cached = redis.get(cache_key)

    if cached
      headers['X-Cache'] = 'HIT'
      render json: JSON.parse(cached)
      return
    end

    response_data = self.class.get("/users/#{username}", headers: { 'Authorization' => "Bearer #{ENV['GITHUB_TOKEN']}" })
    if response_data.success?
      redis.setex(cache_key, 30 * 60, response_data.parsed_response.to_json)
      headers['X-Cache'] = 'MISS'
      render json: response_data.parsed_response
    else
      logger.error "GitHub API error: #{response_data.code} - #{response_data.message}"
      render json: { detail: 'GitHub API error' }, status: response_data.code
    end
  rescue StandardError => e
    logger.error "Failed to reach GitHub: #{e.message}"
    render json: { detail: 'Failed to reach GitHub', error: e.message }, status: :internal_server_error
  end

  private

  def set_default_headers
    headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
    headers['Pragma'] = 'no-cache'
    headers['Expires'] = '0'
    headers['Access-Control-Allow-Origin'] = 'http://localhost:3000'
    headers['Access-Control-Allow-Methods'] = 'GET'
    headers['Access-Control-Allow-Headers'] = '*'
  end
end