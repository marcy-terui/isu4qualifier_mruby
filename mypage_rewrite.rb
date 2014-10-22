r = Nginx::Request.new

req = {}
cookie_str  = r.headers_in['Cookie']
unless cookie_str.nil? then
  cookie_list = cookie_str.split("; ")
  cookie_list.each do |cookie|
    key, val = cookie.split("=")
    req[key] = val
  end
end

login = req.key?("login") ? req[:login] : nil

if login.nil? then
  hout = Nginx::Headers_out.new
  cookie = "notice=You must be logged in;"
  hout["Set-Cookie"] = cookie
  Nginx.redirect "/", Nginx::HTTP_MOVED_TEMPORARILY
else
  Nginx.return Nginx::DECLINED
end
