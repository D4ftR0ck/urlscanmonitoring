#!/bin/bash
#Lib JQ sur Bash.
current_dir=$(dirname $(realpath -s $0))
var_location=$(cat $current_dir/list_url)
IFS=$'\n'
lines=($var_location)
# creation monitoring
if [ ! -f $current_dir/monitoring.xml ]; then
touch "$current_dir/monitoring.xml"
fi
# Open or not - monitoring
if grep -q "</rss>" $current_dir/monitoring.xml;then
sed -i '$d' $current_dir/monitoring.xml
sed -i '$d' $current_dir/monitoring.xml
fi
# Si fichier monitoring vide - creation du xml
if [ $(wc -l < $current_dir/monitoring.xml) -lt 2 ]; then
echo "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>" > $current_dir/monitoring.xml
echo "<rss version=\"2.0\">" >> $current_dir/monitoring.xml
echo "<channel>" >> $current_dir/monitoring.xml
echo "<title>URLSCANRSS</title>" >> $current_dir/monitoring.xml
echo "<link>http://urlscan.io</link>" >> $current_dir/monitoring.xml
echo "<description>Récupérer les derniers scans du site urlscan.io</description>" >> $current_dir/monitoring.xml
fi
########################
if [ ! -f $current_dir/list_url ]; then
touch "$current_dir/list_url"
echo "Attention list_url est vide et a été crée il faut le remplir !"
exit
fi
if [ $(wc -l < $current_dir/list_url) -eq 0 ]; then
echo "Attention list_url est vide"
exit
fi

#CREATION DES DOSSIERS A PARTIR DE LOCATION
for line in "${lines[@]}"; do
    if [ ! -d $current_dir/lastdata ]; then
    echo "$line in work"
    curl -s "https://urlscan.io/api/v1/search/?q=domain:$line&size=10000" >> $line

    jq -r '.results[] | .task.uuid, .task.url, .page.url, .page.ip, .page.asnname, .task.time, .result, .screenshot' $line >> $current_dir/tempo1

    file=$current_dir/tempo1
    touch $current_dir/transit

        while [ "$(wc -l < "$file")" -gt 0 ];do
        declare -a valeurs
        valeurs=($(tail -n 8 $current_dir/tempo1))
            if ! grep -q "${valeurs[0]}" $current_dir/monitoring.xml; then
            echo ${valeurs[0]} >> $current_dir/transit
            echo ${valeurs[1]} >> $current_dir/transit
            echo ${valeurs[2]} >> $current_dir/transit
            echo ${valeurs[3]} >> $current_dir/transit
            echo ${valeurs[4]} >> $current_dir/transit
            echo ${valeurs[5]} >> $current_dir/transit
            echo ${valeurs[6]} >> $current_dir/transit
            echo ${valeurs[7]} >> $current_dir/transit
            echo "Data add $valeurs"
            for i in {1..8}; do sed -i '$d' $current_dir/tempo1; done # une seule ligne
            else
            for i in {1..8}; do sed -i '$d' $current_dir/tempo1; done
            fi

        done
    rm $current_dir/tempo1
    fi
done

while [ $(wc -l < $current_dir/transit) -gt 7 ]; do
valeurs=($(head -n 8 $current_dir/transit))
declare -a valeurs
#datexml=$(date -Ru --date="${valeurs[5]}") Date version international
datexml=$(date -Ru)
datereal=$(date -u --date="${valeurs[5]}")

echo "<item>" >> $current_dir/monitoring.xml
echo "<title>URLSCAN.IO - $datereal</title>" >> $current_dir/monitoring.xml
echo "<link>https://urlscan.io/api/v1/result/</link>" >> $current_dir/monitoring.xml
echo -e '<description><![CDATA[\c' >> $current_dir/monitoring.xml
echo "Scan url : ${valeurs[1]}<br >" >> $current_dir/monitoring.xml #task.url
echo "Final url : ${valeurs[2]}<br >" >> $current_dir/monitoring.xml #page.url
echo "ip : ${valeurs[3]}<br >" >> $current_dir/monitoring.xml #page.ip
echo "ASN : ${valeurs[4]}<br >" >> $current_dir/monitoring.xml #page.asnname
echo "Scan date : $datereal<br >" >> $current_dir/monitoring.xml #.task.time
echo "Resultat : ${valeurs[6]}<br >" >> $current_dir/monitoring.xml #.result
echo "UUID : ${valeurs[0]}<br >" >> $current_dir/monitoring.xml #task.uuid
echo "Screenshot :<br >" >> $current_dir/monitoring.xml
echo -e '<img src="\c' >> $current_dir/monitoring.xml
echo -e "${valeurs[7]}\c" >> $current_dir/monitoring.xml
echo -e '"/>]]>\c' >> $current_dir/monitoring.xml
echo "</description>" >> $current_dir/monitoring.xml
echo "<pubDate>$datexml</pubDate>" >> $current_dir/monitoring.xml
echo "</item>" >> $current_dir/monitoring.xml
sed -i '1,8d' $current_dir/transit
done
rm $current_dir/transit

if ! grep -q "</rss>" $current_dir/monitoring.xml;then
echo "</channel>" >> $current_dir/monitoring.xml
echo "</rss>" >> $current_dir/monitoring.xml
fi
#timeout 60 python3 -m http.server 8556 --bind 127.0.0.1 -d $current_dir/
#pkill -9 -f 'python3 -m http.server'
