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

db.query('SELECT login, ip, succeeded, created_at FROM login_log').each do |log|
  if log['succeeded'] == 1 then
    Redis.current.del("ip_fail_#{log['ip']}")
    Redis.current.del("user_fail_#{log['login']}")
    Redis.current.mapped_hmset("last_login_#{log['login']}", now_login[log['login']]) if now_login.key?(log['login'])
    now_login[log['login']] = log
  else
    Redis.current.incr("ip_fail_#{log['ip']}")
    Redis.current.incr("user_fail_#{log['login']}")
  end
end

db.query('SELECT login, password_hash, salt FROM users').each_slice(10000) do |users|
  fork do
    users.each do |user|
      Redis.current.mapped_hmset("user_#{user['login']}", user)
    end
  end
end

Process.waitall
