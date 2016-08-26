# Build a gem for RubyGems.org with user dropbox-api-team
# gem build dropbox-sdk.rb
# gem push dropbox-sdk-x.x.x.gem

Gem::Specification.new do |s|
  s.name = "dropbox-sdk-forked_v2"

  s.version = "1.0.1"
  s.license = 'MIT'

  s.authors = ["Greg Merritt"]
  s.email = ["gremerritt@gmail.com"]

  s.add_dependency "json", "~> 1.8"

  s.add_development_dependency "minitest", "~> 4.3"
  s.add_development_dependency "rake", "~> 11.2"
  s.add_development_dependency "test-unit", "~> 3.2"

  s.homepage = "http://www.dropbox.com/developers/"
  s.summary = "Dropbox REST API Client for API V2."
  s.description = <<-EOF
    A library that provides a plain function-call interface to the
    Dropbox API web endpoints.
  EOF

  s.files = [
    "CHANGELOG", "LICENSE", "README.md", "Rakefile",
    "examples/cli_example.rb", "examples/dropbox_controller.rb", "examples/web_file_browser.rb",
    "examples/copy_between_accounts.rb", "examples/chunked_upload.rb", "examples/oauth1_upgrade.rb",
    "examples/search_cache.rb",
    "lib/dropbox_sdk_v2.rb", "lib/trusted-certs.crt",
  ]
end
