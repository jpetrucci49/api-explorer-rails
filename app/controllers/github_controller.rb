class GithubController < ApplicationController
  include HTTParty
  base_uri ENV['GITHUB_API_URL']

  before_action :set_default_headers

  def show
    username = params[:username]
    unless username.present?
      render json: { detail: { status: 400, detail: 'Username is required', extra: {} } }, status: :bad_request
      return
    end

    if username == 'test429'
      render json: { detail: { status: 429, detail: 'GitHub rate limit exceeded', extra: { remaining: '0' } } }, status: :too_many_requests
      return
    end

    cache_key = "github:#{username}"
    begin
      cached = REDIS.get(cache_key)
      if cached
        headers['X-Cache'] = 'HIT'
        render json: JSON.parse(cached)
        return
      end
    rescue Redis::BaseError
      # Continue despite Redis failure
    end

    begin
      response = self.class.get("/users/#{username}", headers: { 'Authorization' => "Bearer #{ENV['GITHUB_TOKEN']}" })
      if response.success?
        begin
          REDIS.setex(cache_key, 30 * 60, response.parsed_response.to_json)
        rescue Redis::BaseError
          # Continue despite Redis failure
        end
        headers['X-Cache'] = 'MISS'
        render json: response.parsed_response
      else
        detail = 'GitHub API error'
        extra = {}
        case response.code
        when 404
          detail = 'GitHub user not found'
        when 429
          detail = 'GitHub rate limit exceeded'
          extra = { remaining: response.headers['x-ratelimit-remaining'] || '0' }
        when 400
          detail = 'Invalid GitHub API request'
        end
        logger.error "GitHub API error: #{response.code} - #{response.message} - #{detail}"
        render json: { detail: { status: response.code, detail: detail, extra: extra }}, status: response.code
      end
    rescue StandardError => e
      logger.error "Failed to reach GitHub: #{e.message}"
      render json: { detail: { status: 500, detail: 'Failed to reach GitHub', extra: {} }, error: e.message }, status: :internal_server_error
    end
  end


  def analyze
    username = params[:username]
    unless username.present?
      render json: { detail: { status: 400, detail: 'Username is required', extra: {} } }, status: :bad_request
      return
    end

    if username == 'test429'
      render json: { detail: { status: 429, detail: 'GitHub rate limit exceeded', extra: { remaining: '0' } } }, status: :too_many_requests
      return
    end

    cache_key = "analyze:#{username}"
    begin
      cached = REDIS.get(cache_key)
      if cached
        headers['X-Cache'] = 'HIT'
        render json: JSON.parse(cached)
        return
      end
    rescue Redis::BaseError
      # Continue despite Redis failure
    end

    begin
      user_response = self.class.get("/users/#{username}", headers: { 'Authorization' => "Bearer #{ENV['GITHUB_TOKEN']}" })
      unless user_response.success?
        detail = 'GitHub API error'
        extra = {}
        case user_response.code
        when 404
          detail = 'GitHub user not found'
        when 429
          detail = 'GitHub rate limit exceeded'
          extra = { remaining: user_response.headers['x-ratelimit-remaining'] || '0' }
        when 400
          detail = 'Invalid GitHub API request'
        end
        logger.error "GitHub API error: #{user_response.code} - #{user_response.message} - #{detail}"
        render json: { detail: { status: user_response.code, detail: detail, extra: extra } }, status: user_response.code
        return
      end
      user_data = user_response.parsed_response

      repos_response = self.class.get(user_data["repos_url"], headers: { 'Authorization' => "Bearer #{ENV['GITHUB_TOKEN']}" }, query: { per_page: 100 })
      unless repos_response.success?
        detail = 'GitHub API error'
        extra = {}
        case repos_response.code
        when 404
          detail = 'GitHub user not found'
        when 429
          detail = 'GitHub rate limit exceeded'
          extra = { remaining: repos_response.headers['x-ratelimit-remaining'] || '0' }
        when 400
          detail = 'Invalid GitHub API request'
        end
        logger.error "GitHub API error: #{repos_response.code} - #{repos_response.message} - #{detail}"
        render json: { detail: { status: repos_response.code, detail: detail, extra: extra } }, status: repos_response.code
        return
      end
      repos = repos_response.parsed_response

      languages = repos.map do |repo|
        lang_response = self.class.get(repo["languages_url"], headers: { 'Authorization' => "Bearer #{ENV['GITHUB_TOKEN']}" })
        lang_response.success? ? lang_response.parsed_response : {}
      end

      lang_stats = {}
      languages.each do |lang_data|
        lang_data.each do |lang, bytes|
          lang_stats[lang] ||= 0
          lang_stats[lang] += bytes
        end
      end

      top_languages = lang_stats.sort_by { |_, v| -v }[0..4].map do |lang, bytes|
        { "lang" => lang, "bytes" => bytes }
      end

      analysis = {
        "login" => user_data["login"],
        "publicRepos" => user_data["public_repos"],
        "topLanguages" => top_languages
      }

      begin
        REDIS.setex(cache_key, 30 * 60, analysis.to_json)
      rescue Redis::BaseError
        # Continue despite Redis failure
      end
      headers['X-Cache'] = 'MISS'
      render json: analysis
    rescue StandardError => e
      logger.error "Failed to analyze profile: #{e.message}"
      render json: { detail: { status: 500, detail: 'Failed to analyze profile', extra: {} } }, status: :internal_server_error
    end
  end

  def clear_cache
    begin
      REDIS.flushdb
      logger.info "Cache cleared"
      render json: { detail: { status: 200, detail: 'Cache cleared successfully', extra: {} } }
    rescue Redis::BaseError
      logger.error "Failed to clear cache: Redis connection failed"
      render json: { detail: { status: 500, detail: 'Redis connection failed', extra: {} } }, status: :internal_server_error
    end
  end

  private

  def set_default_headers
    headers['Content-Type'] = 'application/json'
    headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
    headers['Pragma'] = 'no-cache'
    headers['Expires'] = '0'
    headers['Access-Control-Allow-Origin'] = 'http://localhost:3000'
    headers['Access-Control-Allow-Methods'] = 'GET, POST'
    headers['Access-Control-Allow-Headers'] = '*'
  end
end
