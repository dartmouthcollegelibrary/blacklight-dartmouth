#!/bin/bash

function killthis() {
  pid="$(cat tmp/pids/server.pid)"
  if [ ! -z "$pid" ]; then
    echo "[OK] Process Id : ${pid}"
    kill -9 $pid
    echo "[OK] Process killed"
  else
    echo "[FAIL] Some issues in getting pid"
  fi
}

killthis
rake jetty:stop

