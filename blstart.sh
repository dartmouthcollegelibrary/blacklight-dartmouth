#!/bin/bash
rake jetty:start >>log/script.log 2>&1 &
rails server >>log/script.log 2>&1 &
