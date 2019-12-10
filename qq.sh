#!/usr/bin/env bash

install(){
  if ! [ -x "$(command -v docker)" ]; then
    echo 'Error: docker is not installed.' >&2
    exit 1
  fi
  if ! [ -x ~/.local/bin/qq.sh ]; then
    echo 'Install this script to ~/.local/bin/qq.sh' >&2
    cp $0 ~/.local/bin/qq.sh
    QQ_P=/home/$(whoami)/.local/bin/qq.sh
    wget https://raw.githubusercontent.com/ygcaicn/ubuntu_qq/master/tim.png \
    -O ~/.local/share/icons/hicolor/256x256/apps/WINE_TIM.png
    cat <<-EOF > /home/$(whoami)/.local/share/applications/TIM.desktop
[Desktop Entry]
Categories=Network;InstantMessaging;
Exec=${QQ_P}
Icon=/home/$(whoami)/.local/share/icons/hicolor/256x256/apps/WINE_TIM.png
Name=TIM
NoDisplay=false
StartupNotify=true
Terminal=0
Type=Application
Name[en_US]=TIM
EOF
  else
    echo "already installed at ~/.local/bin/qq.sh"
  fi

}

remove(){
  echo "remove ~/.local/bin/qq.sh"
  [ -e ~/.local/bin/qq.sh ] && rm -f ~/.local/bin/qq.sh
  echo "remove ~/.local/share/icons/hicolor/256x256/apps/WINE_TIM.png"
  [ -e ~/.local/share/icons/hicolor/256x256/apps/WINE_TIM.png ] && rm -f ~/.local/share/icons/hicolor/256x256/apps/WINE_TIM.png
  echo "remove ~/.local/share/applications/TIM.desktop"
  [ -e /home/$(whoami)/.local/share/applications/TIM.desktop ] && rm -f /home/$(whoami)/.local/share/applications/TIM.desktop
}
clean(){
  container_ids=$(docker ps -a | awk  'NR!=1 && $2 ~ /bestwu\/qq/ {print $1}')
  docker container rm -f $container_ids
}

update(){
  clean
  wget https://raw.githubusercontent.com/ygcaicn/ubuntu_qq/master/qq.sh \
  -O $0
  . $0 -f
  start
}

startContainer(){
  arg='--name script_qq'
  if [[ "$1" == "instance" ]]; then
    arg='--rm'
  fi
  docker container run -d ${arg} \
    --device /dev/snd \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
    -v $HOME:$HOME \
    -v $HOME/TencentFiles:/TencentFiles \
    -e DISPLAY=unix$DISPLAY \
    -e XMODIFIERS=@im=fcitx \
    -e QT_IM_MODULE=fcitx \
    -e GTK_IM_MODULE=fcitx \
    -e AUDIO_GID=`getent group audio | cut -d: -f3` \
    -e VIDEO_GID=`getent group video | cut -d: -f3` \
    -e GID=`id -g` \
    -e UID=`id -u` \
    bestwu/qq:office

}

start(){
  container_id=$(docker ps -a | grep script_qq | awk  '$2 ~ /bestwu\/qq/ {print $1}')
  if [ -z "$container_id" ]; then
    startContainer
  else
    container_stat=$(docker ps | grep script_qq | awk  '$2 ~ /bestwu\/qq/ {print $1}')
    if [ -z "$container_stat" ]; then
      docker container start ${container_id}
    else
      docker container exec -d ${container_id} /entrypoint.sh
    fi
  fi
}

starti(){
  startContainer instance
}

help(){
  echo "./qq.sh [-h] [-i] [-f] [-c] [--remove] [--instance]"
  echo "  -h, --help            Show help"
  echo "  -i, --install         Install this script to system"
  echo "  -f, --force           Force install or reinstall"
  echo "  -c, --clean           Clean all qq container"
  echo "      --update          Update script"
  echo "      --remove          Remove this script"
  echo "      --instance        Create a instance container, you can create more then one using this option"
  return 0
}


REMOVE=''
INSTALL=''
REINSTALL=''
HELP=""
INSTANCE=""
CLEAN=""
while [[ $# > 0 ]];do
  key="$1"
  case $key in
      -i|--install)
      INSTALL="1"
      ;;
      --remove)
      REMOVE="1"
      ;;
      -f|--force)
      REINSTALL="1"
      ;;
      --instance)
      INSTANCE="1"
      ;;
      -c|--clean)
      CLEAN="1"
      ;;
      -h|--help)
      HELP="1"
      ;;
      *)
      echo "Unknown opt."
      help
      ;;
  esac
  shift
done

main(){
  [[ "$REMOVE" == "1" ]] && remove && return
  [[ "$INSTALL" == "1" ]] && install && return
  [[ "$REINSTALL" == "1" ]] && remove && install && return
  [[ "$INSTANCE" == "1" ]] && starti && return
  [[ "$CLEAN" == "1" ]] && clean && return
  [[ "$UPDATE" == "1" ]] && update && return
  [[ "$HELP" == "1" ]] && help && return
  
  start
}
main