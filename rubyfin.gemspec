# frozen_string_literal: true

require_relative "lib/rubyfin/version"

Gem::Specification.new do |spec|
  spec.name = "rubyfin"
  spec.version = Rubyfin::VERSION
  spec.authors = ["Dylan Leuschke"]
  spec.email = ["dleuschke@users.noreply.github.com"]

  spec.summary = "A la carte Ruby adapters for free and public financial data sources."
  spec.description = "Rubyfin provides small, composable Ruby adapters for free and public financial data sources, starting with SEC EDGAR."
  spec.homepage = "https://github.com/dleuschke/rubyfin"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*", "docs/**/*", "README.md", "CONTRIBUTING.md", "LICENSE.txt"].select { |path| File.file?(path) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "csv", ">= 3.0"

  spec.add_development_dependency "activerecord", ">= 7.0"
  spec.add_development_dependency "minitest", ">= 5.0"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "sqlite3", ">= 1.4"
end
