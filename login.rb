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

login = req.key?("login") ? req['login'] : nil
pass  = req.key?("password") ? req['password'] : nil
ip    = r.var.remote_addr

user = redis.exists?("user_#{login}") ? {'login' => redis.hget("user_#{login}", "login"), 'password_hash' => redis.hget("user_#{login}", "password_hash"), 'salt' => redis.hget("user_#{login}", "salt")} : nil

ip_fail = redis.exists?("ip_fail_#{ip}") ? redis.get("ip_fail_#{ip}").to_i : 0
if ip_fail >= 10 then
  redis.incr("ip_fail_#{ip}")
  redis.incr("user_fail_#{login}") unless login.nil?
  redis.close
  Nginx.redirect "http://#{r.var.http_host}/?notice=You're+banned.", Nginx::HTTP_MOVED_TEMPORARILY
end

user_fail = redis.exists?("user_fail_#{login}") ? redis.get("user_fail_#{login}").to_i : 0
if user_fail >= 3 then
  redis.incr("ip_fail_#{ip}")
  redis.incr("user_fail_#{login}")
  redis.close
  Nginx.redirect "http://#{r.var.http_host}/?notice=This+account+is+locked.", Nginx::HTTP_MOVED_TEMPORARILY
end

if !(user.nil?) && Digest::SHA256.hexdigest("#{pass}:#{user['salt']}") == user['password_hash'] then
  redis.del("ip_fail_#{ip}")
  redis.del("user_fail_#{login}")
  if redis.exists?("now_login_#{login}") then
    redis.hset("last_login_#{login}", "created_at", redis.hget("now_login_#{login}", "created_at"))
    redis.hset("last_login_#{login}", "ip", redis.hget("now_login_#{login}", "ip"))
  end
  year  = Time.now.year
  month = Time.now.month
  day   = Time.now.day
  hour  = Time.now.hour
  min   = Time.now.min
  sec   = Time.now.sec

  month = month < 10 ? "0#{month.to_s}" : month.to_s
  day   = day < 10 ? "0#{day.to_s}" : day.to_s
  hour  = hour < 10 ? "0#{hour.to_s}" : hour.to_s
  min   = min < 10 ? "0#{min.to_s}" : min.to_s
  sec   = sec < 10 ? "0#{sec.to_s}" : sec.to_s

  redis.hset("now_login_#{login}", "created_at", "#{year}-#{month}-#{day} #{hour}:#{min}:#{sec}")
  redis.hset("now_login_#{login}", "ip", ip)
  redis.close
  Nginx.redirect "http://#{r.var.http_host}/mypage?login=#{login}", Nginx::HTTP_MOVED_TEMPORARILY
else
  redis.close
  Nginx.redirect "http://#{r.var.http_host}/?notice=Wrong+username+or+password", Nginx::HTTP_MOVED_TEMPORARILY
end
