module FrontendUrlsHelper
  def frontend_url(path, **query_params)
    url_params = query_params.blank? ? '' : "?#{query_params.to_query}"
    base_url = ENV['FRONTEND_URL'].present? ? "https://#{ENV['FRONTEND_URL']}" : root_url
    "#{base_url}/app/#{path}#{url_params}"
  end
end
