module Isu4
  class Cookie
    def initialize
      @req = {}
      @res = {}
      r = Nginx::Request.new
      cookie_str  = r.headers_in['Cookie']
      cookie_list = cookie_str.split("; ")
      cookie_list.each do |cookie|
        key, val = cookie.split("=")
        @req[key] = val
      end
    end

    def get(key)
      @req.key?(key) ? @req[key] : nil
    end

    def set(key, val)
      @res[key] = val

      hout = Nginx::Headers_out.new

      cookie = ""
      @res.each do |k,v|
        cookie = "#{k}=#{v}; #{cookie}"
      end
      hout["Set-Cookie"] = cookie
    end
  end

  class Redis
    def initialize
      @redis = Redis.new "127.0.0.1", 6379
    end

    def set_last_login(ip, login)
      if @redis.exists?("now_login_#{login}") then
        @redis.hset("last_login_#{login}", "created_at", @redis.hget("now_login_#{login}", "created_at"))
        @redis.hset("last_login_#{login}", "ip", @redis.hget("now_login_#{login}", "ip"))
      end
      @redis.hset("now_login_#{login}", "created_at", Time.now.strftime("%Y-%m-%d %H:%M:%S"))
      @redis.hset("now_login_#{login}", "ip", ip)
    end

    def get_last_login(login)
      @redis.exists?("last_login_#{login}") ? {created_at: @redis.hget("last_login_#{login}", "created_at"), ip: @redis.hget("last_login_#{login}", "ip")} : nil
    end

    def get_user(login)
      @redis.exists?("user_#{login}") ? {login: @redis.hget("user_#{login}", "login"), password_hash: @redis.hget("user_#{login}", "password_hash"), salt: @redis.hget("user_#{login}", "salt")} : nil
    end

    def get_ip_fail(ip)
      @redis.exists?("ip_fail_#{ip}") ? @redis.get("ip_fail_#{ip}") : 0
    end

    def get_user_fail(login)
      @redis.exists?("user_fail_#{login}") ? @redis.get("user_fail_#{login}") : 0
    end

    def incr_ip_fail(ip)
      @redis.incr("ip_fail_#{ip}")
    end

    def incr_user_fail(login)
      @redis.incr("user_fail_#{login}")
    end

    def del_ip_fail(ip)
      @redis.del("ip_fail_#{ip}")
    end

    def del_user_fail(login)
      @redis.del("user_fail_#{login}")
    end
  end

  class Post
    def initialize
      @req = {}
      v = Nginx::Var
      request_body = v.request_body
      post_list = request_body.split("&")
      post_list.each do |post|
        key, val = post.split("=")
        @req[key] = val
      end
    end

    def get(key)
      @req.key?(key) ? @req[key] : nil
    end

end
