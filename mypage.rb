r     = Nginx::Request.new
redis = Redis.new "127.0.0.1", 6379

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

last_login = redis.exists?("last_login_#{login}") ? {created_at: redis.hget("last_login_#{login}", "created_at"), ip: redis.hget("last_login_#{login}", "ip")} : {}

created_at = last_login[:created_at]
ip         = last_login[:ip]
login      = last_login[:login]

html = <<-EOH
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <link rel="stylesheet" href="/stylesheets/bootstrap.min.css">
    <link rel="stylesheet" href="/stylesheets/bootflat.min.css">
    <link rel="stylesheet" href="/stylesheets/isucon-bank.css">
    <title>isucon4</title>
  </head>
  <body>
    <div class="container">
      <h1 id="topbar">
        <a href="/"><img src="/images/isucon-bank.png" alt="いすこん銀行 オンラインバンキングサービス"></a>
      </h1>
      <div class="alert alert-success" role="alert">
        ログインに成功しました。<br>
        未読のお知らせが０件、残っています。
      </div>

      <dl class="dl-horizontal">
        <dt>前回ログイン</dt>
        <dd id="last-logined-at">#{created_at}</dd>
        <dt>最終ログインIPアドレス</dt>
        <dd id="last-logined-ip">#{ip}</dd>
      </dl>

      <div class="panel panel-default">
        <div class="panel-heading">
        お客様ご契約ID：#{login} 様の代表口座
        </div>
        <div class="panel-body">
          <div class="row">
            <div class="col-sm-4">
              普通預金<br>
              <small>東京支店　1111111111</small><br>
            </div>
            <div class="col-sm-4">
              <p id="zandaka" class="text-right">
                ―――円
              </p>
            </div>

            <div class="col-sm-4">
              <p>
                <a class="btn btn-success btn-block">入出金明細を表示</a>
                <a class="btn btn-default btn-block">振込・振替はこちらから</a>
              </p>
            </div>

            <div class="col-sm-12">
              <a class="btn btn-link btn-block">定期預金・住宅ローンのお申込みはこちら</a>
            </div>
          </div>
        </div>
      </div>
    </div>

  </body>
</html>
EOH

Nginx.echo html
Nginx.return Nginx::HTTP_OK
