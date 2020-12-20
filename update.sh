#!/usr/bin/env bash
raw_url="https://api.github.com/repos/rawfoxDE/raw-wine/releases"
snatella_url="https://api.github.com/repos/snatella/wine-runner-sc/releases"
base_path="$HOME/.local/share/lutris/runners/wine" # Default location of Lutris wine runner
install_complete=false;
delete_complete=false;
restart_lutris=2
max_runners=20
# Set restart_lutris=0 to not restart lutris after installing the runner
# Set restart_lutris=1 to autorestart lutris after installing the runner
# Set restart_lutris=2 to ask with a y/n prompt if Lutris is running

PrintRelease() {
  echo "----------Description----------"
  echo ""
  echo "  LUG-Helper Runner Downloader"
  echo ""
  echo "---------Latest Releases-------"
  echo snatella:
  curl -s $snatella_url | grep -H -m1 "\"name\"" | cut -d = -f3 | cut -d \" -f4
  echo rawfox:
  curl -s $raw_url | grep -H -m1 "\"name\"" | cut -d = -f3 | cut -d \" -f4
  echo "--------------------------------"
  echo ""

}

InstallWineRunner() {
  rsp="$(curl -sI "$url" | head -1)"
  echo "$rsp" | grep -q 302 || {
    echo "$rsp"
    exit 1
    }
    read ra
    if test $latest_url = $snatella_url ; then
        dest_path="$base_path/$version"
        [ -d "$dest_path" ] || {
            mkdir "$dest_path"
            echo [Info] Created "$dest_path"
        }
    else
    dest_path="$base_path"
    fi
    curl -sL "$url" | tar xfzv - -C "$dest_path"
    install_complete=true
    echo "Installation completed"
    DeleteRestartPrompt
}

DeleteRestartPrompt() {
    echo ""
    read -r -p "Do you want to delete intalled runners? <y/N> " prompt
    if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then
        DeleteRunnersCheck
    else
        RestartLutrisCheck
    fi
}

DeleteRunnersCheck() {
    echo ""
    echo "Installed runners:"
    installed_versions=($(ls -d "$base_path"/*/))       #read all directorys in the base_path
    for((i=0;i<${#installed_versions[@]};i++)); do
        inumber=$(("$i" + 1))
        folder=$(echo "${installed_versions[i]}" | rev | cut -d/ -f2 | rev) #reverse the order, cut after the second / and reverse again to only have the runner folder instead of the whole path
        echo "$inumber. $folder"
    done
    echo ""
    echo -n "Please choose an option to remove [1-${#installed_versions[@]}]:"
    read -ra option_remove
    
    case "$option_remove" in
        [1-9])
        if (( $option_remove<= ${#installed_versions[@]} )); then
            remove_option=${installed_versions[$option_remove -1]}
            echo "removing $remove_option"
            DeleteRunnerPrompt
        else
            echo "That is not a valid option"
        fi
        ;;
        *)
            echo "Not a valid option" 
        ;;
    esac
}

DeleteRunnerPrompt() {
    read -r -p "Do you really want to permanently delete this runner? <y/N> " prompt
    if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then
      DeleteRunner
      delete_complete=true          #used to track the need to restart Lutris
    else
      echo "Operation canceled"
      DeleteRestartPrompt
    fi
}

DeleteRunner() {
    rm -rf $remove_option
    echo "removed $remove_option"
    DeleteRestartPrompt
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
  if [ "$( pgrep lutris )" != "" ] && [ "$install_complete" = true || "$delete_complete" = true ]; then
    if [ $restart_lutris == 2 ]; then
      read -r -p "Do you want to restart Lutris? <y/N> " prompt
      if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then
        RestartLutris
      else
        exit 0
      fi
    elif [ $restart_lutris == 0 ]; then
      exit 0
    else
      RestartLutris
    fi
  fi
}

InstallationPrompt() {
  if [ ! -d "$base_path"/"$version" ]; then
    InstallWineRunner
  else
    read -r -p "Do you want to try to download and (re)install this release? <y/N> " prompt
    if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then
      InstallWineRunner
    else
      echo "Operation canceled"
      DeleteRestartPrompt
    fi
  fi
}


PrintRelease

echo "Choose Contributor:"
echo "1. snatella"
echo "2. rawfox"
echo ""
read -ra set_url

case $set_url in
    1)
    latest_url=$snatella_url
    echo "searching $snatella_url ..."
    download_options=($(curl -s "$latest_url" | grep -E "browser_download_url.*tgz" | cut -d \" -f4 | cut -d / -f9))
    ;;
    2)
    latest_url=$raw_url
    echo "searching $raw_url ..."
    download_options=($(curl -s "$latest_url" | grep -E "browser_download_url.*tar.gz" | cut -d \" -f4 | cut -d / -f9 | cut -d . -f1-3))
    ;;
esac

echo ""
echo "Available runners:"
if ((${#download_options[@]} > $max_runners)); then
    runner_count=$max_runners
else
    runner_count=${#download_options[@]}
fi

for((i=0;i<$runner_count;i++)); do
  number=$(("$i" + 1))
  version=$(echo "${download_options[i]}" | sed 's/\.[^.]*$//')
  if [ -d "$base_path"/"$version" ]; then
    echo "$number. $version    [installed]"
  else
    echo "$number. $version"
  fi
done

echo ""
echo -n "Please choose an option to install [1-20]:"
read -ra option_install

if ! [ "$option_install" -eq "$option_install" ] 2> /dev/null
then
    echo "Sorry integers only"
else
    if (( $option_install <= $runner_count )); then
      option=${download_options[$option_install -1]}
      version=$(echo "$option" | sed 's/\.[^.]*$//') 
      url=$(curl -s "$latest_url" | grep -E "browser_download_url.*$option" | cut -d \" -f4)
      echo "Installing $version"
      InstallationPrompt
    else
      echo "That is not a valid option"
    fi
fi
