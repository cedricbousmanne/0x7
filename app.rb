require 'sinatra'
require 'pry'

get '/' do
  send_file "readme.md"
end

post '/short' do
  domain = "#{request.scheme}://#{request.host}"
  if (request.scheme == "http" and request.port != 80) or (request.scheme == "https" and request.port != 443)
    domain += ":#{request.port}"
  end

  "#{domain}/foo"
end
