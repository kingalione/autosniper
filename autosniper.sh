#!/bin/bash
round=0
type=$1
maskedDefId=$2
price=$3
priceRange=$4
sid=$5

function getMilliSeconds() {
  node -e 'console.log(Date.now())'
}

function getTradeIds() {
  curl -s $1 -X OPTIONS -H 'Access-Control-Request-Method: GET' -H 'Origin: https://www.easports.com' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36' -H 'Access-Control-Request-Headers: content-type,easw-session-data-nucleus-id,x-ut-sid' --compressed

  if [[ "$type" == 'fitness' ]]; then
    #check for FC's
    curl -s $1 -H 'Accept: text/plain, */*; q=0.01' -H "X-UT-SID: $sid" -H 'Easw-Session-Data-Nucleus-Id: 2370625520' -H 'Origin: https://www.easports.com' -H 'Referer: https://www.easports.com/fifa/ultimate-team/web-app/' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36' -H 'Content-Type: application/json' --compressed | jq -r '.auctionInfo[].tradeId'
  else
    #check for P's
    curl -s $1 -H 'Accept: text/plain, */*; q=0.01' -H "X-UT-SID: $sid" -H 'Easw-Session-Data-Nucleus-Id: 2370625520' -H 'Origin: https://www.easports.com' -H 'Referer: https://www.easports.com/de/fifa/ultimate-team/web-app/' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36' -H 'Content-Type: application/json' --compressed | jq -r '.auctionInfo[].tradeId'
  fi

}

function sendOptionReq() {
  curl -s "https://utas.external.s2.fut.ea.com/ut/game/fifa19/trade/$1/bid?sku_c=fut19" -X OPTIONS -H 'Access-Control-Request-Method: PUT' -H 'Origin: https://www.easports.com' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36' -H 'Access-Control-Request-Headers: content-type,x-ut-sid' --compressed
}

function sendBidReq() {
  if [[ "$type" == 'fitness' ]]; then
    #try to buy FC's
    curl -s "https://utas.external.s2.fut.ea.com/ut/game/fifa19/trade/$1/bid?sku_c=fut19" -X PUT -H "X-UT-SID: $sid" -H 'Referer: https://www.easports.com/fifa/ultimate-team/web-app/' -H 'Origin: https://www.easports.com' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36' -H 'Content-Type: application/json' --data-binary "{\"bid\":$price}" --compressed
  else
    #try to buy P's
    curl -s "https://utas.external.s2.fut.ea.com/ut/game/fifa19/trade/$1/bid?sku_c=fut19" -X PUT -H "X-UT-SID: $sid" -H 'Referer: https://www.easports.com/de/fifa/ultimate-team/web-app/' -H 'Origin: https://www.easports.com' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36' -H 'Content-Type: application/json' --data-binary "{\"bid\":$price}" --compressed
  fi

}

while [ 1 ]
do
    if ! ((round % 2)); then
      price=$((price - priceRange))
    else
      price=$((price + priceRange))
    fi

    echo "Searching for card for $price coins. Round: $round"

    milli=$(getMilliSeconds)


    if [[ "$type" == 'gold' ]]; then
        #check for GOLD-P
        url="https://utas.external.s2.fut.ea.com/ut/game/fifa19/transfermarket?start=0&num=21&type=player&maskedDefId=$maskedDefId&lev=gold&maxb=$price&_=$milli"
    elif [[ "$type" == 'special' ]]; then
        #check for Special-P
        url="https://utas.external.s2.fut.ea.com/ut/game/fifa19/transfermarket?start=0&num=21&type=player&maskedDefId=$maskedDefId&rare=SP&maxb=$price&_=$milli"
    elif [[ "$type" == 'fitness' ]]; then
        if [[ "$maskedDefId" == 'bid' ]]; then
            url="https://utas.external.s2.fut.ea.com/ut/game/fifa19/transfermarket?start=0&num=21&type=development&definitionId=5002006&micr=150&macr=250&_=$milli"
        else
            #check for FC
            url="https://utas.external.s2.fut.ea.com/ut/game/fifa19/transfermarket?start=0&num=21&type=development&definitionId=5002006&maxb=$price&_=$milli"
        fi
     elif [[ "$type" == 'chemistry' ]]; then
        if [[ "$maskedDefId" == 'hunter' ]]; then
            url="https://utas.external.s2.fut.ea.com/ut/game/fifa19/transfermarket?start=0&num=21&type=training&cat=playStyle&playStyle=266&maxb=$price&_=$milli"
        else
            url="https://utas.external.s2.fut.ea.com/ut/game/fifa19/transfermarket?start=0&num=21&type=training&cat=playStyle&playStyle=268&maxb=$price&_=$milli"
        fi
    else
        echo "No card type given. Exiting application."
        break
    fi

    tradeIds=($(getTradeIds $url))

    if [[ ${#tradeIds[@]} -eq 0 ]]; then
        echo "No cards found for $price coins."
    else
        echo "Cards found: "
        echo ${tradeIds[@]}

        len=${#tradeIds[*]}

        if [[ "$type" == 'fitness' && "$maskedDefId" == 'bid' ]]; then

            COUNTER=$len
            until [[  $COUNTER -lt 1 ]]; do
                sleep 3
                echo "Trying to buy the card ${tradeIds[$COUNTER-1]} for $price coins"
                echo $(sendOptionReq ${tradeIds[$COUNTER-1]})
                response=$(sendBidReq ${tradeIds[$COUNTER-1]})
                echo $response
                let COUNTER-=1
            done

        else
            echo "Trying to buy the card ${tradeIds[$len-1]} for $price coins"
            echo $(sendOptionReq ${tradeIds[$len-1]})
            response=$(sendBidReq ${tradeIds[$len-1]})
            echo $response
        fi

    fi

    round=$((round + 1))

    sleeper=$(( ( RANDOM % 20 )  + 10 ))
    echo "Round finished sleeping $sleeper seconds."
    sleep $sleeper
done