#!/bin/bash
shopt -s nocasematch
if [[ ! $1 ]]
then
  echo -e " >> USAGE: sub.sh directory\n"
  exit
fi
DefaultDir=""
find ${1:-"DefaultDir"} \( -name "*.mkv" -or -name "*.mp4" \) > ${1:-"DefaultDir"}/movieList.txt

#min movie size: 100Mb
minimumsize=1000000 

exec 3< ${1:-"DefaultDir"}/movieList.txt
while read -u 3 line 
do
  actualsize=$(stat "$line" | cut -f 9 -d ' ')
  # Don't download subs for filename including word "sample"
  if [[ ( $actualsize -ge $minimumsize ) && !( "$line" =~ "sample" ) ]]; then
    movieDir="$(dirname "$line")"
    movieName="$(basename "$line")"
    cutMovieName="$(echo "$movieName" | sed -E 's_\..*$__g')"
    movieExt="$(echo "$movieName" | sed -E 's_^.*\.__g')"
    
    subListURLENG="http://www.opensubtitles.org/en/search/sublanguageid-eng/moviename-"
    subListURLENG+=$movieName

    engID="$(curl --silent $subListURLENG | grep -m1 -i "servOC(" | sed -E 's_^.*servOC.__g' | sed -E 's_,./en/subtitles.*$__g')" 

    downloadURL="http://www.opensubtitles.org/en/download/sub/"
    engDownloadURL=$downloadURL$engID
    wget -q $engDownloadURL -O "$movieDir/$cutMovieName-eng.zip" >/dev/null 2>&1

    unzip "$movieDir/$cutMovieName-eng.zip" -d "$movieDir/$cutMovieName" >/dev/null 2>&1
    subDir="$movieDir/$cutMovieName"
    sub="$(find "$subDir" -name "*.srt")"

    mv "$sub" "$movieDir/$cutMovieName-eng.srt" >/dev/null 2>&1

    rm "$movieDir/$cutMovieName-eng.zip"
    rm -rf "$movieDir/$cutMovieName"

  fi
  
done #< "$filename"

