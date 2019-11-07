#!/bin/bash

set -eo pipefail

multipass delete master worker1 worker2 || true
multipass purge

printf "Total runtime was: %02d:%02.f\n" $(($SECONDS%3600/60)) $(($SECONDS%60))
echo "############################################################################"
