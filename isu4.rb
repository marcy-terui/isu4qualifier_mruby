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

    def get_last_login(login)
#      @redis.exists?(key) ? @redis.get("last_login_#{login}") : nil
      @redis.get("last_login_#{login}")
    end

    def get_user(login)
      @redis.get("user_#{login}")
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
