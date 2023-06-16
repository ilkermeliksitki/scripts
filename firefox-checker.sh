#!/bin/bash

# URL of the JSON file for checking the latest firefox versions
json_url="https://product-details.mozilla.org/1.0/firefox_versions.json"

# Get the installed version of firefox
installed_version=$(firefox --version | awk '{print $3}')

# Download the JSON file and calculate the total size
json_file="/tmp/firefox_versions.json"
curl -s "$json_url" -o "$json_file"
json_file_size=$(stat -c %s "$json_file")

# Get the latest version from the downloaded JSON file
latest_version=$(jq -r '.LATEST_FIREFOX_VERSION' "$json_file")

# Compare the versions
if [[ $installed_version == $latest_version ]]; then
  echo "Firefox is up to date. Installed version: $installed_version"
  total_fetched_byte=$json_file_size
else
  echo "Firefox is not up to date. Installed version: $installed_version, Latest version: $latest_version"
  
  # Prompt user to continue and download Firefox
  read -p "Do you want to download and install the latest version of Firefox? (y/n) " choice

  if [[ $choice == "y" || $choice == "Y" ]]; then
    # Download firefox
    cd "$HOME/Downloads/"
    sudo curl --parallel -L -o "firefox-latest.tar.bz2" "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US"
    sudo tar -xvjf "firefox-latest.tar.bz2"

    # Remove firefox directory and replace with the fresh one
    sudo rm -rvf "/opt/firefox"
    sudo mv -v "firefox" "/opt"

    # Create a symbolic link
    sudo ln -f -s "/opt/firefox/firefox" "/usr/local/bin/firefox"

    # Create a desktop file, delete the old one
    if [ -f "/usr/local/share/applications/firefox.desktop" ]; then
       sudo rm -v "/usr/local/share/applications/firefox.desktop" 
    fi
    sudo wget "https://raw.githubusercontent.com/mozilla/sumo-kb/main/install-firefox-linux/firefox.desktop" -P "/usr/local/share/applications"

    # Change "Firefox Web Browser" to "Firefox" for esthetic reasons
    sudo sed -i "s/Name=Firefox Web Browser/Name=Firefox/g" "/usr/local/share/applications/firefox.desktop"

    echo "Firefox has been downloaded and installed."
    total_fetched_byte=$((json_file_size + $(stat -c %s "firefox-latest.tar.bz2") + $(stat -c %s "/usr/local/share/applications/firefox.desktop")))
  else
    echo "No action taken. Exiting."
    total_fetched_byte=$json_file_size
  fi
fi

# Display the total downloaded size
echo "Total downloaded size: $total_fetched_byte bytes [~$(( total_fetched_byte / (1024 * 1024) )) MB]"

