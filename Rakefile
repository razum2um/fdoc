require "rake"
require "bundler"; Bundler.setup
require "rspec/core/rake_task"
require 'pry-debugger'

RSpec::Core::RakeTask.new(:spec)

task :c do
  require 'fdoc'
  ARGV.clear
  Pry.start
end

###

require 'pathname'
require 'logger'
require 'fileutils'
require 'sprockets'
require 'sass'
#require 'jquery-rails'
#require 'bootstrap-sass'
#require 'remotipart'

ROOT        = Pathname(File.dirname(__FILE__))
LOGGER      = Logger.new(STDOUT)
BUNDLES     = %w( application.css application.js )
BUILD_DIR   = ROOT.join("lib/fdoc/templates/public")
SOURCE_DIR  = ROOT.join("lib/fdoc/templates")

task :compile do
  FileUtils.rm_rf(BUILD_DIR)
  FileUtils.mkdir_p(BUILD_DIR)

  sprockets = Sprockets::Environment.new(ROOT) do |env|
    env.logger = LOGGER
  end

  sprockets.context_class.class_eval do
    def asset_path(path, options = {})
      '/'
    end
  end

  sprockets.append_path(SOURCE_DIR.join('javascripts').to_s)
  sprockets.append_path(SOURCE_DIR.join('stylesheets').to_s)

  %w[jquery-rails bootstrap-sass remotipart].each do |gem|
    gem_path = Pathname.new(Bundler.rubygems.find_name(gem).first.full_gem_path)
    %w[javascripts stylesheets].each do |prefix|
      sprockets.append_path(gem_path.join('vendor', 'assets', prefix).to_s)
    end
  end

  BUNDLES.each do |bundle|
    assets = sprockets.find_asset(bundle)
    realname = (assets.pathname.basename.to_s.split(".").take_while { |s| !s.match /^(js|css)$/ } + [$~.to_s]).join(".")
    assets.write_to(BUILD_DIR.join(realname))
  end
end

task :default => :spec
