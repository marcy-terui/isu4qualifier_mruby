require 'redis'
require 'mysql2'

db = Mysql2::Client.new(
  host: 'localhost',
  username: 'root',
  database: 'isu4_qualifier'
)

Redis.current.flushall

now_login = {}
users     = {}

db.query('SELECT login, ip, succeeded, created_at FROM login_log').each do |login, ip, succeeded, created_at|
  if succeeded == 1 then
    Redis.current.del("ip_fail_#{ip}")
    Redis.current.del("user_fail_#{login}")
    Redis.current.hmset("last_login_#{login}", now_login[login].to_a.flatten) if now_login.key?(login)
    now_login[login] = {created_at: created_at, ip: ip}
  else
    Redis.current.incr("ip_fail_#{ip}")
    Redis.current.incr("user_fail_#{login}")
  end
end

db.query('SELECT login, password_hash, salt FROM users').each_slice(10000) do |users|
  fork do
    users.each do |user|
      Redis.current.hmset("user_#{user[:login]}", user.to_a.flatten)
    end
  end
end

Process.waitall
