#!/bin/bash
round=0
sid=$1
maskedDefId=$2
quality=$3
price=$4
priceRange=$5

function getTradeIds() {
  #curl -s $1 -X OPTIONS -H 'Access-Control-Request-Method: GET' -H 'Origin: https://www.easports.com' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36' -H 'Access-Control-Request-Headers: content-type,easw-session-data-nucleus-id,x-ut-sid' --compressed
  #send option header
  curl -s $1 -X OPTIONS -H 'Connection: keep-alive' -H 'Access-Control-Request-Method: GET' -H 'Origin: https://www.easports.com' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.97 Safari/537.36' -H 'Access-Control-Request-Headers: content-type,x-ut-sid' -H 'Accept: */*' -H 'Sec-Fetch-Site: cross-site' -H 'Sec-Fetch-Mode: cors' -H 'Referer: https://www.easports.com/fifa/ultimate-team/web-app/' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7' --compressed

  #check for Players
  #curl -s $1 -H 'Accept: text/plain, */*; q=0.01' -H "X-UT-SID: $sid" -H 'Easw-Session-Data-Nucleus-Id: 2370625520' -H 'Origin: https://www.easports.com' -H 'Referer: https://www.easports.com/de/fifa/ultimate-team/web-app/' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36' -H 'Content-Type: application/json' --compressed | jq -r '.auctionInfo[].tradeId'
  curl -s $1 -H 'Connection: keep-alive' -H "X-UT-SID: $sid" -H 'Origin: https://www.easports.com' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.97 Safari/537.36' -H 'Content-Type: application/json' -H 'Accept: */*' -H 'Sec-Fetch-Site: cross-site' -H 'Sec-Fetch-Mode: cors' -H 'Referer: https://www.easports.com/fifa/ultimate-team/web-app/' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7' --compressed | jq -r '.auctionInfo[].tradeId'
}
function sendOptionReq() {
  curl -s "https://utas.external.s2.fut.ea.com/ut/game/fifa19/trade/$1/bid?sku_c=fut19" -X OPTIONS -H 'Access-Control-Request-Method: PUT' -H 'Origin: https://www.easports.com' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36' -H 'Access-Control-Request-Headers: content-type,x-ut-sid' --compressed
}

function sendBuyReq() {
  curl -s "https://utas.external.s2.fut.ea.com/ut/game/fifa19/trade/$1/bid?sku_c=fut19" -X PUT -H "X-UT-SID: $sid" -H 'Referer: https://www.easports.com/de/fifa/ultimate-team/web-app/' -H 'Origin: https://www.easports.com' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36' -H 'Content-Type: application/json' --data-binary "{\"bid\":$price}" --compressed
}

while [ 1 ]
do
  if ! ((round % 2)); then
    price=$((price - priceRange))
  else
    price=$((price + priceRange))
  fi

  echo "Suche nach der Karte $maskedDefId für $price coins. Runde: $round"

  url="https://utas.external.s2.fut.ea.com/ut/game/fifa20/transfermarket?start=0&num=21&type=player&maskedDefId=$maskedDefId&lev=$quality"

  tradeIds=($(getTradeIds $url))
  bidTimer=0

  if [[ ${#tradeIds[@]} -eq 0 ]]; then
    echo "Keine Karten für $price coins gefunden."
  else
    echo "Karten gefunden: "
    echo ${tradeIds[@]}

    len=${#tradeIds[*]}

    echo "Versuche die Karte mit der Id ${tradeIds[$len-1]} für $price coins zu kaufen."
    echo $(sendOptionReq ${tradeIds[$len-1]})
    response=$(sendBuyReq ${tradeIds[$len-1]})
    echo $response
  fi

  round=$((round + 1))

  sleeper=$(( ( RANDOM % (30 + $bidTimer) )  + (15 + ($bidTimer / 3)) ))
  echo "Runde beendet. Schlafe $sleeper Sekunden."
  sleep $sleeper
done