#!/bin/sh

# エラー終了の関数
errexit() {
  printf "\033[31m[ERROR]\033[0m" ; echo " $1"
  echo "使い方: $0 入力dir 出力dir"
  exit 1
}

generator=`basename $0`
echo "\"$generator\" - MarkdownをまとめてHTMLに変換してindexファイルも作る"
echo ""

# Pandocの有無をチェック
test "`which pandoc 2>/dev/null`" || errexit "Pandocがありません"

# 引数チェック
test "$1" = "" && errexit "入力dirが指定されていません"
test "$2" = "" && errexit "出力dirが指定されていません"

srcdir=$1
outdir=$2

# dirの有無をチェック
test -d "$srcdir" || errexit "入力dirが存在しません"
test -d "$outdir" || errexit "出力dirが存在しません"

indexfile=$outdir/index.html
stylefilename=style.css

echo "HTMLファイルの生成を開始."
# index.htmlの前半
cat << EOT > $indexfile
<!DOCTYPE html>
<html><head><meta charset="utf-8" />
<meta generator="$generator" /><title>Documents</title>
<link rel="stylesheet" href="$stylefilename">
</head><body><h1>Documents</h1>
<p>"$generator"によって`date "+%Y-%m-%d %H:%M:%S"`に生成されました。</p>
<ul>
EOT
# ループ開始 
for f in `ls -t $srcdir/*.md` # mdファイルを新しい順に取得
do
  name=`basename $f`
  htmlname=`echo $name | sed s/.md$/.html/`
  /bin/echo -n "  変換: $name -> $htmlname ..."
  title=`head -n 1 $f | sed 's/#//' | sed 's/^<space>+//'` # タイトルは先頭行を使用
  test "$title" = "" && title=$name # タイトルが無い場合はmdファイル名を設定
  mtime=`date -r $f "+%Y-%m-%d %H:%M:%S"` # mdファイルの最終更新日時
  tempfile=`mktemp temp-XXXXXX`
  ( echo "% $title" ; cat $f | awk "2<=NR" ) > $tempfile # 先頭行を差し替え
  pandoc -s -f markdown -t html5 -c $stylefilename -o $outdir/$htmlname $tempfile
  rm $tempfile
  echo ".. 完了"
  echo "<li><a href="./$htmlname">$title</a><br />（最終更新日時：${mtime}）</li>" >> $indexfile
done
# index.htmlの後半
cat << EOT >> $indexfile
</ul></body></html>
EOT
echo "完了しました."

