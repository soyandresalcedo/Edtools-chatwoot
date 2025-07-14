module FrontendUrlsHelper
  def frontend_url(path, **query_params)
    url_params = query_params.blank? ? '' : "?#{query_params.to_query}"
    "https://#{ENV.fetch('FRONTEND_URL')}/app/#{path}#{url_params}"
  end
end
