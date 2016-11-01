floodgate for mahjong（仮）
===========================

麻雀のAI同士を対戦させ、成績を比較する対局場を作成するプロジェクトです。
http://mjai.hocha.org/


各ディレクトリの説明
--------------------

* mjai/
 gimiteさん作成の麻雀サーバープログラム (Ruby) に修正を加えたものです。
 本プロジェクトで管理するサーバー上で動作しているプログラムです。
 
 元プロジェクト（修正BSDライセンス）
 http://gimite.net/pukiwiki/index.php?Mjai%20%CB%E3%BF%FDAI%C2%D0%C0%EF%A5%B5%A1%BC%A5%D0

 実行コマンド（カレントディレクトリに注意）
 $ ./bin/multisrv.rb

* MjaiForms/
 wistery_kさん作成の、mjaiプロトコルに対応した人間用クライアントに修正を加えたものです。
 C# で作成されています。
 同梱の牌画は「雀のお宿」で配布されている、完全フリーの素材です。
 
 元プロジェクト
 http://d.hatena.ne.jp/wistery_k/20121102/1351845850
 
 牌画
 http://suzume.hakata21.com/5zats/haiga43.html

*tsumogiri
接続テスト用のツモ切りを行うプレイヤです。
g++のコンパイラが必要です。
実行コマンド
$make
$./main

* transmau_ws/
 「まうじゃん」Windows版のAPIを実装した、DLL形式の麻雀AIを、mjaiサーバーに接続するためのラッパースクリプトです。
 Ruby で作成されていますが、Windowsでのみ動作します。

1. http://shokai.org/blog/archives/7223 からwebsocket-client-simple をインストール
2. RubyInstaller のページから、Ruby 2.1.x（x64と書いていないもの）をダウンロードし、インストールする（現時点では Ruby 2.1.7）。インストール中、インストール先の指定画面にある「Ruby への実行ファイルへ環境変数 PATH を設定する」にチェックを入れる
3. コマンド プロンプトで gem install bundler sass nokogiri を実行
4. 本プロジェクトのソースファイル mjai_flood_○○○_○○○○.zip を展開し、mjai_flood\transmau\MaujongPlugin ディレクトリ内に「まうじゃん」のDLLファイルを置く（例えば Akagi_1.0.dll とします）
5. mjai_flood\transmau をカレントディレクトリとして、 ruby test.rb Akagi_1.0 を実行


* public_html/
 牌譜・成績等を閲覧するための、Webサイトのコードです。
 牌譜ビューアは、gimiteさんのmjaiプロジェクト内のものです。

 index.cgi と同じディレクトリ内に mjlog へのシンボリックリンクを張る

* 試合結果
　http://www.logos.t.u-tokyo.ac.jp/mjlog/


* protocol.txt
　麻雀サーバーでやり取りするメッセージの形式を書いています。
