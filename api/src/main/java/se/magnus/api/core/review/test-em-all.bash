#!/usr/bin/env bash
: ${HOST=localhost}
: ${PORT=7001}

function assertCurl() {
  local expectedHttpCode=$1
  local curlCmd="$2 -w \"%{http_code}\""
  local result=$(eval $curlCmd)
  local httpCode="${result:(-3)}"
  RESPONSE='' && (( ${#result} > 3 )) && RESPONSE="${result%???}"
  if [ "$httpCode" = "$expectedHttpCode" ]; then
    echo "Test OK (HTTP Code: $httpCode)"
  else
    echo "Test FAILED, EXPECTED HTTP Code: $expectedHttpCode, GOT: $httpCode, WILL ABORT!"
    echo "- Failing command: $curlCmd"
    echo "- Response Body: $RESPONSE"
    exit 1
  fi
}

function assertEqual() {
  local expected=$1
  local actual=$2
  if [ "$actual" = "$expected" ]; then
    echo "Test OK (actual value: $actual)"
  else
    echo "Test FAILED, EXPECTED VALUE: $expected, ACTUAL VALUE: $actual, WILL ABORT"
    exit 1
  fi
}

echo "HOST=${HOST}"
echo "PORT=${PORT}"

# 정상 요청: 추천 3개, 리뷰 3개
assertCurl 200 "curl http://$HOST:${PORT}/product-composite/1 -s"
assertEqual 1 $(echo $RESPONSE | jq .productId)
assertEqual 3 $(echo $RESPONSE | jq ".recommendations | length")
assertEqual 3 $(echo $RESPONSE | jq ".reviews | length")

# 존재하지 않는 productId(13): 404
assertCurl 404 "curl http://$HOST:${PORT}/product-composite/13 -s"
assertEqual "\"No product found for productId: 13\"" "$(echo $RESPONSE | jq .message)"

# 잘못된 productId(-1): 422
assertCurl 422 "curl http://$HOST:${PORT}/product-composite/-1 -s"
assertEqual "\"Invalid productId: -1\"" "$(echo $RESPONSE | jq .message)"

# 타입 오류: 400
assertCurl 400 "curl http://$HOST:${PORT}/product-composite/invalidProductId -s"
assertEqual "\"Type mismatch.\"" "$(echo $RESPONSE | jq .message)"

echo "End, all tests OK:" `date`