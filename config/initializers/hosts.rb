# Render sends its public hostname in the Host header. Development mode
# otherwise rejects anything that is not localhost.
render_host = ENV["RENDER_EXTERNAL_HOSTNAME"].to_s.strip
Rails.application.config.hosts << render_host if render_host.present?
