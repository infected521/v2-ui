#!/usr/bin/env bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} Este script debe ejecutarse como usuario root！\n" && exit 1

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
    echo -e "${red}No se detectó la versión del sistema, póngase en contacto con el autor del script！${plain}\n" && exit 1
fi

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ] ; then
    echo "Este software no es compatible con sistemas de 32 bits (x86), utilice sistemas de 64 bits (x86_64), si la detección es incorrecta, comuníquese con el autor"
    exit -1
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
        echo -e "${red}Utilice CentOS 7 o superior！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Utilice Ubuntu 16 o superior！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Utilice Debian 8 o superior！${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}

install_v2ray() {
    echo -e "${green}Comience a instalar o actualizar v2ray${plain}"
    bash <(curl -L -s https://install.direct/go.sh)
    if [[ $? -ne 0 ]]; then
        echo -e "${red}v2ray  Falló la instalación o actualización, verifique el mensaje de error${plain}"
        exit 1
    fi
    systemctl enable v2ray
    systemctl start v2ray
}

close_firewall() {
    if [[ x"${release}" == x"centos" ]]; then
        systemctl stop firewalld
        systemctl disable firewalld
    elif [[ x"${release}" == x"ubuntu" ]]; then
        ufw disable
    elif [[ x"${release}" == x"debian" ]]; then
        iptables -P INPUT ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -P FORWARD ACCEPT
        iptables -F
    fi
}

install_v2-ui() {
    systemctl stop v2-ui
    cd /usr/local/
    if [[ -e /usr/local/v2-ui/ ]]; then
        rm /usr/local/v2-ui/ -rf
    fi
    last_version=$(curl -Ls "https://api.github.com/repos/sprov065/v2-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    echo -e "V2-ui última versión detectada：${last_version}，Comience la instalación"
    wget -N --no-check-certificate -O /usr/local/v2-ui-linux.tar.gz https://github.com/sprov065/v2-ui/releases/download/${last_version}/v2-ui-linux.tar.gz
    if [[ $? -ne 0 ]]; then
        echo -e "${red}No se pudo descargar v2-ui, asegúrese de que su servidor pueda descargar archivos Github. Si la instalación falla varias veces, consulte el tutorial de instalación manual${plain}"
        exit 1
    fi
    tar zxvf v2-ui-linux.tar.gz
    rm v2-ui-linux.tar.gz -f
    cd v2-ui
    chmod +x v2-ui
    cp -f v2-ui.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable v2-ui
    systemctl start v2-ui
    echo -e "${green}v2-ui v${last_version}${plain} La instalación ha finalizado y se inicia el panel，"
    echo -e ""
    echo -e "Para una instalación nueva, el puerto web predeterminado es ${green}65432${plain}，El nombre de usuario y la contraseña son predeterminados ${green}admin${plain}"
    echo -e "Asegúrese de que este puerto no esté ocupado por otros programas，${yellow}Y asegúrese de que el puerto 65432 esté liberado${plain}"
    echo -e ""
    echo -e "Si actualiza el panel, acceda al panel como lo hizo antes"
    echo -e ""
    curl -o /usr/bin/v2-ui -Ls https://raw.githubusercontent.com/infected521/v2-ui/master/v2-ui.sh
    chmod +x /usr/bin/v2-ui
    echo "v2-ui Cómo usar el script de administración: "
    echo "------------------------------------------"
    echo "v2-ui              - Mostrar menú de gestión (más funciones)"
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
    read -p "Escribe el dominio registrado a esta vps: " domain
    echo ""
    echo "Para acceder al panel en su navegador escriba"
    echo "http://$domain:65432"
}

meu_ip="$(wget -qO- ipv4.icanhazip.com)"

crt_key() {
    echo ""
    echo "Instalacion de certificado y key para v2ray"
    echo ""
    echo "------------------------------------------"
    echo ""
    if [[ x"${release}" == x"centos" ]]; then
        yum install stunnel4 -y
    else
        apt install stunnel4 -y
    fi
       [[ ! -e /{*.key} ]] && read -p "Nombre del certificado (ejemplo:rock): " keyssl
       openssl genrsa -out /${keyssl}.key 2048
       openssl req -new -key /${keyssl}.key -x509 -days 1000 -out /${keyssl}.crt
    echo ""
    echo "directorio del certificado en el panel"
    echo "[certificate file path] /${keyssl}.crt"
    echo ""
    echo "directorio de la key en el panel"
    echo "[key file path] /${keyssl}.key"
    echo "------------------------------------------"
    read -p "Enter para continuar: " continuar
}

echo -e "${green}Comience la instalación${plain}"
install_base
install_v2ray
crt_key
install_v2-ui

