#!bin/bash

                               
                               # GET ALL PREFIXES ASSIGNED AT A GIVEN COUNTRY, KEEP ONLY THE NETWORK ADDRESS AND STORE THEM IN "IPs.tmp"

                             
 curl -s --location --request GET "https://stat.ripe.net/data/country-resource-list/data.json?resource=$1&v4_format=prefix" > query_output.tmp.json

 # Check if there are two arguments
 if (( $# < 2 )); then
    echo
    echo "Usage: ./city2networks.sh ISO_COUNTRY_CODE City"
    echo
    exit 1
 fi


 perl -MRegexp::Common=net -nE 'say $& while /$RE{net}{IPv4}|$RE{net}{IPv6}/g' query_output.tmp.json > prefixes.tmp
 head --lines=-1 prefixes.tmp >  IPs.tmp
 rm query_output.tmp.json && rm prefixes.tmp


                               
                               # READ STORED IPs FROM "IPs.tmp" AND QUERY FOR THE CITY AND COORDINATES FOR EACH IP THEN STORE ONLY THE RELEVANT INFO IN A JSON FILE
 
 echo
 echo "Depending on the # of allocated prefixes, this could take some time.."
 echo
 output="$1-maxmind_query.json"
 while read -r ip; do
   
   
   curl -s --location --request GET "https://stat.ripe.net/data/maxmind-geo-lite/data.json?resource=$ip" -o maxmindb_curl_res_dump
   echo "$(<maxmindb_curl_res_dump)" | jq '.data.located_resources | .[0] | .locations' >> "$output"
   echo "Querying for $ip"
   \rm -f maxmindb_curl_res_dump
   


 done < IPs.tmp



 rm IPs.tmp

                              # READ STORED INFO FROM JSON FILE AND OUTPUT ONLY THE IPs WITH A GIVEN CITY ASSIGNED (some IPs don't have a city assigned but only coordinates)


echo "$(<$1-maxmind_query.json)" | jq 'if . | .[0] | ."city" == "'$2'" then . | .[0] | ."resources" elif . | .[0] | ."country" == "'$1'" then "NO CITY ASSIGNED TO IP" else "DIFFERENT COUNTRY" end' >> jq-out.temp
grep -E "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" jq-out.temp > $2_$1-Networks-IPv4.txt

egrep '(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]).){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]).){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))' jq-out.temp > $2_$1-Networks-IPv6.txt

echo "Results saved to current directory."

rm jq-out.temp 

