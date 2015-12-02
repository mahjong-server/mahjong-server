#!/usr/bin/ruby

require 'json'
require 'time'
require 'cgi'

def parsedate(str)
	return Time.strptime(str, "%Y-%m-%d-%H%M%S")
end
def fulltime(str)
	return parsedate(str).strftime("%Y-%m-%d %H:%M:%S")
end
def onlytime(str)
	return parsedate(str).strftime("%H:%M:%S")
end


puts "Content-Type: text/html; charset=UTF-8"
puts

puts <<"HTMLDOC"
<html>
<head>
<title>麻雀AIレーティング</title>
<meta name="robots" content="noindex, nofollow" />

<style type="text/css">

table {
border-collapse: collapse;
border: 1px #1C79C6 solid;
}

th, td {
border: 1px #1C79C6 solid;
padding: 2px;
} 

</style>

</head>
<body>

<h1>floodgate for mahjong（仮）</h1>
<p>接続先：mjsonp://mjai.hocha.org:11600/default</p>

<ul>
<li>gimiteさん作 <a href="http://gimite.net/pukiwiki/index.php?Mjai%20%CB%E3%BF%FDAI%C2%D0%C0%EF%A5%B5%A1%BC%A5%D0">mjaiプロトコル</a> に対応した麻雀AI自動対戦サーバー（になる予定）です。</li>
<li>東風戦、喰いタン・赤あり</li>
<li>Visual Studioを入れていないひとのために<a href="MjaiForms_bin.zip">人間用クライアントのバイナリ</a>（<a href="http://d.hatena.ne.jp/wistery_k/20121102/1351845850">オリジナル</a>）を置きます。役なし・フリテン和了、喰い替え等のチェックをしていないので、要注意。</li>
<li>AIは3人走らせているので、すぐ卓が立つはずです。</li>
<li><a href="./mjlog/stat.txt">生ログ stat.txt</a></li>
</ul>

HTMLDOC

list = {}

log = open("./mjlog/stat.txt", "r")
while line = log.gets
	js = JSON.parse(line)
	
	if !js["type"] then
		next
	end
	
	if js["type"] == "start" then
		list[js["idtime"]] = js
		list[js["idtime"]]["player"].map!{|s| CGI.escapeHTML(s)}
	else
		if list.has_key?(js["idtime"]) then
			list[js["idtime"]].merge!(js)
		else
			puts "Error: " + js["idtime"] + "<br />"
		end
	end
end
log.close

revlist = list.values.sort_by{|k| k["idtime"]}.reverse

puts "<table>"
puts "<tr><th>開始日時</th><th>終了</th><th>1位</th><th>（得点）</th><th>2位</th><th>（得点）</th><th>3位</th><th>（得点）</th><th>4位</th><th>（得点）</th><th>mjlog</th><th>牌譜</th></tr>"


revlist.find_all{|l| l["type"] == "start"}.each do |pp|
	puts "<tr><td>" + fulltime(pp["idtime"]) + "</td><td>対局中</td><td>" + pp["player"].join("</td><td>-</td><td>") + "</td><td>-</td><td>-</td><td>-</td></tr>"
end

revlist.each do |pp|
	if pp["type"] == "start" then
		next
	end
	
	if pp["type"] == "finish" then
		score = pp["player"].zip(pp["score"]).sort_by{|s| s[1]}.reverse
		puts "<tr><td>" + fulltime(pp["idtime"]) + "</td><td>" + onlytime(pp["time"]) + "</td>"
		score.each do |s|
			print("<td>" + s[0] + "</td><td align='right'>" + s[1].to_s + "</td>")
		end
		puts "<td><a href='mjlog/" + pp["idtime"]  + ".mjson'>json</a></td><td><a href='mjlog/" + pp["idtime"]  + ".mjson.html'>表示</a></td></tr>"
	elsif pp["type"] == "error" then
		puts "<tr><td rowspan='2'>" + fulltime(pp["idtime"]) + "</td><td><span title=\"" + CGI.escapeHTML(pp["message"]) + "\">エラー" + (pp["criminal"]+1).to_s + "</span></span></td><td>" + pp["player"].join("</td><td>-</td><td>") + "</td><td>-</td><td><a href='mjlog/" + pp["idtime"]  + ".mjson'>json</a></td><td><a href='mjlog/" + pp["idtime"]  + ".mjson.html'>表示</a></td></tr>"
		puts "<tr><td colspan='11'>" + ((pp["criminal"]!=-1) ? pp["player"][pp["criminal"]] : "Server Error") + ": " + CGI.escapeHTML(pp["message"]) + "</td></tr>"

	end
end
	
puts "</table>"

puts "</body>"
puts "</html>"
