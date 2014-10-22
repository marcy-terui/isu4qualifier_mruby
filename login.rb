r     = Nginx::Request.new
redis = Redis.new "127.0.0.1", 6379

req = {}
request_body = r.var.request_body
unless request_body.nil? then
  post_list = request_body.split("&")
  post_list.each do |post|
    key, val = post.split("=")
    req[key] = val
  end
end

login = req.key?("login") ? req[:login] : nil
pass  = req.key?("password") ? req[:password] : nil
ip    = r.var.http_x_forwarded_for

user = redis.exists?("user_#{login}") ? {login: redis.hget("user_#{login}", "login"), password_hash: redis.hget("user_#{login}", "password_hash"), salt: redis.hget("user_#{login}", "salt")} : nil

ip_fail = redis.exists?("ip_fail_#{ip}") ? redis.get("ip_fail_#{ip}").to_i : 0
if ip_fail >= 10 then
  redis.incr("ip_fail_#{ip}")
  redis.incr("user_fail_#{login}") unless login.nil?
  redis.close
  Nginx.redirect "/?notice=You're+banned."
  Nginx.return Nginx::HTTP_MOVED_TEMPORARILY
end

user_fail = redis.exists?("user_fail_#{login}") ? redis.get("user_fail_#{login}").to_i : 0
if user_fail >= 3 then
  redis.incr("ip_fail_#{ip}")
  redis.incr("user_fail_#{login}")
  redis.close
  Nginx.redirect "/?notice=This+account+is+locked."
  Nginx.return Nginx::HTTP_MOVED_TEMPORARILY
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
  redis.close
  Nginx.redirect "/mypage?login=#{login}"
  Nginx.return Nginx::HTTP_MOVED_TEMPORARILY
else
  redis.close
  Nginx.redirect "/?notice=Wrong+username+or+password"
  Nginx.return Nginx::HTTP_MOVED_TEMPORARILY
end
