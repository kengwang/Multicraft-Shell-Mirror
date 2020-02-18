#!/bin/bash

# author:Kengwang
# url:blog.tysv.top
# V2.0.0全新起航! 借鉴于 ToyoDAdoubi/doubi 的脚本风格,于2019/8/13开始重构
# 2020/2/18 0:16 完成初步重构 明天就要开始网课了......
# 可能是一个永远也写不完的东西吧......
# 这个究竟会不会被弃坑,这个也是个未知迷
# 加油吧,Stay Cool~
# Ubuntu我是真的准备放弃了!
# 这次一定要详细注释了!!!

# ---------------------------------------------------变量表-------------------------------------------------------

# 脚本配置相关
SHVersion="2.0.0"               #脚本版本
ConfigPath="${PWD}/mush.config" #脚本配置文件路径,勿删
Mirror="4"                      #镜像编号
MuVer=""                        #Multicraft编号
ApiUrl="http://mush.tysv.top/"  #Api路径
OSVersion="Unknown"             #系统版本 C6/C7

# 显示颜色相关 - 摘录自doubi脚本
Font_Green="\033[32m " && Font_Red="\033[31m " && Background_Green="\033[42;37m " && Background_Red="\033[41;37m " && Font_end=" \033[0m"
Info="${Font_Green}[信息]${Font_end}"
Error="${Font_Red}[错误]${Font_end}"
Tip="\033[33m [注意]${Font_end}"

# Multicraft配置相关
Database="mysql"
mysqlpw=""
mudpassword=""
webport="80"
mu_key="none"
multicraft_InstallPATH="/home/minecraft/multicraft/"
unintmy="yes"
SETTING=""

# -------------------------------------------------函数集---------------------------------------------------------

################################################ Multicraft类 ####################################################

# *************************** 基础类 ****************************

# Multicraft 是否安装
function Multicraft_CheckInstall() {
  conf=$(cat ${multicraft_InstallPATH}/multicraft.conf)
  if [[ $? -eq 0 ]]; then
    return 1
  else
    return 0
  fi
}

# Multicraft 是否开启
function Multicraft_CheckOpen() {
  MuPID=$(cat ${multicraft_InstallPATH}/multicraft.pid)
  if [[ $? -eq 0 ]]; then
    ret=$(ps -p ${MuPID})
    if [[ $? -eq 0 ]]; then
      return 1
    else
      return 0
    fi
  else
    return 0
  fi
}

# 输出Multicraft状态
function Multicraft_OutputStatus() {
  Multicraft_CheckInstall
  if [[ $? -eq 1 ]]; then
    Multicraft_CheckOpen
    if [[ $? -eq 1 ]]; then
      clear
      echo -e "${Info} Multicraft 已经${Background_Green}开启${Font_end}"
    else
      clear
      echo -e "${Tip} Multicraft ${Font_Red}未开启${Font_end}"
    fi
  else
    clear
    echo -e "${Error} Multicraft ${Background_Red}未安装${Font_end}"
  fi
}

# 开启 Multicraft $1:开启的方式
function Multicraft_Start() {
  clear
  if [[ "$1" != "" ]]; then
    /home/minecraft/multicraft/bin/multicraft $1
  fi
  Multicraft_OutputStatus
}

# ******************* 安装类 **********************

# ===================原本的安装方法##################

function repl() {
  LINE="$SETTING = $(echo -e $1 | sed "s/['\&,]/\\&/g")"
}

function realinstallmu() {
  MC_JAVA="$(which java)"
  MC_ZIP="$(which zip)"
  MC_UNZIP="$(which unzip)"
  MC_USERADD="$(which useradd)"
  MC_GROUPADD="$(which groupadd)"
  MC_USERDEL="$(which userdel)"
  MC_GROUPDEL="$(which groupdel)"
  MC_USER="minecraft"
  MC_DIR=${multicraft_InstallPATH}
  MC_DB_TYPE=${Database}
  MC_DB_PASS=${mysqlpw}
  MC_WEB_USER="apache"
  MC_DAEMON_PW=${mudpassword}
  INSTALL="bin/ jar/ launcher/ scripts/ templates/ eula.txt multicraft.conf.dist default_server.conf.dist server_configs.conf.dist"

  if [[ -e "$MC_DIR/bin/multicraft" ]]; then
    echo -e "正在关闭运行中的Daemon"
    "$MC_DIR/bin/multicraft" stop
    "$MC_DIR/bin/multicraft" stop_ftp
    echo -e "完成."
    sleep 1
  fi
  echo -e
  echo -e "正在创建用户: '$MC_USER'"
  "$MC_GROUPADD" minecraft
  if [[ ! "$?" = "0" ]]; then
    echo -e "错误: 不能创建用户组 '$MC_USER'! 请创建后重新运行脚本"
  fi

  "$MC_USERADD" "$MC_USER" -g "$MC_USER" -s /bin/false
  if [[ ! "$?" = "0" ]]; then
    echo -e "错误: 不能创建用户 '$MC_USER'! 请手动创建此用户然后重新安装"
  fi

  echo -e
  echo -e "创建目录 '$MC_DIR'"
  mkdir -p "$MC_DIR"

  echo -e
  echo -e "确保该目录可以被'$MC_DIR'读取并修改"
  MC_HOME="$(grep "^$MC_USER:" /etc/passwd | awk -F":" '{print $6}')"
  mkdir -p "$MC_HOME"
  chown "$MC_USER":"$MC_USER" "$MC_HOME"
  chmod u+rwx "$MC_HOME"
  chmod go+x "$MC_HOME"

  echo -e
  if [[ -e "$MC_DIR/bin" && "$(cd "bin/" && pwd)" != "$(cd "$MC_DIR/bin" 2>/dev/null && pwd)" ]]; then
    mv "$MC_DIR/bin" "$MC_DIR/bin.bak"
  fi
  for i in ${INSTALL}; do
    echo -e "安装 '$i' 到 '$MC_DIR/$i'"
    cp -a "$i" "$MC_DIR/"
  done
  echo -e "删除不必要的文件......"
  rm -f "$MC_DIR/bin/_weakref.so"
  rm -f "$MC_DIR/bin/collections.so"
  rm -f "$MC_DIR/bin/libpython2.5.so.1.0"
  rm -f "$MC_DIR/bin/"*-py2.5*.egg

  if [[ "$mu_key" == "" ]]; then
    MC_KEY="no"
  fi

  if [[ "$mu_key" != "no" ]]; then
    echo -e
    echo -e "安装Multicraft密钥"
    echo -e "$mu_key" >"$MC_DIR/multicraft.key"
  fi

  ### Generate config

  echo -e
  CFG="$MC_DIR/multicraft.conf"
  if [[ -e "$CFG" ]]; then
    echo -e "配置文件已经存在!默认替换!"
  fi

  if [[ "$Database" = "mysql" ]]; then
    DB_STR="mysql:host=127.0.0.1;dbname=multicraft_daemon"
  fi

  if [[ ! -e "$CFG" ]]; then

    if [[ -e "$CFG" ]]; then
      echo -e "Multicraft.conf 已经存在,正在备份..."
      cp -a "$CFG" "$CFG.bak"
    fi

    echo -e "创建 'multicraft.conf'"
    >"$CFG"
    ip=$(curl -L http://www.multicraft.org/ip)
    SECTION=""
    MC_LOCAL="y"
    cat "$CFG.dist" | while IFS="" read -r LINE; do
      if [[ "$(echo -e ${LINE} | grep "^ *\[\w\+\] *$")" ]]; then
        SECTION="$LINE"
        SETTING=""
      else
        SETTING="$(echo -e ${LINE} | sed -n 's/^ *\#\? *\([^ ]\+\) *=.*/\1/p')"
      fi
      case "$SECTION" in
      "[multicraft]")
        case "$SETTING" in
        "user") repl "minecraft" ;;
        "ip") if [[ "$MC_LOCAL" != "y" ]]; then repl "0.0.0.0"; fi ;;
        "port") if [[ "$MC_LOCAL" != "y" ]]; then repl "25465"; fi ;;
        "password") repl "$MC_DAEMON_PW" ;;
        "id") repl "1" ;;
        "database") if [[ "$MC_DB_TYPE" = "mysql" ]]; then repl "$DB_STR"; fi ;;
        "dbUser") if [[ "$MC_DB_TYPE" = "mysql" ]]; then repl "root"; fi ;;
        "dbPassword") if [[ "$MC_DB_TYPE" = "mysql" ]]; then repl "$MC_DB_PASS"; fi ;;
        "webUser") if [[ "$MC_DB_TYPE" = "mysql" ]]; then repl ""; else repl "$MC_WEB_USER"; fi ;;
        "baseDir") repl "$MC_DIR" ;;
        esac
        ;;
      "[ftp]")
        case "$SETTING" in
        "enabled") if [[ "aaa" = "aaa" ]]; then repl "true"; else repl "false"; fi ;;
        "ftpIp") repl "0.0.0.0" ;;
        "ftpExternalIp") if [[ ! "$ip" = "" ]]; then repl "$ip"; fi ;;
        "ftpPort") repl "21" ;;
        "forbiddenFiles") if [[ "a" = "ymmm" ]]; then repl ""; fi ;;
        esac
        ;;
      "[minecraft]")
        case "$SETTING" in
        "java") repl "$MC_JAVA" ;;
        esac
        ;;
      "[system]")
        case "$SETTING" in
        "unpackCmd") repl "$MC_UNZIP"' -quo "{FILE}"' ;;
        "packCmd") repl "$MC_ZIP"' -qr "{FILE}" .' ;;
        esac
        if [[ "y" = "y" ]]; then
          case "$SETTING" in
          "multiuser") repl "true" ;;
          "addUser") repl "$MC_USERADD"' -c "Multicraft Server {ID}" -d "{DIR}" -g "{GROUP}" -s /bin/false "{USER}"' ;;
          "addGroup") repl "$MC_GROUPADD"' "{GROUP}"' ;;
          "delUser") repl "$MC_USERDEL"' "{USER}"' ;;
          "delGroup") repl "$MC_GROUPDEL"' "{GROUP}"' ;;
          esac
        fi
        ;;
      "[backup]")
        case "$SETTING" in
        "command") repl "$MC_ZIP"' -qr "{WORLD}-tmp.zip" . -i "{WORLD}"*/*' ;;
        esac
        ;;
      esac
      echo -e "$LINE" >>"$CFG"
    done
  fi

  echo -e
  echo -e "设置 '$MC_DIR' 的拥有者为 '$MC_USER'"
  chown "$MC_USER":"$MC_USER" "$MC_DIR"
  chown -R "$MC_USER":"$MC_USER" "$MC_DIR/bin"
  chown -R "$MC_USER":"$MC_USER" "$MC_DIR/launcher"
  chmod 555 "$MC_DIR/launcher/launcher"
  chown -R "$MC_USER":"$MC_USER" "$MC_DIR/jar"
  chown -R "$MC_USER":"$MC_USER" "$MC_DIR/scripts"
  chmod 555 "$MC_DIR/scripts/getquota.sh"
  chown -R "$MC_USER":"$MC_USER" "$MC_DIR/templates"
  chown "$MC_USER":"$MC_USER" "$MC_DIR/default_server.conf.dist"
  chown "$MC_USER":"$MC_USER" "$MC_DIR/server_configs.conf.dist"

  echo -e "设置特殊的权限"

  chown 0:"$MC_USER" "$MC_DIR/bin/useragent"
  chmod 4550 "$MC_DIR/bin/useragent"

  chmod 755 "$MC_DIR/jar/"*.jar 2>/dev/null

  ### Install PHP frontend
  MC_WEB_DIR="/var/www/html"
  if [[ "y" = "y" ]]; then
    echo -e

    if [[ -e "$MC_WEB_DIR" && -e "$MC_WEB_DIR/protected/data/data.db" ]]; then
      echo -e "网页面板文件存在,正在备份 protected/data/data.db"
      cp -a "$MC_WEB_DIR/protected/data/data.db" "$MC_WEB_DIR/protected/data/data.db.bak"
    fi

    echo -e "创建目录 '$MC_WEB_DIR'"
    mkdir -p "$MC_WEB_DIR"

    echo -e "安装网页面板 'panel/' to '$MC_WEB_DIR'"
    cp -a panel/* "$MC_WEB_DIR"
    cp -a panel/.ht* "$MC_WEB_DIR"

    echo -e "设置 '$MC_WEB_DIR' 的主人为 '$MC_WEB_USER'"
    chown -R "$MC_WEB_USER":"$MC_WEB_USER" "$MC_WEB_DIR"
    echo -e "设置权限给 '$MC_WEB_DIR'"
    chmod -R o-rwx "$MC_WEB_DIR"

  else
    ### PHP frontend not on local machine
    echo -e
    echo -e "* 注意: 网页面板不会安装到这台机子"
  fi

  echo -e "尝试运行来设置权限"
  "$MC_DIR/bin/multicraft" set_permissions

}

function Multicraft_Download() {
  wget "${ApiUrl}/api.php?f=Download&mirror=${Mirror}&file=${MuVer}" -O multicraft.tar.gz
  if [[ $? -ne 0 ]]; then
    ThrowError "下载 Multicraft 错误"
  fi
  echo "正在校验文件......"
  servermd5=$(curl "${ApiUrl}/api.php?f=getMd5&file=${MuVer}")
  localmd5=$(md5sum multicraft.tar.gz | cut -d ' ' -f1)

  if [[ "$servermd5" != "$localmd5" ]]; then
    ThrowError "服务端MD5: ${Background_Green} ${servermd5} ${Font_end}
本地MD5: ${Background_Green} ${localmd5} ${Font_end}
不相符,可能是镜像文件出了问题,也可能是文件被篡改"
  else
    echo "${Info} 文件校验成功"
  fi
  tar xfvz multicraft.tar.gz
  if [[ $? -ne 0 ]]; then
    ThrowError "解压Multicraft文件错误"
  fi
}

function Multicraft_Install() {
  setenforce 0
  AskAllThing
  clear
  echo -e "${Info} 正在安装"
  InstallYum
  Mysql_Install
  Mysql_ChangePassword
  Mysql_InitDatabase
  Multicraft_Download
  echo -e "${Info} 开始安装 Multicraft"
  cd ./multicraft
  realinstallmu
  echo -e "${Info} 安装完成,正在启动"
  ${multicraft_InstallPATH}/bin/multicraft start
  if [[ $? -ne 0 ]]; then
    ThrowError "启动失败,可能安装出错"
  fi
  Multicraft_Start
  echo
  DisplayConfig
}

function InstallYum() {
  yum clean all
  yum makecache
  yum -y update
  yum -y install java-1.8.0-openjdk java-1.7.0-openjdk java-11-openjdk vim unzip zip wget gcc gcc-c++ kernel-devel httpd php nano php-gd php-ldap php-odbc php-pear php-xml php-xmlrpc php sed httpd-manual mod_ssl vim
  if [[ $? -ne 0 ]]; then
    ThrowError "必要组件安装失败,请检查报错,如无伤大雅可继续以便重试"
    yum -y install java-1.8.0-openjdk java-11-openjdk vim unzip zip wget gcc gcc-c++ kernel-devel httpd php nano php-gd php-ldap php-odbc php-pear php-xml php-xmlrpc php sed httpd-manual mod_ssl vim
  fi
}

#################################################### 杂七杂八 ####################################################

function DisplayConfig() {
  clear
  echo -e "${Background_Green}安装成功!${Font_end} 下面是您需要记住的信息和接下来的操作
============= 别忘了给作者打赏啊! ==================
数据库地址: 127.0.0.1
数据库账号: root
数据库密码: ${mysqlpw}
Daemon密码: ${mudpassword}
Multicraft安装路径: ${multicraft_InstallPATH}
============ 下面是您要执行的操作 ==================
1.假如说要改成88端口,请重启脚本,选择Https设置 - 端口设置 来设置端口
2.假如想要开机启动请重启脚本 选择 系统设置 - 设置Multicraft开机启动
3.记得给作者打赏啊! 有问题联系QQ: 1136772134"
}

function AskAllThing() {
  echo -e "正在检测API可用性......"

  if [[ $(curl "$ApiUrl/api.php?f=check") != "Pass" ]]; then
    ThrowError "链接到API失败,请检查版本是否正确"
  fi
  clear
  curl "$ApiUrl/api.php?f=GetMirror"
  read -p "请输入要选择的源的序号数字" Mirror
  clear

  echo -e "请稍等,正在获取版本......"

  clear
  curl "${ApiUrl}/api.php?f=GetAvailable"

  read -p "请输入要安装的选项(数字): " MuVer

  read -p "请选择要安装的数据库,请按照格式 [mysql]/sqlite : " Database
  if [[ "$Database" != "sqlite" ]]; then
    Database="mysql"
  fi
  echo -e "中国大陆使用yum可能速度稍慢,建议换成中国的阿里云的源"
  read -p "是否使用阿里源 ( mirrors.aliyun.com ) [yes]/no" alisource
  if [[ "$alisource" != "no" ]]; then
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    if [[ "$OSVersion" == "CentOS6" ]]; then
      wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
    elif [[ "$OSVersion" == "CentOS7" ]]; then
      wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    elif [[ "$OSVersion" == "CentOS8" ]]; then
      wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
    else
      echo -e "换源失败,版本错误"
    fi
  fi

  if [[ "$Database" == "mysql" ]]; then
    echo -e "您选择了MySQL数据库!正在检测您的MySQL安装情况"
    if [[ $(yum list installed | grep -E "mariadb|mysql" | wc -l) != 0 ]]; then
      echo -e "${Tip} 您已安装了 MySQL 数据库"
      read -p "是否要还原MySQL,这会清空你的MySQL数据库(新机请选择yes) no/[yes]: " uninsmy
      if [[ "$uninsmy" == "" ]]; then
        uninsmy="yes"
      fi
    fi

    echo -e "请输入您想设置的MySQL密码(如果你原本有数据库且选择保留数据,请输入原本的MySQL的密码)[留空随机]"
    read -p "作者保证不会泄露您的密码: " mysqlpw
    if [[ "$mysqlpw" == "" ]]; then
      mysqlpw=$(cat /dev/urandom | head -n 10 | md5sum | head -c 18)
    fi
    echo -e "您的密码设置为: $mysqlpw 为您暂停十秒确定和记忆"
    sleep 1
  fi

  read -p "请输入您要设置的Multicraft Daemon密码[必填 留空随机]:" mudpassword
  if [[ "$mudpassword" == "" ]]; then
    mudpassword=$(cat /dev/urandom | head -n 10 | md5sum | head -c 18)
  fi
  read -p "请输入Multicraft安装目录 [/home/minecraft/multicraft]: " mudir
  if [[ "$mudir" == "" ]]; then
    mudir="/home/minecraft/multicraft"
  fi

  read -p "请输入Multicraft许可证密钥 [none]:" mukey
  read -p "请输入网页面板要使用的端口 [80]: " aport
  if [[ "$aport" == "" ]]; then
    aport="80"
  fi
  echo -e "正在自动安装……如果不出意外的话,应该不会有问题吧......"
  echo -e "倒计时5秒 随时按 Ctrl+c 退出脚本"
  sleep 1
  echo -e "倒计时4秒 最好不要离开,免得出错后来不及处理"
  sleep 1
  echo -e "倒计时3秒 感谢Frank大佬的支持!"
  sleep 1
  echo -e "倒计时2秒 作者Kengwang,禁止盗版,此脚本只是为了方便,不可能完美支持"
  sleep 1
  echo -e "倒计时1秒 作者QQ 1136772134"
  sleep 1
  echo -e "正在载入……"
}

#################################################### 数据库类 ####################################################

# 安装MySQL
function Mysql_Install() {
  if [[ "$unintmy" == "yes" ]]; then
    echo -e "正在删除MySQL数据库"
    if [[ "$OSVersion" == "CentOS6" || "$OSVersion" == "CentOS8" ]]; then
      yum -y remove mysql mysql-server
    elif [[ "$OSVersion" == "CentOS7" ]]; then
      yum -y -q remove mariadb mariadb-server
    else
      ThrowError "无法获取到当前系统版本 当前仅支持 ${Font_Green}CentOS6/7/8${Font_end}"
    fi
    rm -rf /var/lib/mysql
    rm -rf /root/.mysql_sercret
    rm -rf /etc/my.cnf
  fi
  echo -e "正在尝试安装MySQL"
  if [[ "$OSVersion" == "CentOS7" ]]; then
    yum -y install mariadb mariadb-server
  elif [[ "$OSVersion" == "CentOS6" || "$OSVersion" == "CentOS8" ]]; then
    yum -y install mysql mysql-server
  else
    ThrowError "无法获取到当前系统版本 当前仅支持 ${Font_Green}CentOS6/7/8${Font_end}"
  fi

  if [[ $? -ne 0 ]]; then
    ThrowError "MySQL安装失败"
  else
    echo -e "MySQL安装成功"
  fi
}

function Mysql_Restart() {
  if [[ ${OSVersion} == "CentOS7" ]]; then
    service mariadb restart
  else
    service mysqld restart
  fi
}

function Mysql_Stop() {
  if [[ ${OSVersion} == "CentOS7" ]]; then
    service mariadb stop
  else
    service mysqld stop
  fi
}

function Mysql_Start() {
  if [[ ${OSVersion} == "CentOS7" ]]; then
    service mariadb start
  else
    service mysqld start
  fi
}

# 更改MySQL密码
function Mysql_ChangePassword() {
  if [[ "$unintmy" == "yes" ]]; then
    echo -e "正在尝试启动${OSVersion}MySQL服务"
    Mysql_Restart
    if [[ $? -eq 0 ]]; then
      echo -e "正在修改您的MySQL密码"
      mysqladmin -u root password ${mysqlpw}
      sleep 3
      echo -e "冷却完成,正在开启MySQL以测试"
      Mysql_Restart
    else
      ThrowError "启动MySQL服务${Font_Red}失败${Font_end},请检查MySQL安装状态"
      exit
    fi
  fi
}

# 创建数据库
function Mysql_InitDatabase() {
  echo -e "正在尝试创建数据库"
  mysql -uroot -p${mysqlpw} <<EOF
create database multicraft_daemon;create database multicraft_panel;
EOF
}

##################################################### 系统类 #####################################################

# 检测Root权限
function OS_CheckRoot() {
  [[ $EUID != 0 ]] && echo -e "${Error} 当前账号非ROOT(或没有ROOT权限)，无法继续操作，请使用${Background_Red} su root ${Font_end}来获取临时ROOT权限（执行后会提示输入当前账号的密码）。" && stty erase ^? && exit 1
}

# 刷新系统版本
function OS_RefreshOSVersion() {
  cv=$(cat /etc/redhat-release | sed -r 's/.* ([0-9]+)\..*/\1/')
  if [[ ${cv} -eq 6 ]]; then
    #CentOS 6
    OSVersion="CentOS6"
  elif [[ ${cv} -eq 7 ]]; then
    #CentOS 7
    OSVersion="CentOS7"
  elif [[ ${cv} -eq 8 ]]; then
    #Centos 8
    OSVersion="CentOS8"
  else
    ThrowError "您的系统版本不支持此脚本,目前支持CentOS6/7/8"
  fi
}

# 升级系统组件
function OS_UpdatePackage() {
  echo -e "正在为第一次安装做准备"
  yum -q clean all
  yum -q makecache
  if [[ $? -ne 0 ]]; then
    ThrowError "生成Yum缓存失败 请检查报错"
  fi
  echo -e "准备完成,正在升级组件"
  yum -y -q update
  if [[ $? -ne 0 ]]; then
    ThrowError "Yum升级组件失败 请检查报错"
  fi
  echo -e "固件升级完成"
}

# 安装必要组件
function OS_InstallUsefulPackage() {
  echo -e "${Info} 正在安装必要组件"
  yum -y -q install vim java-1.8.0-openjdk vim unzip zip wget gcc gcc-c++ kernel-devel httpd php nano php-mysql php-gd php-imap php-ldap php-odbc php-pear php-xml php-xmlrpc PHP sed httpd-manual mod_ssl mod_perl mod_auth_mysql
  if [[ $? -ne 0 ]]; then
    ThrowError "Yum安装必要组件失败 请检查报错"
  fi
  echo -e "固件升级完成"
}

#################################################### 脚本类 ######################################################

# 指令执行失败提示
function ThrowError() {
  echo -e "$Error $1"
  echo -e "按 ${Font_Green}[Enter]$Font_end 继续执行  按 ${Font_Red}[Ctrl + C]${Font_end} 终止脚本"
  stty erase ^?
  read -p "" a
  stty erase ^H
}

# 升级脚本
function Shell_Update() {
  echo -e "${Info} 正在下载最新版脚本"
  wget -O multicraft.sh "https://multicraftshell.oss-cn-beijing.aliyuncs.com/multicraft.sh"
  chmod 755 multicraft.sh
  bash multicraft.sh
  stty erase ^?
  exit 0
}

#################################################### 窗口 #######################################################

# 窗口 : Main

function Init() {
  OS_CheckRoot
  clear
  echo -e "
    Multicraft 一键脚本 ${Background_Green}[$SHVersion]${Font_end}
    -> 作者Kengwang [QQ:${Background_Green}1136772134${Font_end}] <-
    $Info 你的系统版本为 ${Background_Green}[${OSVersion}]${Font_end}
    ===========*${Background_Green}主菜单${Font_end}*===========
    = ${Font_Green}1.${Font_end} Multicraft 设置
    = ${Font_Green}2.${Font_end} Httpd 设置
    = ${Font_Green}3.${Font_end} MySQL 设置
    = ${Font_Green}4.${Font_end} 系统 设置 (未完成)
    = ${Font_Green}5.${Font_end} 其他 设置 (未完成)

    ----------脚本功能-------------
    = ${Background_Red}0. 升级脚本${Font_end}

    = ${Background_Red}按 Ctrl + C 退出脚本${Font_end}
    "
  echo -e && read -e -p "请输入数字 [0-5]：" num

  case "$num" in
  1)
    Submenu_Multicraft
    ;;
  2)
    Submenu_Httpd
    ;;
  3)
    Submenu_MySQL
    ;;
  4)
    Submenu_OS
    ;;
  5)
    Submenu_Other
    ;;
  0)
    Shell_Update
    ;;
  *)
    echo -e "${Error} 请输入正确的数字 [0-5]"
    ;;
  esac
}

function Submenu_MySQL() {
  clear
  echo -e "
   ============= MySQL 设置 ==============

   = ${Font_Green}1.${Font_end} 开启MySQL
   = ${Font_Green}2.${Font_end} 关闭MySQL
   = ${Font_Green}3.${Font_end} 修改MySQL密码

   = ${Font_Red}0.${Font_end} 返回上一级
"

  read -p "请输入编号 [0-3]: " num
  case $num in
  1)
    Mysql_Restart
    ;;
  2)
    Mysql_Stop
    ;;
  3)
    Submenu_MySQLPassword
    ;;
  0)
    Init
    ;;
  *)
    echo -e "${Error} 请输入正确的数字 [0-11]"
    ;;
  esac
}

function Submenu_MySQLPassword() {
  read -p "请输入原密码,如无原密码直接回车" oldpw
  read -p "请输入要修改成的密码" mysqlpw
  if [[ "$oldpw" == "" ]]; then
    pwc=""
  else
    pwc=" -p $oldpw"
  fi
  if [[ "$unintmy" == "yes" ]]; then
    echo -e "正在尝试启动${OSVersion}MySQL服务"
    Mysql_Restart
    if [[ $? -eq 0 ]]; then
      echo -e "正在修改您的MySQL密码"
      mysqladmin -u root${pwc} password ${mysqlpw}
      sleep 3
      echo -e "冷却完成,正在开启MySQL以测试"
      Mysql_Restart
    else
      ThrowError "启动MySQL服务${Font_Red}失败${Font_end},请检查MySQL安装状态"
    fi
  fi
}

# 子窗口 : Main-Multicraft
function Submenu_Multicraft() {
  Multicraft_OutputStatus
  echo -e "
    ================= Multicraft 设置 =========================
    = ${Font_Green}1.${Font_end} 开启 Multicraft
    = ${Font_Green}2.${Font_end} 关闭 Multicraft
    = ${Font_Green}3.${Font_end} 重启 Multicraft
    = ${Font_Green}4.${Font_end} 重启 FTP
    = ${Font_Green}5.${Font_end} 设置权限
    --------------------------------------------------
    = ${Font_Green}6.${Font_end} 安装 Multicraft
    = ${Font_Green}7.${Font_end} 卸载 Multicraft (测试)
    = ${Font_Green}8.${Font_end} 安装 Multicraft Panel (未完成)
    = ${Font_Green}9.${Font_end} 根据multicraft.conf配置面板 (未完成)
    --------------------------------------------------
    = ${Font_Green}10.${Font_end} 安装 Multicraft 数据库 (未完成)
    = ${Font_Green}11.${Font_end} 重置 Multicraft (未完成)

    => ${Background_Green}0. 返回上一级菜单${Font_end}
    "
  echo -e && read -e -p "请输入数字 [0-11]：" num

  case "$num" in
  1)
    Multicraft_Start "start"
    ;;
  2)
    Multicraft_Start "stop"
    ;;
  3)
    Multicraft_Start "restart"
    ;;
  4)
    Multicraft_Start "restart_ftp"
    ;;
  5)
    Multicraft_Start "set_permissions"
    ;;
  6)
    Multicraft_Install
    ;;
  7)
    Multicraft_Uninstall
    ;;
  8)
    Multicraft_InstallPanel
    ;;
  9)
    Multicraft_GenerateConfig
    ;;
  10)
    Multicraft_InstallDatabase
    ;;
  11)
    Multicraft_Reset
    ;;
  0)
    Init
    ;;
  *)
    echo -e "${Error} 请输入正确的数字 [0-11]"
    ;;
  esac
}

function Submenu_HttpdAccess() {
  echo "正在备份httpd配置"
  cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bak
  echo "正在开启htaccess"
  sed -i "s/AllowOverride None/AllowOverride All/g" /etc/httpd/conf/httpd.conf
  res=$(cat /etc/httpd/conf/httpd.conf | grep 'AllowOverride None')
  service httpd restart
  if [[ $? -ne 0 ]]; then
    echo "失败,正在恢复配置文件"
    cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bak
    stty erase ^?
    exit
  fi
  echo "成功"

}

# Submenu - Httpd
function Submenu_Httpd() {
  clear

  echo -e "
=================== HTTPD 设置 ======================

${Font_Green}1.${Font_end} HTTPD端口设置
${Font_Green}2.${Font_end} .htaccess 允许

${Font_Red}0.${Font_end} 返回上一级"

  echo && read -e -p "请输入数字 [0-2]：" num

  case ${num} in
  1)
    Submenu_HttpdPort
    ;;
  2)
    Submenu_HttpdAccess
    ;;
  0)
    Init
    ;;
  *)
    echo -e "${Error} 请输入正确的数字 [0-11]"
    ;;
  esac
}

function Submenu_HttpdPort() {
  clear
  read -p "请输入您要设置并开放的端口: " port
  echo -e "正在开放端口 $port"
  systemctl disable firewalld
  setenforce 0
  echo "SELINUX=disable" >/etc/selinux/config
  chkconfig iptables off
  if [[ "$OSVersion" != "CentOS6" ]]; then
    firewall-cmd --get-active-zones
    status=$(firewall-cmd --zone=public --add-port=${port}/tcp --permanent)
    firewall-cmd --reload
    if [[ "$status" != "success" || $? -ne 0 ]]; then
      echo -e "开放失败"
    else
      echo -e "开放成功"
    fi
  fi
  echo "正在备份httpd配置"
  cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bak
  sent=$(cat /etc/httpd/conf/httpd.conf | grep 'Listen ' | awk 'END {print}')
  sed -i "s/$sent/Listen $port/g" /etc/httpd/conf/httpd.conf
  echo -e "即将重启httpd"
  sleep 5
  clear
  service httpd restart
  if [[ $? -ne 0 ]]; then
    echo "失败,正在恢复配置文件"
    cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bak
    stty erase ^?
    exit
  else
    echo -e "${Info} 端口更改成功"
  fi
}

# 载入开始
stty erase '^H'
OS_CheckRoot
OS_RefreshOSVersion
Init
