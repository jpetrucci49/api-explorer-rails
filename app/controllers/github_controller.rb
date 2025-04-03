class GithubController < ApplicationController
  include HTTParty
  base_uri 'https://api.github.com'

  # In-memory cache
  CACHE = {}
  CACHE_TTL = 30 * 60 # 30 minutes in seconds

  before_action :set_default_headers

  def show
    username = params[:username]
    unless username
      render json: { detail: 'Username is required' }, status: :bad_request
      return
    end

    cache_key = "github:#{username}"
    cached = CACHE[cache_key]

    if cached && (Time.now.to_f - cached[:timestamp]) < CACHE_TTL
      headers['X-Cache'] = 'HIT'
      render json: cached[:data]
      return
    end

    response_data = self.class.get("/users/#{username}", headers: { 'Authorization' => "Bearer #{ENV['GITHUB_TOKEN']}" })
    if response_data.success?
      CACHE[cache_key] = { data: response_data.parsed_response, timestamp: Time.now.to_f }
      headers['X-Cache'] = 'MISS'
      render json: response_data.parsed_response
    else
      render json: { detail: 'GitHub API error' }, status: response_data.code
    end
  rescue StandardError
    render json: { detail: 'Failed to reach GitHub' }, status: :internal_server_error
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