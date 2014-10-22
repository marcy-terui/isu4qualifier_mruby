require 'isu4'

v = Nginx::Var

redis  = Isu4::Redis.new
post   = Isu4::Post.new
cookie = Isu4::Cookie.new

login = post.get("login")
pass  = post.get("pass")
ip    = v.http_x_forwarded_for

user = redis.get_user(login)

if redis.get_ip_fail(ip) >= 10 then
  redis.incr_ip_fail(ip)
  redis.incr_user_fail(login) unless login.nil?
  cookie.set("notice", "You're banned.")
  Nginx.redirect "/"
elsif redis.get_user_fail(login) >= 3 then
  redis.incr_user_fail(login)
  cookie.set("notice", "This account is locked.")
  Nginx.redirect "/"
elsif !(user.nil?) && Digest::SHA256.digest("#{pass}:#{user[:salt]}") == user[:password_hash] then
  redis.del_ip_fail(ip)
  redis.del_user_fail(login)
  redis.set_last_login(ip, login)
  cookie.set("login", login)
  Nginx.redirect "/mypage"
else
  cookie.set("notice", "Wrong username or password")
  Nginx.redirect "/"
end
