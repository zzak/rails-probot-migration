require 'net/http'
require 'json'
require 'uri'

GITHUB_TOKEN = ENV["GITHUB_TOKEN"]
SOURCE_REPO = 'rails/rails'
TARGET_REPO_OWNER = 'zzak'
TARGET_REPO_NAME = 'rails-probot-migration'

create_url = URI("https://api.github.com/repos/#{TARGET_REPO_OWNER}/#{TARGET_REPO_NAME}/labels")

headers = {
  'Authorization' => "Bearer #{GITHUB_TOKEN}",
  'Accept' => 'application/vnd.github.v3+json'
}

def fetch_labels(source_repo, headers)
  labels = []
  page = 1

  loop do
    fetch_url = URI("https://api.github.com/repos/#{source_repo}/labels?per_page=100&page=#{page}")
    http = Net::HTTP.new(fetch_url.host, fetch_url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(fetch_url, headers)
    response = http.request(request)

    if response.code == '200'
      page_labels = JSON.parse(response.body)
      labels.concat(page_labels)
      break if page_labels.empty?
    else
      puts "Failed to fetch labels. Status code: #{response.code}"
      break
    end

    page += 1
  end

  labels
end

def create_label(label, create_url, headers)
  http = Net::HTTP.new(create_url.host, create_url.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(create_url, headers)
  request.body = {
    name: label['name'],
    color: label['color'],
    description: label['description'] || ''
  }.to_json
  response = http.request(request)
  if response.code == '201'
    puts "Created label: #{label['name']}"
  elsif response.code == '422'
    puts "Label #{label['name']} already exists."
  else
    puts "Failed to create label #{label['name']}. Status code: #{response.code}"
  end
end

labels = fetch_labels(SOURCE_REPO, headers)
labels.each do |label|
  create_label(label, create_url, headers)
end
