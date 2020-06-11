#!/usr/bin/env bash
latest_url="https://api.github.com/repos/snatella/wine-runner-sc/releases/latest"
base_path="$HOME/.local/share/lutris/runners/wine" # Default location of Lutris wine runner
download_options=($(curl -s "$latest_url" | grep -E "browser_download_url.*tgz" | cut -d \" -f4 | cut -d / -f9))
install_complete=false;
restart_lutris=2
# Set restart_lutris=0 to not restart lutris after installing the runner
# Set restart_lutris=1 to autorestart lutris after installing the runner
# Set restart_lutris=2 to ask with a y/n prompt if Lutris is running

PrintRelease() {
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
  echo "Installation completed"
  DeleteRestartPrompt
}

DeleteRestartPrompt() {
    if [ "$( pgrep lutris )" != "" ] && [ "$install_complete" = true ]; then
        read -r -p "Do you want to delete intalled runners? <y/N> " prompt
        if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then
            DeleteRunnersCheck
        else
            RestartLutrisCheck
        fi
    fi
}

DeleteRunnersCheck() {
    echo "Installed runners:"
    installed_versions=($(ls -d "$base_path"/*/))
    for((i=0;i<${#installed_versions[@]};i++)); do
        inumber=$(("$i" + 1))
        folder=$(echo "${installed_versions[i]}" | rev | cut -d/ -f2 | rev)
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
    else
      echo "Operation canceled"
      exit 0
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
  if [ "$( pgrep lutris )" != "" ] && [ "$install_complete" = true ]; then
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


PrintRelease

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
      option=${download_options[$option_install -1]}
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
