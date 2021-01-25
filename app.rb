require 'sinatra'
require 'pry'
require 'rom'
require 'rom-sql'

SLUG_RANGE = (1..5)

@@rom = ROM.container(:sql, 'sqlite::memory') do |config|
  config.default.create_table(:links) do
    # primary_key :slug
    column :url, String, null: false, unique: true
    column :slug, String, null: false, unique: true
  end

  class Links < ROM::Relation[:sql]
    UUID = Types::String.default { SecureRandom.uuid }
    schema(infer: true) do
      attribute :slug, UUID
    end
  end

  config.register_relation(Links)

  class LinkRepo < ROM::Repository[:links]
    commands :create

    def by_slug(slug)
      links.where(slug: slug).one
    end

    def by_url(url)
      links.where(url: url).one
    end
  end
end


get '/' do
  send_file "readme.md", disposition: "inline", type: "text/plain"
end

get '/index.html' do
  markdown File.read("readme.md")
end

get '/u/:slug' do
  link_repo = LinkRepo.new(@@rom)
  link = link_repo.by_slug(params[:slug])
  if link.nil?
    # render 404
    status 404
    body "Not found"
  else
    # redirect to url
    redirect link.url, 301
    body link.url
  end
end

post '/u' do
  link_repo = LinkRepo.new(@@rom)
  url = params[:url]
  # binding.pry
  if link_repo.by_url(url).nil?
    # url does not exists yet
    slug = SecureRandom.uuid[SLUG_RANGE]
    until link_repo.by_slug(slug).nil?
      slug = SecureRandom.uuid[SLUG_RANGE]
    end

    # save the object and return the slug
    link_repo.create({ url: url, slug: slug })
  else
    # fetch existing object
    slug = link_repo.by_url(url).slug
  end
  domain = "#{request.scheme}://#{request.host}"
  if (request.scheme == "http" and request.port != 80) or (request.scheme == "https" and request.port != 443)
    domain += ":#{request.port}"
  end

  "#{domain}/u/#{slug}"
end
