require 'redmine'

plugin_name = :redmine_oauth2
plugin_root = File.dirname(__FILE__)

unless defined?(SmileTools)
    require plugin_root + '/lib/redmine_oauth2/hooks'
end

Redmine::Plugin.register :redmine_oauth2 do
    name 'Redmine oauth2.0 plugin'
    author 'nomadli'
    description 'This is a plugin for Redmine registration through oauth2.0'
    version '0.0.1'
    url 'https://github.com/nomadli/redmine_oauth2'
    author_url 'http://nomadli.github.io'

    settings :default => {
        :oauth2_host => "",
        :oauth2_auth => "",
        :oauth2_token => "",
        :oauth2_info => "",
        :client_id => "",
        :client_secret => "",
        :oauth_autentification => false,
        :email_key => "",
        :uid_key => "",
        :fname_key => "",
        :lname_key => ""
    }, :partial => 'settings/oauth2_settings'
end
