#!/usr/bin/env bash

# install chrome headless for karma tests
sudo apt update
sudo apt install -y wget libasound2 libnspr4 libnss3 libxss1 xdg-utils unzip libappindicator1 fonts-liberation libappindicator3-1 libatk-bridge2.0-0 libatspi2.0-0 libgbm1 libgtk-3-0 libu2f-udev
sudo apt install -f
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome*.deb

# remove local deb package
rm -f google-chrome*.deb
