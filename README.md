## This is a general oauth 2.0 login redmine5.0 plug-in

![](doc/img/settings.png)
![](doc/img/login.png)


## 0.0.1  Only oauth2.0 with all APIs under the same domain name is supported
## 0.0.2  Support user information under the new domain name

## google oauth2
- 0.0.1 not super
- Host: https://accounts.google.com
- Auth: /o/oauth2/auth
- Token: /o/oauth2/token
- User Info: https://www.googleapis.com/oauth2/v1/userinfo
- Email key: email
- UID: name or empty
- Fist name name or given_name or family_name

## install 
```console
apt-get install -y make gcc git | yum install -y make gcc git
cd x/redmine/plugins
git clone https://github.com/nomadli/redmine_oauth2
cd x/redmine
bundle install --without development test
rake redmine:plugins:migrate RAILS_ENV=production
touch x/redmine/tmp/restart.txt
```
