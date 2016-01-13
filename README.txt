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


* MjaiForms/
 wistery_kさん作成の、mjaiプロトコルに対応した人間用クライアントに修正を加えたものです。
 C# で作成されています。
 同梱の牌画は「雀のお宿」で配布されている、完全フリーの素材です。
 
 元プロジェクト
 http://d.hatena.ne.jp/wistery_k/20121102/1351845850
 
 牌画
 http://suzume.hakata21.com/5zats/haiga43.html


* transmau/
 「まうじゃん」Windows版のAPIを実装した、DLL形式の麻雀AIを、mjaiサーバーに接続するためのラッパースクリプトです。
 Ruby で作成されていますが、Windowsでのみ動作します。


* public_html/
 牌譜・成績等を閲覧するための、Webサイトのコードです。
 牌譜ビューアは、gimiteさんのmjaiプロジェクト内のものです。
