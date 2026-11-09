#!/bin/bash
set -e
cd "$(dirname "$0")"
npm install
if [ ! -d ./ios ]; then npx cap add ios; fi
npx cap sync ios
npx cap open ios
printf '\nNo Xcode: selecione Signing & Capabilities / Team, depois Product > Archive.\n'
