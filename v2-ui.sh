#!/bin/bash

#======================================================
#   System Required: CentOS 7+ / Debian 8+ / Ubuntu 16+
#   Description: Manage v2-ui
#   Author: sprov
#   Blog: https://blog.sprov.xyz
#   Github - v2-ui: https://github.com/sprov065/v2-ui
#======================================================

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

version="v1.0.0"

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Error: ${plain} Este script debe de ejecutarse como usuario root！\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}No se detectó la versión del sistema，Por favor contacte al autor del script！${plain}\n" && exit 1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Por favor use CentOS 7, O sistema superior！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Por favor use Ubuntu 16, O sistema superior！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Por favor use Debian 8, O sistema superior！${plain}\n" && exit 1
    fi
fi

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [Por defecto $2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Quiere reiniciar el panel?" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Presione enter para volver al menú principal.: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/infected521/v2-ui/master/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    confirm "Esta característica obligará a reinstalar la última versión，No se pierden datos，Desea continuar?" "n"
    if [[ $? != 0 ]]; then
        echo -e "${red}Cancelado${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/infected521/v2-ui/master/install.sh)
    if [[ $? == 0 ]]; then
        echo -e "${green}Actualización completada，Panel reiniciado automáticamente${plain}"
        exit
#        if [[ $# == 0 ]]; then
#            restart
#        else
#            restart 0
#        fi
    fi
}

uninstall() {
    confirm "¿Está seguro de que desea desinstalar el panel??" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop v2-ui
    systemctl disable v2-ui
    rm /etc/systemd/system/v2-ui.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/v2-ui/ -rf
    rm /usr/local/v2-ui/ -rf

    echo ""
    echo -e "La desinstalación se realizó correctamente, si desea eliminar este script, ejecute después de salir del script ${green}rm /usr/bin/v2-ui -f${plain} 进行删除"
    echo ""
    echo -e "Telegram Grupo: ${green}https://t.me/sprov_blog${plain}"
    echo -e "Github issues: ${green}https://github.com/sprov065/v2-ui/issues${plain}"
    echo -e "Blog: ${green}https://blog.sprov.xyz/v2-ui${plain}"

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

reset_user() {
    confirm "¿Está seguro de que desea restablecer su nombre de usuario y contraseña a admin?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/v2-ui/v2-ui resetuser
    echo -e "El nombre de usuario y la contraseña se han restablecido a ${green}admin${plain}，Ahora reinicie el panel"
    confirm_restart
}

reset_config() {
    confirm "¿Está seguro de que desea restablecer todas las configuraciones del panel, los datos de la cuenta no se perderán, el nombre de usuario y la contraseña no se cambiarán?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/v2-ui/v2-ui resetconfig
    echo -e "Todos los paneles se han restablecido a los valores predeterminados. Ahora reinicie los paneles y use el predeterminado ${green}65432${plain} Panel de acceso a puerto"
    confirm_restart
}

set_port() {
    echo && echo -n -e "Ingrese el número de puerto [1-65535]: " && read port
    if [[ -z "${port}" ]]; then
        echo -e "${yellow}Cancelado${plain}"
        before_show_menu
    else
        /usr/local/v2-ui/v2-ui setport ${port}
        echo -e "Después de configurar el puerto, reinicie el panel y use el puerto recién configurado ${green}${port}${plain} Panel de acceso"
        confirm_restart
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}El panel se está ejecutando, no es necesario comenzar de nuevo, si necesita reiniciar, elija reiniciar${plain}"
    else
        systemctl start v2-ui
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}v2-ui Comenzó exitosamente${plain}"
        else
            echo -e "${red}El panel no se inicia, puede deberse a que el tiempo de inicio es más de dos segundos, verifique la información de registro más tarde${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        echo -e "${green}El panel se detiene, no es necesario detenerse nuevamente${plain}"
    else
        systemctl stop v2-ui
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            echo -e "${green}v2-ui Deja de tener éxito${plain}"
        else
            echo -e "${red}El panel no se detiene, puede deberse a que el tiempo de detención es superior a dos segundos, verifique la información de registro más tarde${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart v2-ui
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}v2-ui Reiniciado exitosamente${plain}"
    else
        echo -e "${red}El reinicio del panel falló, puede deberse a que el tiempo de inicio es más de dos segundos, verifique la información de registro más tarde${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status v2-ui -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable v2-ui
    if [[ $? == 0 ]]; then
        echo -e "${green}v2-ui Establecer inicio automático con éxito${plain}"
    else
        echo -e "${red}v2-ui Error al configurar el encendido automático${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable v2-ui
    if [[ $? == 0 ]]; then
        echo -e "${green}v2-ui Cancelar inicio${plain}"
    else
        echo -e "${red}v2-ui Cancelar falla de arranque${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    echo && echo -n -e "Se pueden generar muchos registros de ADVERTENCIA durante el uso del panel. Si no hay ningún problema con el uso del panel, entonces no hay ningún problema. Presione Entrar para continuar: " && read temp
    tail -f /etc/v2-ui/v2-ui.log
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

install_bbr() {
    bash <(curl -L -s https://github.com/sprov065/blog/raw/master/bbr.sh)
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}Instalar bbr con éxito${plain}"
    else
        echo ""
        echo -e "${red}No se pudo descargar el script de instalación de bbr, compruebe si la máquina puede conectarse a Github${plain}"
    fi

    before_show_menu
}

update_shell() {
    wget -O /usr/bin/v2-ui -N --no-check-certificate https://raw.githubusercontent.com/infected521/v2-ui/master/v2-ui.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}No se pudo descargar el script, verifique si la máquina puede conectarse a Github${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/v2-ui
        echo -e "${green}El script de actualización fue exitoso, vuelva a ejecutar el script${plain}" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/v2-ui.service ]]; then
        return 2
    fi
    temp=$(systemctl status v2-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled v2-ui)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1;
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red}El panel está instalado, no repita la instalación.${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red}Por favor instale el panel primero${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "Estado del panel: ${green}Correr${plain}"
            show_enable_status
            ;;
        1)
            echo -e "Estado del panel: ${yellow}No corriendo${plain}"
            show_enable_status
            ;;
        2)
            echo -e "Estado del panel: ${red}No instalado${plain}"
    esac
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "comenzar automáticamente: ${green}Si ${plain}"
    else
        echo -e "comenzar automáticamente: ${red}No${plain}"
    fi
}

show_usage() {
    echo "v2-ui Cómo usar el script de administración: "
    echo "------------------------------------------"
    echo "v2-ui              - Menú de gestión (más funciones)"
    echo "v2-ui start        - Inicie el panel v2-ui"
    echo "v2-ui stop         - Detener el panel v2-ui"
    echo "v2-ui restart      - Reinicie el panel v2-ui"
    echo "v2-ui status       - Ver el estado de v2-ui"
    echo "v2-ui enable       - Arranque Automatico v2-ui"
    echo "v2-ui disable      - Cancelar el inicio de v2-ui"
    echo "v2-ui log          - Ver registros de v2-ui"
    echo "v2-ui update       - Actualizar el panel v2-ui"
    echo "v2-ui install      - Instalar el panel v2-u"
    echo "v2-ui uninstall    - Desinstalar el panel v2-ui"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}v2-ui Script de gestión del panel${plain} ${red}${version}${plain}
--- https://blog.sprov.xyz/v2-ui ---
  ${green}0.${plain} Salir del script
————————————————
  ${green}1.${plain} Instalar v2-ui
  ${green}2.${plain} Actualizar v2-ui
  ${green}3.${plain} Desinstalar v2-ui
————————————————
  ${green}4.${plain} Restablecer contraseña de nombre de usuario
  ${green}5.${plain} Restablecer configuración del panel
  ${green}6.${plain} Configurar el puerto del panel
————————————————
  ${green}7.${plain} Lanzar v2-ui
  ${green}8.${plain} Detener v2-ui
  ${green}9.${plain} Reiniciar v2-ui
 ${green}10.${plain} Ver el estado de v2-ui
 ${green}11.${plain} Ver registros de v2-ui
————————————————
 ${green}12.${plain} Arranque Automatico v2-ui
 ${green}13.${plain} Cancelar el inicio de v2-ui
————————————————
 ${green}14.${plain} Instalar bbr (último kernel)
 "
    show_status
    echo && read -p "Por favor ingrese la selección [0-14]: " num

    case "${num}" in
        0) exit 0
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && update
        ;;
        3) check_install && uninstall
        ;;
        4) check_install && reset_user
        ;;
        5) check_install && reset_config
        ;;
        6) check_install && set_port
        ;;
        7) check_install && start
        ;;
        8) check_install && stop
        ;;
        9) check_install && restart
        ;;
        10) check_install && status
        ;;
        11) check_install && show_log
        ;;
        12) check_install && enable
        ;;
        13) check_install && disable
        ;;
        14) install_bbr
        ;;
        *) echo -e "${red}Por favor ingrese el número correcto [0-14]${plain}"
        ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0
        ;;
        "stop") check_install 0 && stop 0
        ;;
        "restart") check_install 0 && restart 0
        ;;
        "status") check_install 0 && status 0
        ;;
        "enable") check_install 0 && enable 0
        ;;
        "disable") check_install 0 && disable 0
        ;;
        "log") check_install 0 && show_log 0
        ;;
        "update") check_install 0 && update 0
        ;;
        "install") check_uninstall 0 && install 0
        ;;
        "uninstall") check_install 0 && uninstall 0
        ;;
        *) show_usage
    esac
else
    show_menu
fi
