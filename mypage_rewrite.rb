r = Nginx::Request.new

req = {}
args = r.args
unless args.nil? then
  arg_list = args.split("&")
  arg_list.each do |arg|
    key, val = arg.split("=")
    if val.nil? then
      req[key] = ""
    else
      req[key] = val.gsub("+", " ")
    end
  end
end

login = req.key?("login") ? req['login'] : nil

if login.nil? then
  Nginx.redirect "http://#{r.var.http_host}/?notice=You+must+be+logged+in", Nginx::HTTP_MOVED_TEMPORARILY
else
  Nginx.return Nginx::DECLINED
end
