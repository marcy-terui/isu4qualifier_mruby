v     = Nginx::Var
hout  = Nginx::Headers_out.new
redis = Redis.new "127.0.0.1", 6379

req = {}
request_body = v.request_body
unless request_body.nil? then
  post_list = request_body.split("&")
  post_list.each do |post|
    key, val = post.split("=")
    req[key] = val
  end
end

login = req.key?("login") ? req[:login] : nil
pass  = req.key?("password") ? req[:password] : nil
ip    = v.http_x_forwarded_for

user = redis.exists?("user_#{login}") ? {login: redis.hget("user_#{login}", "login"), password_hash: redis.hget("user_#{login}", "password_hash"), salt: redis.hget("user_#{login}", "salt")} : nil

ip_fail = redis.exists?("ip_fail_#{ip}") ? redis.get("ip_fail_#{ip}") : 0
if ip_fail >= 10 then
  redis.incr("ip_fail_#{ip}")
  redis.incr("user_fail_#{login}") unless login.nil?
  cookie = "notice=You're banned.;"
  hout["Set-Cookie"] = cookie
  Nginx.redirect "/", Nginx::HTTP_MOVED_TEMPORARILY
end

user_fail = redis.exists?("user_fail_#{login}") ? redis.get("user_fail_#{login}") : 0
if user_fail >= 3 then
  redis.incr("ip_fail_#{ip}")
  redis.incr("user_fail_#{login}")
  cookie = "notice=This account is locked.;"
  hout["Set-Cookie"] = cookie
  Nginx.redirect "/", Nginx::HTTP_MOVED_TEMPORARILY
end

if !(user.nil?) && Digest::SHA256.hexdigest("#{pass}:#{user[:salt]}") == user[:password_hash] then
  redis.del("ip_fail_#{ip}")
  redis.del("user_fail_#{login}")
  if redis.exists?("now_login_#{login}") then
    redis.hset("last_login_#{login}", "created_at", redis.hget("now_login_#{login}", "created_at"))
    redis.hset("last_login_#{login}", "ip", redis.hget("now_login_#{login}", "ip"))
  end
  redis.hset("now_login_#{login}", "created_at", Time.now.strftime("%Y-%m-%d %H:%M:%S"))
  redis.hset("now_login_#{login}", "ip", ip)
  cookie = "login=#{login};"
  hout["Set-Cookie"] = cookie
  Nginx.redirect "/mypage", Nginx::HTTP_MOVED_TEMPORARILY
else
  cookie = "notice=Wrong username or password;"
  hout["Set-Cookie"] = cookie
  Nginx.redirect "/", Nginx::HTTP_MOVED_TEMPORARILY
end
