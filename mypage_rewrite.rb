r = Nginx::Request.new

req = {}
cookie_str  = r.headers_in['Cookie']
unless cookie_str.nil? then
  cookie_list = cookie_str.split("; ")
  cookie_list.each do |cookie|
    key, val = cookie.split("=")
    req[key] = val.gsub("+", " ")
  end
end

login = req.key?("login") ? req[:login] : nil

if login.nil? then
  cookie = "notice=You+must+be+logged+in; path=/"
  r.headers_out["Set-Cookie"] = cookie
  Nginx.redirect "/", Nginx::HTTP_MOVED_TEMPORARILY
else
  Nginx.return Nginx::DECLINED
end
