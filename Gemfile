source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }
git_source(:entdec) { |repo_name| "git@github.com:entdec/#{repo_name}.git" }

# Declare your gem's dependencies in vario.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use a debugger
# gem 'byebug', group: [:development, :test]
gem "form_components", entdec: "form_components"
# Its record rules aren't released yet: the checkout next to this one,
# mounted in the devcontainer (.devcontainer/docker-compose.yml)
gem "entdec-view_components", entdec: "view_components"

# The dummy app's server and assets
gem "puma"
gem "propshaft"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 4.0"
gem "shipkit"
