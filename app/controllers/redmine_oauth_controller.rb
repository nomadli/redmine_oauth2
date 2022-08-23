require 'account_controller'
require 'json'

class RedmineOauthController < AccountController
    include Helpers::MailHelper
    include Helpers::Checker
    
    def oauth_oauth2
        if settings[:oauth2_host].empty? || settings[:oauth2_auth].empty? ||
            settings[:oauth2_token].empty? || settings[:oauth2_info].empty? ||
            settings[:client_id].empty? || settings[:client_secret].empty? ||
            settings[:email_key].empty?
            l(:oauth2_setting_err)
            redirect_to signin_path
            return
        end

        if settings[:oauth_authentification]
            session[:back_url] = params[:back_url]
            redirect_to oauth_client.auth_code.authorize_url(:redirect_uri => oauth2_callback_url, :scope => scopes)
        else
            password_authentication
        end
    end

    def oauth2_callback
        if params[:error]
            flash[:error] = l(:notice_access_denied)
            redirect_to signin_path
            return
        end
        
        token = oauth_client.auth_code.get_token(params[:code], {redirect_uri:oauth2_callback_url, client_id:settings[:client_id], client_secret:settings[:client_secret]})
        #Rails.logger.info "o=> code #{token}"

        result = token.get(settings[:oauth2_info])
        info = JSON.parse(result.body)

        root_path = settings[:info_root].split(",")
        root_path.each_with_index do |key, i|
            if !info
                flash[:error] = l(:notice_access_denied)
                redirect_to signin_path
                return
            end
            info = info[key]
        end

        if info && info[settings[:email_key]]
            try_to_login info
        else
            flash[:error] = l(:notice_access_denied)
            redirect_to signin_path
        end
    end

    def try_to_login info
        params[:back_url] = session[:back_url]
        session.delete(:back_url)
        
        email = info[settings[:email_key]]

        fname = ""
        lname = ""
        if settings[:fname_key].length > 0 && settings[:lname_key].length <= 0
            fname, lname = info[settings[:fname_key]].split(' ') unless info[settings[:fname_key]].nil?
        elsif settings[:fname_key].length > 0
            fname = info[settings[:fname_key]]
        end 
        if settings[:fname_key].length <= 0 && settings[:lname_key].length > 0
            fname, lname = info[settings[:lname_key]].split(' ') unless info[settings[:lname_key]].nil?
        elsif settings[:lname_key].length > 0
            lname = info[settings[:lname_key]]
        end
        if fname && !fname.empty? && (!lname || lname.empty?) && fname.length > 1
            lname = fname[-1]
            fname = fname[0..-2]
        end
        if (!fname || fname.empty?) && lname && !lname.empty? && lname.length > 1
            fname = lname[0..-2]
            lname = lname[-1]
        end
            
        login = ""
        if settings[:uid_key].length > 0
            login = info[settings[:uid_key]]
        end
        if login.empty?
            login = parse_email(email)[:login]
            login ||= [fname, lname]*"."
        end

        user = User.find_by_login(login)
        if user && !user.new_record?
            if user.active?
                successful_authentication(user)
                return
            end
            if Redmine::VERSION::MAJOR > 2 || 
                (Redmine::VERSION::MAJOR == 2 && Redmine::VERSION::MINOR >= 4)
                account_pending(user)
            else
                account_pending
            end
        end

        if !Setting.self_registration && !settings[:auto_registration]
            redirect_to(home_url)
            return
        end

        attrs = {
            :firstname => fname,
            :lastname => lname,
            :mail => email,
            :auth_source_id => "redmine_oauth2"
        }
        user = User.new(attrs)
        user.login = login
        user.language = Setting.default_language
        register_automatically(user) do
            onthefly_creation_failed(user)
        end
    end

    def oauth_client
        @client ||= OAuth2::Client.new(settings[:client_id], settings[:client_secret],
        :site => settings[:oauth2_host],
        :authorize_url => settings[:oauth2_auth],
        :token_url => settings[:oauth2_token])
    end

    def settings
        @settings ||= Setting.plugin_redmine_oauth2
    end

    def scopes
        settings[:client_secret]
    end
end
