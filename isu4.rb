module Isu4
  class Cookie
    def initialize
      @data = {}
      r = Nginx::Request.new
      cookie_str  = r.headers_in['Cookie']
      cookie_list = cookie_str.split("; ")
      cookie_list.each do |cookie|
        key, val = cookie.split("=")
        @data[key] = val
      end
    end

    def get(key)
      @data.key?(key) ? @data[key] : nil
    end
  end
end    
