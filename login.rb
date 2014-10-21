require 'isu4'

v = Nginx::Var

redis  = Isu4::Redis.new
post   = Isu4::Post.new
cookie = Isu4::Cookie.new

login = post.get("login")
pass  = post.get("pass")
ip    = v.http_x_forwarded_for

user = redis.get_user(login)

if redis.get_ip_banned(ip) >= 10 then
  cookie.set("notice", "You're banned.")
  Nginx.redirect "/"
elsif redis.get_user_banned(login) >= 3 then
  cookie.set("notice", "This account is locked.")
  Nginx.redirect "/"
elsif !(user.nil?) && Digest::SHA256.digest("#{pass}:#{user[:salt]}") == user[:password_hash] then
  cookie.set("login", login)
  Nginx.redirect "/mypage"
else
  cookie.set("notice", "Wrong username or password")
  Nginx.redirect "/"
end
