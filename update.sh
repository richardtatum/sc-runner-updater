#!/usr/bin/env bash
baseuri="https://github.com/snatella/wine-runner-sc/releases"
latesturi="https://github.com/snatella/wine-runner-sc/releases/latest"
parameter="${1}"
installComplete=false;
dstpath="$HOME/.local/share/lutris/runners/wine" #### Destination folder of the wine installations
restartLutris=2
autoInstall=false
#### Set restartLutris=0 to not restart lutris after installing Wine (Keep process untouched)
#### Set restartLutris=1 to autorestart lutris after installing Wine
#### Set restartLutris=2 to to get a y/n prompt asking if you want to restart Lutris after each installation.

#### Set autoInstall=true to skip the installation prompt and install the latest not-installed, or any forced Wine runner 
#### Set autoInstall=false to display a installation-confirmation prompt when installing a Wine runner


PrintReleases() {
  echo "----------Description----------"
  echo ""
  echo "Run './update.sh [VersionName]'"
  echo "to download specific versions."
  echo ""
  echo "------------Releases------------"
  curl -s https://github.com/snatella/wine-runner-sc/releases | grep -H "tag_name" | cut -d = -f3 | cut -d \& -f1
  echo "--------------------------------"

}

InstallWineRunner() {
  rsp="$(curl -sI "$url" | head -1)"
  echo "$rsp" | grep -q 302 || {
    echo "$rsp"
    exit 1
  }

  [ -d "$dstpath" ] || {
    mkdir "$dstpath"
    echo [Info] Created "$dstpath"
  }
  curl -sL "$url" | tar xfzv - -C "$dstpath"
  installComplete=true
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
  if [ "$( pgrep lutris )" != "" ] && [ "$installComplete" = true ]; then
    if [ $restartLutris == 2 ]; then
      read -r -p "Do you want to restart Lutris? <y/N> " prompt
      if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then
        RestartLutris
      else
        exit 2
      fi
    elif [ $restartLutris == 0 ]; then
      exit 0
    fi
    RestartLutris
  fi
}

InstallationPrompt() {
  if [ "$autoInstall" = true ]; then
    if [ ! -d "$dstpath"/snatella-"$version" ]; then
      InstallWineRunner
    fi
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

if [ -z "$parameter" ]; then
  version="$(curl -s $latesturi | grep -E -m1 "tag_name" | cut -d \" -f4)"
  url=$(curl -s $latesturi | grep -E -m1 "browser_download_url.*Wine" | cut -d \" -f4)
  if [ -d "$dstpath"/snatella-"$version" ]; then
    echo "Wine $version is the latest version and is already installed."
  else
    echo "Wine $version is the latest version and is not installed yet."
  fi
elif [ "$parameter" == "-l" ]; then
  PrintReleases
else
  url=$baseuri/"$parameter"/snatella-"$parameter".tar.gz
  if [ -d "$dstpath"/snatella-"$parameter" ]; then
    echo "Wine $parameter is already installed."
  else
    echo "Wine $parameter is not installed yet."
  fi
fi

if [ ! "$parameter" == "-l" ]; then
  InstallationPrompt
  RestartLutrisCheck
fi
