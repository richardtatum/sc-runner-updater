#!/usr/bin/env bash
base_url="https://github.com/snatella/wine-runner-sc/releases"
latest_url="https://api.github.com/repos/snatella/wine-runner-sc/releases/latest"
install_complete=false;
base_path="$HOME/.local/share/lutris/runners/wine" #### Destination folder of the wine installations
restart_lutris=2
download_options=($(curl -s "$latest_url" | grep -E "browser_download_url.*tgz" | cut -d \" -f4 | cut -d / -f9))
#### Set restart_lutris=0 to not restart lutris after installing Wine (Keep process untouched)
#### Set restart_lutris=1 to autorestart lutris after installing Wine
#### Set restart_lutris=2 to to get a y/n prompt asking if you want to restart Lutris after each installation.


PrintReleases() {
  echo "----------Description----------"
  echo ""
  echo "Tatumkhamun's SC Runner Updater"
  echo ""
  echo "---------Latest Release---------"
  curl -s $latest_url | grep -H -m1 "\"name\"" | cut -d = -f3 | cut -d \" -f4
  echo "--------------------------------"
  echo ""

}

InstallWineRunner() {
  rsp="$(curl -sI "$url" | head -1)"
  echo "$rsp" | grep -q 302 || {
    echo "$rsp"
    exit 1
  }
  
  dest_path="$base_path/snatella-$version"
  [ -d "$dest_path" ] || {
    mkdir "$dest_path"
    echo [Info] Created "$dest_path"
  }
  curl -sL "$url" | tar xfzv - -C "$dest_path"
  install_complete=true
}

RestartLutris() {
  if [ "$( pgrep lutris )" != "" ]; then
    echo "Restarting Lutris"
    pkill -TERM lutris #restarting Lutris
    sleep 5s
    nohup lutris </dev/null &>/dev/null &
  fi
}

RestartLutrisCheck() {
  if [ "$( pgrep lutris )" != "" ] && [ "$install_complete" = true ]; then
    if [ $restart_lutris == 2 ]; then
      read -r -p "Do you want to restart Lutris? <y/N> " prompt
      if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then
        RestartLutris
      else
        exit 2
      fi
    elif [ $restart_lutris == 0 ]; then
      exit 0
    fi
    RestartLutris
  fi
}

InstallationPrompt() {
    if [ ! -d "$base_path"/snatella-"$version" ]; then
        InstallWineRunner
    else
        read -r -p "Do you want to try to download and (re)install this release? <y/N> " prompt
        if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then
            InstallWineRunner
        else
            echo "Operation canceled"
            exit 0
        fi
    fi
}


PrintReleases

echo "Available runners:"
for((i=0;i<${#download_options[@]};i++)); do
  number=$(("$i" + 1))
  version=$(echo "${download_options[i]}" | sed 's/\.[^.]*$//')
  if [ -d "$base_path"/snatella-"$version" ]; then
    echo "$number. $version    [installed]"
  else
    echo "$number. $version"
  fi
done

echo ""
echo -n "Please choose an option to install [1-${#download_options[@]}]:"
read -ra option_install

case "$option_install" in
    [1-9])
        if (( $option_install <= ${#download_options[@]} )); then
          option=$(echo "${download_options[$option_install -1]}")
          version=$(echo "$option" | sed 's/\.[^.]*$//') 
          url=$(curl -s "$latest_url" | grep -E "browser_download_url.*$option" | cut -d \" -f4)
          echo "Installing $version"
          InstallationPrompt
        else
          echo "That is not a valid option"
        fi
    ;;
    *)
        echo "Not a valid option" 
    ;;
esac
