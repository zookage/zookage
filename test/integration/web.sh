#!/bin/bash
set -eu

check () {
  local -r url=$1
  echo "Check ${url}"
  local -r response=$(curl -o /dev/null -w '%{http_code}' -s "${url}")
  echo "${url} returned ${response}"
  echo
  if [ "$response" = 200 ] || [ "$response" = 307 ]; then
    return 0
  else
    return 1
  fi
}

check "http://localhost:14000/webhdfs/v1/?op=liststatus&user.name=zookage"
check "http://localhost:9870/dfshealth.html"
check "http://localhost:9874/#!/"
check "http://localhost:9876/#!/"
check "http://localhost:9888/#/Overview"
check "http://localhost:8088/cluster"
check "http://localhost:8088/ui2/"
check "http://localhost:8188/applicationhistory"
check "http://localhost:19888/jobhistory"
check "http://localhost:9999/tez-ui/"
check "http://localhost:10002/"
check "http://localhost:16010/master-status"
check "http://localhost:8080/ui/"
