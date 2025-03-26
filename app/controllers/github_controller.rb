class GithubController < ApplicationController
  include HTTParty
  base_uri 'https://api.github.com'

  def show
    username = params[:username]
    return render json: { detail: 'Username is required' }, status: :bad_request unless username

    response = self.class.get("/users/#{username}")
    if response.success?
      render json: response.parsed_response
    else
      render json: { detail: 'GitHub API error' }, status: response.code
    end
  rescue StandardError
    render json: { detail: 'Failed to reach GitHub' }, status: :internal_server_error
  end
end