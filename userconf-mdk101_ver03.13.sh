#!/bin/bash
#
#
# Определение текущей локали
#===============================================================================

locale | grep LANG= | awk -F = '{ print $2 }' | grep -q -i  ru_ru.koi8
if [ $? = 0 ]
then
	LANG_MESSAGE=0
else
	LANG_MESSAGE=1
fi
#export LANG=POSIX
#export LC_ALL=POSIX
#NAME_DIR_SH=`dirname $0`
#NAME_SH=`basename $0`

# Проверка от какого пользователя запущен скрипт
#===============================================================================

USER_ID=`id -u`
if [ $USER_ID != 0 ]
then
	if [ $LANG_MESSAGE = 0 ]
	then
		echo -e "Скрит запущен не от пользователя root"
		echo -e "Регистрация пользователем root, нужно ввести пароль"
	else
		echo -e "Script is running not as root"
		echo -e "Check the root user will need to enter your password..."
	fi
	exit 11
fi

# Используемые переменные в скрипте
#===============================================================================
Ver="03"
SubVer="12"
DateVer="170825-20"
USERDIR="/var/tmp/"
DATEFILE=`date +%y%m%d` # дата сбора файла в формате гг.мм.дд
#DISTR_VER=`cat /etc/redhat-release`
DISTR_VER=`cat /etc/issue`
DISTR_VER_LIST="5.3\|5.4\|5.5\|5.6\|5.7\|5.8\|5.9\|6.0\|6.4\|6.7\|6.8\|7.0\|7.3\|7.4" # версии RHEL
# Определние операциооной системы
#===============================================================================
DISTR=`echo $DISTR_VER | awk '{print $1}' | tr [a-z] [A-Z]`
#===============================================================================
NAME_BIN_LIST="tree lspci lshw lspcidrake lsof xmessage rsync script hdparm sdparm usbutils"
LIST_BIN="cdrecord mkisofs pppd dip diplogin ifconfig route"
USERCONFLOG="userconf.log"
HOSTNAME=`echo $HOSTNAME | awk -F "." '{ print $1 }'`
USERCONFVER="userconf.ver"
VOCH="/usr/local/voch" # Рабочий каталог VOCH (видеонаблюдение)
SENCELOCK_ID="0471:485d" # VendorID и ProductID ключей SenseLock

# список директорий с деревом АДИС и Живой сканер
#===============================================================================
#LISTPPLN="/papillon /papillon1 /papillon8"
LISTPPLN[0]=`grep -r "WORKDIR=" /etc/sysconfig/ | awk -F = '{ print $2 }' | sort | uniq`

# список директорий с бинарными файлами АДИС и Живой сканер
#===============================================================================
LISTBIN_P[0]=`grep -r "BINDIR=" /etc/sysconfig/papillon | awk -F "=" '{ print $2 }' | sort | uniq`
LISTBIN_L[0]=`grep -r "BINDIR=" /etc/sysconfig/lscan | awk -F "=" '{ print $2 }' | sort | uniq`

# список директорий с бинарными файлами АДИС и Живой сканер
#===============================================================================
LISTTOOLS_P[0]=`grep -r TOOLSDIR= /etc/sysconfig/papillon | awk -F "=" '{ print $2 }' | sort | uniq`
LISTTOOLS_L[0]=`grep -r TOOLSDIR= /etc/sysconfig/lscan | awk -F "=" '{ print $2 }' | sort | uniq`

# переменная записи в .log файл
#===============================================================================
ADDLOG="/$USERDIR/$HOSTNAME/$USERCONFLOG"
#===============================================================================
sleep 2

if [ $LANG_MESSAGE = 0 ]
then
	echo "Удаление старого архива"
else
	echo "Delete old archive"
fi
rm -frv /$USERDIR/$HOSTNAME
rm -fv /$USERDIR/$HOSTNAME.$Ver.*.tgz

if [ $LANG_MESSAGE = 0 ]
then
	echo  "*** СОЗДАНИЕ АРХИВА КОНФИГУРАЦИИ ЗАКАЗЧИКА ***"
else
	echo  "*** CREATE ARCHIVE USERCONF CUSTOMER  ***"
fi
sleep 2
mkdir /$USERDIR/$HOSTNAME
cd /$USERDIR/$HOSTNAME

# Вставка версии userconf-a и дата, время сборки userconf
#===============================================================================
echo "- $Ver.$SubVer.$DateVer" > /$USERDIR/$HOSTNAME/$USERCONFVER | tee -a "$ADDLOG"
date >>  /$USERDIR/$HOSTNAME/$USERCONFVER | tee -a "$ADDLOG"
echo "$DISTR_VER" >> /$USERDIR/$HOSTNAME/$USERCONFVER | tee -a "$ADDLOG"
#===============================================================================

# Сбор данных с DIPP6
#===============================================================================

DIPPli=`grep verify /etc/sysconfig/papillon`
echo $DIPPli | grep -q "verify"
REZ=$?
if [ $REZ = 0 ]
then
    mkdir /$USERDIR/$HOSTNAME/DiPP/
    mount /dev/mmcblk0p3 /mnt/flash
    find /mnt/flash/etc/ -xdev | cpio -pdvm /$USERDIR/$HOSTNAME/DiPP/
    find /mnt/flash/lsc/ -xdev | cpio -pdvm /$USERDIR/$HOSTNAME/DiPP/
    find /mnt/flash/var/ -xdev | cpio -pdvm /$USERDIR/$HOSTNAME/DiPP/
    umount /mnt/flash
else
    echo "- Не ДиПП6 - ничего не создаем и не копируем"  | tee -a "$ADDLOG"
fi

# Функция установки пакетов в зависимости от дистрибутива
#===============================================================================
install_util(){
which $1 > /dev/null
if [ $? != 0 ]
then
	if [ "$DISTR" = "MANDRAKELINUX" ] || [ "$DISTR" = "MANDRIVA" ] || [ "$DISTR" = "ROSA" ] || [ "$DISTR" = "OS" ]
	then
		urpmi $1
		if [ $? != 0 ]
		then
			echo "- Не настроен urpmi - установка $1 не удалась"  | tee -a "$ADDLOG"
		else
			echo "- Настроен urpmi - установка $1 удалась"  | tee -a "$ADDLOG"
		fi
	else
		if [ "$DISTR" = "RED" ] || [ "$DISTR" = "CENTOS" ]
		then
			yum install -y $1
			if [ $? != 0 ]
			then
				echo "- Не настроен yum - установка $1 не удалась"  | tee -a "$ADDLOG"
			else
				echo "- Настроен yum - установка $1 удалась"  | tee -a "$ADDLOG"
			fi
		fi
	fi
fi
}
	case $DISTR in ASTRA)
			dpkg -i /.1/astra/pool/main/t/tree/tree_*
			dpkg -i /.1/astra/pool/main/l/lshw/lshw*
			dpkg -i /.1/astra/pool/main/l/lsof/lsof_*
			dpkg -i /.1/astra/pool/main/s/sdparm/sdparm_*
	esac
# Доустановка необходимых утилит
#===============================================================================
for NAME_BIN in $NAME_BIN_LIST
do
    install_util $NAME_BIN
done
#===============================================================================

# Проверка на запуск X приложений
#===============================================================================
xmessage -timeout 1 Check
if [ $? = 0 ]
then
	clear
	echo -e ""
else
	clear
	if [ $LANG_MESSAGE = 0 ]
	then
	echo -e "ВЫХОД:"
	echo -e "Графика не экспортирована не будут собраны версии некоторых программ"
	echo -e "Для запуска графических приложений при использовании ssh"
	echo -e "сделайте ssh -X user@host\n"
	echo -e "Для продолжения нажмите Y для прерывания Q"
	else
	echo -e "EXIT:"
	echo -e "Graphics are not exported will not be collected, some versions of"
	echo -e "to run graphical applications using ssh"
	echo -e "fillow ssh -X user@host\n"
	echo -e "To continue, press Y to interrupt Q"
	fi
	read KEY
	if [ "$KEY" = "y" ] || [ "$KEY" = "Y" ]
	then
		echo -e "- Продолжаем сбор конфигурации выбор пользователя"  | tee -a "$ADDLOG" 
	else
		if [ "$KEY" = "q" ] || [ "$KEY" = "Q" ]
		then
			exit 127
		fi
	fi
fi
#===============================================================================


# Сетевые соединения
#===============================================================================
netstat -panto > netstat
#===============================================================================

# Список загруженых модулей
#===============================================================================
lsmod > lsmod
#===============================================================================

# Сбор версий загруженых модулей
#===============================================================================
for namemod in `cat lsmod | sed '1d' | awk '{print $1}'`
do
	echo "$namemod" >> modules_load.version
	modinfo $namemod >> modules_load.version
	echo "===================================" >> modules_load.version
done
#===============================================================================

# Таблица разделов IDE дисков до 8 дисков
#===============================================================================
df -h > df
for ide_liter in a b c d e f g h
do
    if [ -b /dev/hd$ide_liter ]
    then
    fdisk -l /dev/hd$ide_liter > /dev/null
    if [ $? = 0 ]
	then
	fdisk -l /dev/hd$ide_liter > hd$ide_liter
	TEST_LEN=`cat hd$ide_liter`
		if [ -z "$TEST_LEN" ]
		then
			rm hd$ide_liter
		fi
    fi
    DPARM=`which hdparm 2> /dev/null`
    if [ -n "$DPARM" ]
    then
	$DPARM -i /dev/hd$ide_liter > hd$ide_liter.dparm
	$DPARM -I /dev/hd$ide_liter >> hd$ide_liter.dparm
		TEST_LEN=`cat hd$ide_liter.dparm`
		if [ -z "$TEST_LEN" ]
		then
		rm hd$ide_liter.dparm
		echo "- Удаление файла /$USERDIR/$HOSTNAME/hd$ide_liter.dparm - размер файла 0" | tee -a "$ADDLOG"
		fi
    else
	echo "- Не найден исполняемый файл $DPARM - не настроен urpmi/yum" | tee -a "$ADDLOG"
    fi
    else
    echo "Нет устройства /dev/hd$ide_liter"
    fi
done
#===============================================================================

# Таблица разделов SCSI/SATA дисков до 8 дисков
#===============================================================================
for scsi_liter in a b c d e f g h
do
    if [ -b /dev/sd$scsi_liter ]
    then
    fdisk -l /dev/sd$scsi_liter > /dev/null
    if [ $? = 0 ]
	then
	fdisk -l /dev/sd$scsi_liter > sd$scsi_liter
	TEST_LEN=`cat sd$scsi_liter`
	        if [ -z "$TEST_LEN" ]
		then
			rm sd$scsi_liter
		fi
    fi
    DPARM=`which sdparm 2> /dev/null || which hdparm 2> /dev/null`
    if [ -n "$DPARM" ]
    then
	$DPARM -i /dev/sd$scsi_liter > sd$scsi_liter.dparm
	$DPARM -I /dev/sd$scsi_liter >> sd$scsi_liter.dparm
	TEST_LEN=`cat sd$scsi_liter.dparm`
	        if [ -z "$TEST_LEN" ]
		then
		rm sd$scsi_liter.dparm
		echo "- Удаление файла /$USERDIR/$HOSTNAME/sd$scsi_liter.dparm - размер файла 0" | tee -a "$ADDLOG"
		fi
    else
    echo "- Не найден исполняемый файл $DPARM - не настроен urpmi/yum" | tee -a "$ADDLOG"
    fi
    else
    echo "Нет устройства /dev/sd$scsi_liter"
    fi
done
#===============================================================================

# Спсиок процессов
#===============================================================================
ps axwf > ps
#===============================================================================

# Список смонтированных разделов
#===============================================================================
mount > mount
#===============================================================================

# Использование памяти
#===============================================================================
free > mem
cat /proc/meminfo >> mem
#===============================================================================

# Версия ядра и опреционной системы
#===============================================================================
uname -a > osversion
#===============================================================================

# Список установленных rpm пакетов
#===============================================================================
rpm -q -a > all_rpm
# Список установленных deb пакетов
#===============================================================================
dpkg -l > all_deb
#===============================================================================

# "Хвост" протокола загрузки
#===============================================================================
dmesg > dmesg
#===============================================================================

# Список открытых файлов (lsof) с проверкой, если команды нет то установка lsof
#===============================================================================
lsof > lsof
#===============================================================================

# Список usb устройств (lsusb) с проверкой, если команды нет то установка lsusb 
#===============================================================================
which lsusb > /dev/null
REZ=$?
if [ $REZ != 0 ]
then
    if [ "$DISTR" = "MANDRAKELINUX" ] || [ "$DISTR" = "MANDRIVA" ] || [ "$DISTR" = "ROSA" ] || [ "$DISTR" = "OS" ]
    then
	urpmi usbutils
	if [ $? = 0 ]
	then
	    lsusb > lsusb
	else
	    echo -e "- Установка (urpmi) lsusb - не удалась"  | tee -a "$ADDLOG"
	fi
    else
	if [ "$DISTR" = "RED" ] || [ "$DISTR" = "CENTOS" ]
	then
	yum install -y usbutils
		if [ $? = 0 ]
		then
	    		lsusb > lsusb
		else
	    		echo -e "- Установка (yum) lsusb - не удалась"  | tee -a "$ADDLOG"
		fi
	fi
    fi
else
    lsusb > lsusb
fi
    
#===============================================================================


#Читаем HASP ключ
#===============================================================================
ps axwf | grep -v grep | grep -q aksusbd
REZULT=$?
if [ "$REZULT" = "0" ]
then
    for INFO_HASP in keyinfo haspinfo hasphlinfo
    do
	for BINDIR in `echo $LISTBIN_P` `echo $LISTTOOLS_P` `echo $LISTBIN_L` `echo $LISTTOOLS_L`
	do
	which $INFO_HASP
	if [ $? = 0 ]
	then
		`which $INFO_HASP` -h > $INFO_HASP.hasp
	else
		if [ -x $BINDIR/$INFO_HASP ]
		then
		$BINDIR/$INFO_HASP -h > $INFO_HASP.hasp
	else
		echo -e "- Не найден исполняемый файл $INFO_HASP"  | tee -a "$ADDLOG" 
	fi
fi
done
done
else
	echo -e "- Не запущен aksusbd"  | tee -a "$ADDLOG" 
fi

#===============================================================================

#Читаем Senselock ключ
#===============================================================================
lsusb | grep -q "$SENCELOCK_ID"
REZULT=$?
if [ "$REZULT" = "0" ]
then
    for INFO_HASP in keyinfo
    do
	for BINDIR in `echo $LISTBIN_P` `echo $LISTTOOLS_P` `echo $LISTBIN_L` `echo $LISTTOOLS_L`
	do
	which $INFO_HASP
	if [ $? = 0 ]
	then
		`which $INFO_HASP` -h > $INFO_HASP.senselock
	else
		if [ -x $BINDIR/$INFO_HASP ]
		then
		$BINDIR/$INFO_HASP -h > $INFO_HASP.senselock
	else
		echo -e "- Не найден исполняемый файл $INFO_HASP"  | tee -a "$ADDLOG" 
	fi
fi
done
done
else
	echo -e "- Не найден SenceLock ключ"  | tee -a "$ADDLOG" 
fi

#===============================================================================


# Конфигурация SAMBA
#===============================================================================
testparm -s >testparm.smb
#===============================================================================

# Получение списка директорий (tree) /, если есть /.1, /.2 при отсутствии установка
#===============================================================================

which tree > /dev/null
REZULT=$?
for pointdir in 1 2 3 4 5 6 7 8
do
if [ $REZULT = 0 ]
then
	
	tree  -dlL 2 / > dir
	[ -d "/.$pointdir" ] && tree  -dl 2 /.$pointdir > dir$pointdir
else

	if [ "$DISTR" = "MANDRAKELINUX" ] || [ "$DISTR" = "MANDRIVA" ] || [ "$DISTR" = "ROSA" ] || [ "$DISTR" = "OS" ]
        then
		urpmi tree
		if [ $? = 0 ]
		then
			tree  -dlL 2 / > dir
			[ -d "/.$pointdir" ] && tree  -dlL 2 /.$pointdir > dir$pointdir
		else
			echo "- Не найден исполняемый файл tree - не настроен urpmi" | tee -a "$ADDLOG"
		fi
	else
		if [ "$DISTR" = "RED" ] || [ "$DISTR" = "CENTOS" ] || [ "$DISTR" = "ASTRA" ]
		then
			yum install -y tree
			if [ $? = 0 ]
			then
				tree  -dlL 2 / > dir
				[ -d "/.$pointdir" ] && tree  -dlL 2 /.$pointdir > dir$pointdir
			else
					echo "- Не найден исполняемый файл tree - не настроен yum" | tee -a "$ADDLOG"
			fi
		fi
	fi
fi
done
#===============================================================================

# Список оборудования (lspcidrake), если команды нет то установка lspcidrake
#===============================================================================
if [ "$DISTR" = "MANDRAKELINUX" ] || [ "$DISTR" = "MANDRIVA" ] || [ "$DISTR" = "ROSA" ]  || [ "$DISTR" = "OS" ]
	then
		which lspcidrake
		if [ $? = 0 ]
		then
			lspcidrake > lspci
		else
			echo "- Не найден исполняемый файл lspcidrake" | tee -a "$ADDLOG"
			urpmi lspcidrake
			lspcidrake > lspci
		fi
	else
		if [ "$DISTR" = "RED" ] || [ "$DISTR" = "CENTOS" ] || [ "$DISTR" = "ASTRA" ]
		then
			which lspci
			if [ $? = 0 ]
			then
				lspci > lspci
			else
				echo "- Не найден исполняемый файл lspci" | tee -a "$ADDLOG"
				yum install -y lspci
				lspci > lspci	
			fi
		fi
fi
for BIN_CHECK in $LIST_BIN
do
	which $BIN_CHECK
	if [ $? = 0 ]
	then
		BIN_PATH=`which $BIN_CHECK`
		echo $BIN_CHECK | grep -q cdrecord
		if [ $? = 0 ]
		then
			$BIN_PATH -scanbus > scsibus
			$BIN_PATH --version > $BIN_CHECK
			ls -la $BIN_PATH >> files.attr
		else
			$BIN_PATH -v > $BIN_CHECK
			LENGTH_FILE=`wc -c $BIN_CHECK | awk '{print $1}'`
			if [ $LENGTH_FILE = 0 ]
			then
				$BIN_PATH --version > $BIN_CHECK
				LENGTH_FILE=`wc -c $BIN_CHECK | awk '{print $1}'`
				if [ $LENGTH_FILE = 0 ]
				then
					$BIN_PATH --version 2> $BIN_CHECK;
				fi
			fi
			ls -la $BIN_PATH >> files.attr
		fi
	else
		echo "- Не найден исполняемый файл $BIN_CHECK" | tee -a "$ADDLOG"
	fi
done

# Список сервисов всех сервисов
#===============================================================================
chkconfig --list > chkconfig.list
#===============================================================================

# Список включенных сервисов
#===============================================================================
chkconfig --list | grep on > chkconfig.list_on
#===============================================================================

# Сбор правил iptables
#===============================================================================
grep -q iptables chkconfig.list_on
REZ=$?
if [ "$REZ" = 0 ]
then
    iptables -L -n > iptables.all
    iptables -L -n -t nat > iptables.nat
else
     echo "- Проверка сервиса iptables - не включен" | tee -a "$ADDLOG"
fi

# Сбор правил iptables Astra
#===============================================================================
    iptables -L -n > iptables.all
    iptables -L -n -t nat > iptables.nat

#===============================================================================

# Список фалов и директорий в / (root) 
#===============================================================================
ls -la / > ls
#===============================================================================

# Использование i-node
#===============================================================================
df -i > df_inode
#===============================================================================

# Сбор данных ИБП (nut)
#===============================================================================
UPSC=`which upsc`
if [ -n $UPSC ]
then
    grep -q upsd chkconfig.list_on
    REZ=$?
    if [ $REZ = 0 ]
    then
    for nutups in `$UPSC -l`
    do
	if [ -n $nutups ]
	then
	    $UPSC $nutups@localhost > $nutups
	else
	    echo "- Не найдены/не настроены ИБП в nut" | tee -a "$ADDLOG"
	fi
    done
else
    /etc/init.d/apcupsd status > $USERDIR/$HOSTNAME/apcupsd.txt
    echo "- Не найден исполняемый файл upsc " | tee -a $ADDLOG
    fi
    else
    echo "- Не найден запущенный процесс upsd" | tee -a $ADDLOG
fi

#===============================================================================


# Копирование файла config.sys
#===============================================================================

if [ -a /mnt/c/config.sys ]
then
    cp -p -v /mnt/c/config.sys $USERDIR/$HOSTNAME/
else
    echo "- Копирование файла /mnt/c/config.sys - нет файла" | tee -a "$ADDLOG"
fi
#===============================================================================

# Список файлов и директорий в /dev
#===============================================================================
ls -la /dev > ls_dev
#===============================================================================

# Копирование каталога /boot/grub и список файлов и директорий в /boot
#===============================================================================
mkdir -p $USERDIR/$HOSTNAME/boot/grub
cp -R -p -v /boot/grub/* $USERDIR/$HOSTNAME/boot/grub
ls -la /boot > /$USERDIR/$HOSTNAME/boot/lsboot
tree -lsfDN /boot > /$USERDIR/$HOSTNAME/boot/tree_boot

# Копирование каталога /boot/grub2 и список файлов и директорий в /boot
#===============================================================================
mkdir -p $USERDIR/$HOSTNAME/boot/grub2
cp -R -p -v /boot/grub2/grub.cfg $USERDIR/$HOSTNAME/boot/grub2
cp -R -p -v /boot/grub2/menu.lst $USERDIR/$HOSTNAME/boot/grub2
ls -la /boot > /$USERDIR/$HOSTNAME/boot/lsboot
tree -lsfDN /boot > /$USERDIR/$HOSTNAME/boot/tree_boot

#===============================================================================

# Копирование католога /etc
#===============================================================================
find /etc/ -xdev -path '/etc/selinux' -prune -o -path '/etc/locale' -prune -o -path '/etc/gconf' -prune -o -path '/etc/pki' -prune -o -path '/etc/branding-images-Cobalt' -prune -o -print | cpio -pdvm /$USERDIR/$HOSTNAME/

# Копирование католога /.1/rscan/conf
#===============================================================================
find /.1/rscan/conf/ -xdev | cpio -pdvm /$USERDIR/$HOSTNAME/

# Копирование настроек fvwm если есть каталог и не пустой
#===============================================================================

if [ -d /usr/share/fvwm/ ] && [ `ls /usr/share/fvwm/ | wc -l` != 0 ]
then
	mkdir -p $USERDIR/$HOSTNAME/usr/share/fvwm/
	cp -R -p -v /usr/share/fvwm/* $USERDIR/$HOSTNAME/usr/share/fvwm/
else
    echo "- Копирование каталога /usr/share/fvwm/ - нет каталога" | tee -a "$ADDLOG"
fi
#===============================================================================

#  Копирование настроек Icewm если есть каталог и не пустой
#===============================================================================
if [ -d /usr/share/X11/icewm ] && [ `ls /usr/share/X11/icewm/ | wc -l` != 0 ]
then
    find /usr/share/X11/icewm | grep -v "themes" | cpio -pvdm /$USERDIR/$HOSTNAME/
else
    echo "- Копирование каталога /usr/share/X11/icewm/ - нет каталога" | tee -a "$ADDLOG"
fi

#  Копирование настроек Icewm если есть каталог и не пустой
#===============================================================================

if [ -d /usr/share/icewm ] && [ `ls /usr/share/icewm/ | wc -l` != 0 ]
then
    find /usr/share/icewm | grep -v "themes" | cpio -pvdm /$USERDIR/$HOSTNAME/
else
    echo "- Копирование каталога /usr/share/icewm/ - нет каталога" | tee -a "$ADDLOG"
fi

#  Копирование настроек Icewm если есть каталог и не пустой
#===============================================================================

if [ -d /home/st/.icewm ] && [ `ls /home/st/.icewm/ | wc -l` != 0 ]
then
    find /home/st/.icewm | grep -v "themes" | cpio -pvdm /$USERDIR/$HOSTNAME/
else
    echo "- Копирование каталога /home/st/.icewm/ - нет каталога" | tee -a "$ADDLOG"
fi
#===============================================================================

# Вставка короткого HOSTNAME в /etc/HOSTNAME
#===============================================================================
echo $HOSTNAME > /$USERDIR/$HOSTNAME/etc/HOSTNAME
#===============================================================================

# Копирование каталогов /var/spool/cron, если есть и не пустой
#===============================================================================

if [ -d /var/spool/cron ] && [ `ls /var/spool/cron/ | wc -l` != 0 ]
then
    mkdir -p /$USERDIR/$HOSTNAME/var/spool
    cp -R -p -v /var/spool/cron /$USERDIR/$HOSTNAME/var/spool
else
    echo "- Копирование каталога /var/spool/cron - нет каталога или пуст" | tee -a "$ADDLOG"
fi
#===============================================================================

# Копирование каталогов /opt/papcm, если есть и не пустой
#===============================================================================

if [ -d /opt/papcm ] && [ `ls /opt/papcm | wc -l` != 0 ]
then
    mkdir -p /$USERDIR/$HOSTNAME/opt/papcm
    cp -R -p -v /opt/papcm/* /$USERDIR/$HOSTNAME/opt/papcm/
else
    echo "- Копирование каталога /opt/papcm - нет каталога или пуст" | tee -a "$ADDLOG"
fi
#===============================================================================

# Копирование каталогов /var/spool/papillon, если есть и не пустой
#===============================================================================

if [ -d /var/spool/papillon ] && [ `ls ls /var/spool/papillon/ | wc -l` != 0 ]
then
    mkdir -p /$USERDIR/$HOSTNAME/var/spool
    cp -p -v -R /var/spool/papillon /$USERDIR/$HOSTNAME/var/spool
else
    echo "- Копирование каталога /var/spool/papillon - нет каталога или пуст" | tee -a "$ADDLOG"
fi
#===============================================================================

# Копирование каталогов /var/named, если есть, установлен пакет bind и он не пустой
#===============================================================================

rpm -qa | grep -q bind
if [ $? = 0 ]
then
    if [ -d /var/named ] && [ `ls /var/named/ | wc -l` != 0 ]
    then
	mkdir /$USERDIR/$HOSTNAME/var/named
	find /var/named/ | grep -v "proc/" | cpio -pdvm /$USERDIR/$HOSTNAME/var/named
    else
	echo "- Копирование каталога /var/named - нет каталога или пустой" | tee -a "$ADDLOG"
    fi
else
    echo "- Не установлен пакет bind" | tee -a "$ADDLOG"
fi
#===============================================================================

# Копирование файла /usr/lib/diald/connect, если есть
#===============================================================================

if [ -f /usr/lib/diald/connect ]
then
    mkdir -p /$USERDIR/$HOSTNAME/usr/lib/diald
    cp -p -v /usr/lib/diald/connect /$USERDIR/$HOSTNAME/usr/lib/diald/
else
    echo "- Копирование файла /usr/lib/diald/connect - нет файла" | tee -a "$ADDLOG"
fi
#===============================================================================

# Копирование файла /usr/lib/uucp/taylor_config, если есть
#===============================================================================

if [ -f /usr/lib/uucp/taylor_config ]
then
    mkdir -p /$USERDIR/$HOSTNAME/usr/lib/uucp
    cp -p -v -R /usr/lib/uucp/taylor_config /$USERDIR/$HOSTNAME/usr/lib/uucp
else
    echo "- Копирование файла /usr/lib/uucp/taylor_config - нет файла" | tee -a "$ADDLOG"
fi
#===============================================================================

# Сбор информации о КриптоПРО, если есть каталог /var/opt/cprocsp и он не пустой
#===============================================================================
if [ -d /var/opt/cprocsp ] && [ `ls /var/opt/cprocsp/ | wc -l` != 0 ]
then
    mkdir /$USERDIR/$HOSTNAME/var/opt
    cp -p -v -R /var/opt/cprocsp /$USERDIR/$HOSTNAME/var/opt
else
    echo -e "- Копирование каталога /var/opt/cprocsp - нет каталога или пуст"  | tee -a "$ADDLOG"
fi
#===============================================================================

# Сбор информации из каталога /proc
#===============================================================================

echo -n Сбор информации из каталога /proc ... 2>&1
if [ -d /proc/mpt ]
then
# Kernel panic x3650 + IBM DS
    for files_path in `find /proc -path '/*/[0-9]*' -prune -o -print | grep -v kmsg | grep -v kcore | grep -v kpagecount | grep -v kpageflags | grep -v kallsyms | grep -v event | grep -v mpt | grep -v mpp`
    do
    cp --parents $files_path /$USERDIR/$HOSTNAME/
    done
else
    for files_path_i in `find /proc -path '/*/[0-9]*' -prune -o -print | grep -v kmsg | grep -v kcore | grep -v event | grep -v kpagecount | grep -v kpageflags | grep -v kallsyms`
    do
    cp --parents $files_path_i /$USERDIR/$HOSTNAME/
    done
fi    
#===============================================================================

# Определение значения $PPLN
#===============================================================================
for PPLNLIST in `echo $LISTPPLN`
do
	PPLN=$PPLNLIST
	if [ -d "$PPLN" ]
then

# Копирование файлов и каталогов из PPLN
#===============================================================================
if [ -n "$PPLN" ]
then
	mkdir /$USERDIR/$HOSTNAME/$PPLN
	mkdir -p -m 777 /$USERDIR/$HOSTNAME/$PPLN/conf/cfg
	/bin/chown -R st.afis /$USERDIR/$HOSTNAME/$PPLN/conf
	/bin/chmod 775 /$USERDIR/$HOSTNAME/$PPLN/conf
	mkdir /$USERDIR/$HOSTNAME/$PPLN/dict
	mkdir /$USERDIR/$HOSTNAME/home
	find /$PPLN/conf/ -type f -not -uid 1000 | grep -v "print" | grep -v "-" | grep -v ".tif" | grep -v ".bin" | cpio -pdvm /$USERDIR/$HOSTNAME
# Копирование файлов с владельцем admin
su - admin -c "find /$PPLN/conf/ -uid 1000 | cpio -pdvm /$USERDIR/$HOSTNAME/"

#===============================================================================

# Копирование каталога PPLN/dict
#===============================================================================
cp -p -R /$PPLN/dict/* /$USERDIR/$HOSTNAME/$PPLN/dict
#===============================================================================

# Копирование каталога PPLN/local если есть и в нем есть файлы
#===============================================================================
if [ -d /$PPLN/local ]
then
    COUNT_F=`find /$PPLN/local -type f | wc -l`
    if [ $COUNT_F -ge 1 ]
    then
	cp -p -R /$PPLN/local /$USERDIR/$HOSTNAME/$PPLN/
    else
	echo -e "- Каталог /$PPLN/local не содержит файлов"  | tee -a "$ADDLOG"
        
    fi
else
    echo -e "- Копирование каталога /$PPLN/local - нет каталога"  | tee -a "$ADDLOG"
fi
#===============================================================================

# Список файлов и директорий /PPLN в файл
#===============================================================================
ls -la /$PPLN/ > /$USERDIR/$HOSTNAME/$PPLN/lspap
#===============================================================================
fi

#===============================================================================

# Сбор версий программ из каталога /$PPLN/pilot
#=============================================================================== 
if [ -d /$PPLN/pilot ]
then
	mkdir /$USERDIR/$HOSTNAME/$PPLN/pilot
	cp -p  /$PPLN/pilot/Config* /$USERDIR/$HOSTNAME/$PPLN/pilot
	ls -la /$PPLN/pilot/ > /$USERDIR/$HOSTNAME/$PPLN/pilot/lspilot
for i in `ls -1 /$PPLN/pilot/ | grep -v pilotcc | sed 's/*//g'`
do
	file /$PPLN/pilot/$i 
	#| grep -q "ELF 32-bit LSB ex"
	if [ $? = 0 ]
	then
		/$PPLN/pilot/$i -v > /dev/null
		REZULT=$?

		if [ $REZULT = 0 ]
		then
			echo $i | grep -q "pilotd"
			if [ $? = 0 ]
			then
				su - st -c "/$PPLN/pilot/pilotd -v" > /$USERDIR/pilotd.v
				cat /$USERDIR/pilotd.v > /$USERDIR/$HOSTNAME/$PPLN/pilot/$i.version
				rm /$USERDIR/pilotd.v
				md5sum /$PPLN/pilot/$i >> /$USERDIR/$HOSTNAME/$PPLN/pilot/PILOT.md5sum
			else
				/$PPLN/pilot/$i -v > /$USERDIR/$HOSTNAME/$PPLN/pilot/$i.version
				md5sum /$PPLN/pilot/$i >> /$USERDIR/$HOSTNAME/$PPLN/pilot/PILOT.md5sum
			fi
		else
		if [ $REZULT = 1 ]
		then
			echo $i | grep -q "pilotd"
			if [ $? = 0 ]
			then
				su - st -c "/$PPLN/pilot/pilotd -v" > /$USERDIR/pilotd.v
				cat /$USERDIR/pilotd.v > /$USERDIR/$HOSTNAME/$PPLN/pilot/$i.version
				rm /$USERDIR/pilotd.v
				md5sum /$PPLN/pilot/$i >> /$USERDIR/$HOSTNAME/$PPLN/pilot/PILOT.md5sum
			fi
		fi

		fi
	fi
done

# Сбор версий программ из каталога /$PPLN/pilot/bin
#===============================================================================
[ -d /$PPLN/pilot/bin ]
if [ $? = 0 ]
then
	mkdir -p /$USERDIR/$HOSTNAME/$PPLN/pilot/bin
	ls -la /$PPLN/pilot/bin > /$USERDIR/$HOSTNAME/$PPLN/pilot/lsd_bin
	for i in `ls -1 /$PPLN/pilot/bin | sed 's/*//g'`
	do
		file /$PPLN/pilot/bin/$i 
		#| grep -q "ELF 32-bit LSB ex"
		if [ $? = 0 ]
		then
			/$PPLN/pilot/bin/$i > /$USERDIR/$HOSTNAME/$PPLN/pilot/bin/$i.version
			md5sum /$PPLN/pilot/bin/$i >> /$USERDIR/$HOSTNAME/$PPLN/pilot/bin/PILOT_BIN.md5sum
		fi
	done
	echo -e "Закончен каталог $PPLN/pilot/bin"
else
	echo -e "- Сбор версий исполняемых файлов из /$PPLN/pilot/bin - нет каталога" | tee -a "$ADDLOG"
fi
#=============================================================================== 

else
	echo -e "- Копирование каталога $PPLN/pilot - нет каталога" | tee -a "$ADDLOG"
fi
#=============================================================================== 
# Окончание цикла "Определение переменной PPLN" 
fi
done

# Сбор версий программ из каталога /.1/rscan/bin
#===============================================================================
if [ -d /.1/rscan ]
    then
mkdir -p /$USERDIR/$HOSTNAME/.1/rscan/bin
/.1/rscan/bin/flowscan7 -v > /$USERDIR/$HOSTNAME/.1/rscan/bin/flowscan7.version
/.1/rscan/bin/p7pkgsend -v > /$USERDIR/$HOSTNAME/.1/rscan/bin/p7pkgsend.version
/.1/rscan/bin/p7pkgsort -v > /$USERDIR/$HOSTNAME/.1/rscan/bin/p7pkgsort.version
/.1/rscan/bin/p7prcp -v > /$USERDIR/$HOSTNAME/.1/rscan/bin/p7prcp.version
/.1/rscan/bin/p7pscan -v > /$USERDIR/$HOSTNAME/.1/rscan/bin/p7pscan.version
/.1/rscan/bin/p7pwsq -v > /$USERDIR/$HOSTNAME/.1/rscan/bin/p7pwsq.version
/.1/rscan/bin/p7rcp -v > /$USERDIR/$HOSTNAME/.1/rscan/bin/p7rcp.version
/.1/rscan/bin/p7wsq -v > /$USERDIR/$HOSTNAME/.1/rscan/bin/p7wsq.version
/.1/rscan/bin/rev2src -v > /$USERDIR/$HOSTNAME/.1/rscan/bin/rev2src.version
/.1/rscan/bin/xpscan -v > /$USERDIR/$HOSTNAME/.1/rscan/bin/xpscan.version
    else
    echo -e "- Сбор версий исполняемых файлов из /.1/rscan/bin - нет каталога" | tee -a "$ADDLOG"
fi

#export LC_ALL=ru_RU.UTF-8
#[ -d /.1/rscan/bin ]
#if [ $? = 0 ]
#then
#	mkdir -p /$USERDIR/$HOSTNAME/.1/rscan/bin
#	ls -la /.1/rscan/bin > /$USERDIR/$HOSTNAME/.1/rscan/lsd_bin
#	for i in `ls -1 /.1/rscan/bin | grep -v ccd | grep -v adf | sed 's/*//g'`
#	for i in `ls -1 /.1/rscan/bin | grep -v ccd | grep -v adf`
#	do
#		file /.1/rscan/bin/$i | grep -q "ELF 32-bit LSB ex"
#		if [ $? = 0 ]
#		then
#			/.1/rscan/bin/$i -v > /$USERDIR/$HOSTNAME/.1/rscan/bin/$i.version
##			md5sum /.1/rscan/bin/$i >> /$USERDIR/$HOSTNAME/.1/rscan/bin/PILOT_BIN.md5sum
#		fi
#	done
#	echo -e "Закончен каталог /.1/rscan/bin"
#else
#	echo -e "- Сбор версий исполняемых файлов из /.1/rscan/bin - нет каталога" | tee -a "$ADDLOG"
#fi

# Копирование файла /home/st/.rhosts если есть такой файл
#===============================================================================
if [ -z /home/st/.rhosts ]
then
	cp -p /home/st/.rhosts /$USERDIR/$HOSTNAME/
	echo -e "Копирование /home/st/.rhosts"
else
	echo -e "- Копирование /home/st/.rhosts - нет файла"  | tee -a "$ADDLOG" 
fi
#===============================================================================

# Копирование каталога /home/st/.ssh если есть и не пустой
#===============================================================================
ls -l /home/st/.ssh/ | grep -q "dsa\|rsa\|authorized"
if [ $? = 0 ]
then
    mkdir -p /$USERDIR/$HOSTNAME/home/st/.ssh
    cp -p -v -R /home/st/.ssh /$USERDIR/$HOSTNAME/home/st/.ssh/
else
    echo "- Каталог /home/st/.ssh не содержит ключей или отсутствует" | tee -a "$ADDLOG"
fi
#===============================================================================

# Копирование каталога /root/.ssh если есть и не пустой
#===============================================================================
ls -l /root/.ssh/ | grep -q "dsa\|rsa\|authorized"
if [ $? = 0 ]
then
    mkdir -p /$USERDIR/$HOSTNAME/root/.ssh
    cp -p -v -R /root/.ssh /$USERDIR/$HOSTNAME/root/.ssh/
else
    echo "- Каталог /root/.ssh не содержит ключей или отсутствует" | tee -a "$ADDLOG"
fi
#===============================================================================

# Сбор версий программ из каталога /home/p7bin и /home/p8bin
#===============================================================================
for PPLNBIN in `echo $LISTBIN_P`
do
[ -d $PPLNBIN ]
if [ $? = 0 ]
then
	PPLNBIN_N=`echo $(basename $PPLNBIN) | tr [a-z] [A-Z]`
	mkdir -p $USERDIR/$HOSTNAME/$PPLNBIN
	ls -la $PPLNBIN/ > /$USERDIR/$HOSTNAME/home/lsbin.$PPLNBIN_N
fi
	for i in `find $PPLNBIN/ -maxdepth 1 -type f | grep -v cntstat |grep -v dtp | grep -v asil | grep -v CHANGES | grep -v test | grep -v kino | grep -v glue | grep -v grb | grep -v phcamera | grep -v fm`
	do
	i=$(basename $i)
	file $PPLNBIN/$i
	# | grep -q "ELF 32-bit LSB ex"
		if [ $? = 0 ]
		then
		$PPLNBIN/$i -v > /dev/null
		REZULT=$?
			if [ $REZULT = 0 ]
			then
				echo $i
				script -qc "$PPLNBIN/$i -v;sleep 1" /$USERDIR/$HOSTNAME/$PPLNBIN/$i.version > /dev/null
				md5sum $PPLNBIN/$i >> /$USERDIR/$HOSTNAME/$PPLNBIN/$PPLNBIN_N.md5sum
				TEST_FILE=`cat /$USERDIR/$HOSTNAME/$PPLNBIN/$i.version | wc -l`
					if [ "$TEST_FILE" -le "2" ]
					then
						echo $i | grep -q lsd
						if [ $? = 0 ]
						then
						    script -qc "/$PPLNBIN/$i -v;sleep 1" /$USERDIR/$HOSTNAME/$PPLNBIN/$i.version > /dev/null
						else
						    script -qc "/$PPLNBIN/$i;sleep 1" /$USERDIR/$HOSTNAME/$PPLNBIN/$i.version > /dev/null
						fi
					fi
			else
					if [ $REZULT -ge 1 ]
					then
						echo $i | grep -q view_c7
						if [ $? = 0 ]
						then
							echo $i
							su - st -c "/$PPLNBIN/view_c7 -v" > /$USERDIR/view_c7.v
							cat /$USERDIR/view_c7.v > /$USERDIR/$HOSTNAME/$PPLNBIN/view_c7.version
							rm /$USERDIR/view_c7.v
							md5sum /$PPLNBIN/$i >> /$USERDIR/$HOSTNAME/$PPLNBIN/$PPLNBIN_N.md5sum
					else
							echo $i
							script -qc "/$PPLNBIN/$i -v;sleep 1" /$USERDIR/$HOSTNAME/$PPLNBIN/$i.version > /dev/null
							md5sum /$PPLNBIN/$i >> /$USERDIR/$HOSTNAME/$PPLNBIN/$PPLNBIN_N.md5sum
							grep -q "version\|Ver." /$USERDIR/$HOSTNAME/$PPLNBIN/$i.version
							if [ $? != 0 ]
							then
								TEST_FILE=`cat /$USERDIR/$HOSTNAME/$PPLNBIN/$i.version | wc -l`
								if [ "$TEST_FILE" -le "2" ]
								then
								    script -qc "/$PPLNBIN/$i;sleep 1" /$USERDIR/$HOSTNAME/$PPLNBIN/$i.version > /dev/null
								fi
							fi
						fi
					fi
			fi
		fi	
	done
done


# Удаление core файлов из /$USERDIR/$HOSTNAME/$PPLNBIN если есть
#===============================================================================
[ -f /$USERDIR/$HOSTNAME/$PPLNBIN/core* ] && rm /$USERDIR/$HOSTNAME/$PPLNBIN/core*
#===============================================================================


#===============================================================================

# Сбор версий программ из каталогов /home/p7tools, /home/p8tools
#===============================================================================
for PPLNTOOLS in `echo $LISTTOOLS_P`
do
[ -d $PPLNTOOLS ]
if [ $? = 0 ]
then
	PPLNTOOLS_N=`echo $(basename $PPLNTOOLS) | tr [a-z] [A-Z]`
	mkdir -p /$USERDIR/$HOSTNAME/$PPLNTOOLS
	ls -la $PPLNTOOLS/ > /$USERDIR/$HOSTNAME/home/lstools.$PPLNTOOLS_N
#	/$PPLNTOOLS/sane-find-scanner > /$USERDIR/$HOSTNAME/sane-find-scanner
#	if [ -s /$USERDIR/$HOSTNAME/sane-find-scanner ]
#	then
#	    echo "OK"
#	else
#	    echo "- Файл /$USERDIR/$HOSTNAME/sane-find-scanner нулевого размера - удален" | tee -a "$ADDLOG"
#	    rm /$USERDIR/$HOSTNAME/sane-find-scanner
#	fi
#	$PPLNTOOLS/scanimage -L > /$USERDIR/$HOSTNAME/scanimage
#	if [ -s /$USERDIR/$HOSTNAME/scanimage ]
#	then
#	    echo "OK"
#	else
#	    echo "- Файл /$USERDIR/$HOSTNAME/scanimage нулевого размера - удален" | tee -a "$ADDLOG"
#	    rm /$USERDIR/$HOSTNAME/scanimage
#	fi
	for i in `ls -1 /$PPLNTOOLS | grep -v CHANGES | grep -v translit`
	do
	file $PPLNTOOLS/$i 
	#| grep -q "ELF 32-bit LSB ex"
		if [ $? = 0 ]
		then
		if [ "$PPLNTOOLS/$i" = "$PPLNTOOLS/scanimage" ]
		then
			$PPLNTOOLS/$i -V > /dev/null
			export REZULT=$?
		else
			$PPLNTOOLS/$i -v > /dev/null
			export REZULT=$?
		fi

		if [ $REZULT = 0 ]
		then
			echo $i | grep -q scanimage
		        if [ $? = 0 ]
			then
			$PPLNTOOLS/$i -V >/$USERDIR/$HOSTNAME/$PPLNTOOLS/$i.version
			md5sum $PPLNTOOLS/$i >> /$USERDIR/$HOSTNAME/$PPLNTOOLS/$PPLNTOOLS_N.md5sum
		else
			$PPLNTOOLS/$i -v >/$USERDIR/$HOSTNAME/$PPLNTOOLS/$i.version
			md5sum $PPLNTOOLS/$i >> /$USERDIR/$HOSTNAME/$PPLNTOOLS/$PPLNTOOLS_N.md5sum
			TEST_FILE=`cat /$USERDIR/$HOSTNAME/$PPLNTOOLS/$i.version`
			if [ -z $TEST_FILE ]
			then
				$PPLNTOOLS/$i -v 2>/$USERDIR/$HOSTNAME/$PPLNTOOLS/$i.version
			fi
			if [ $REZULT = 1 ]
			then
				if [ -s /$USERDIR/$HOSTNAME/$PPLNTOOLS/$i.version ]
				then
				$PPLNTOOLS/$i -v 2>/$USERDIR/$HOSTNAME/$PPLNTOOLS/$i.version
				md5sum $PPLNTOOLS/$i >> /$USERDIR/$HOSTNAME/$PPLNTOOLS/$PPLNTOOLS_N.md5sum
			fi
		fi
	fi
fi
fi

	done
else
	echo -e "- Сбор версий исполняемых файлов из $PPLNTOOLS - нет каталога" | tee -a "$ADDLOG"
fi
echo -e "Закончен каталог $PPLNTOOLS"
done
#===============================================================================

# Сбор информации о планшетных сканерах (2015.05.13 Глухов В.)
#===============================================================================
for S_FIND in `which sane-find-scanner`
do
    if [ -z $S_FIND ]
    then
	echo -e "- Сбор информации планшетных сканерах - нет файла sane-find-scanner" | tee -a "$ADDLOG"
    else
        if [ -f /$USERDIR/$HOSTNAME/sane-find-scanner ]
	then
	    $S_FIND >> /$USERDIR/$HOSTNAME/sane-find-scanner
	else
	    $S_FIND > /$USERDIR/$HOSTNAME/sane-find-scanner
	fi
    fi
done

# Сбор информации о планшетных сканерах (2017.03.22 Шабакин)
#===============================================================================
for S_FIND in `which scanimage`
do
    if [ -z $S_FIND ]
    then
	echo -e "- Сбор информации планшетных сканерах - нет файла scanimage" | tee -a "$ADDLOG"
    else
        if [ -f /$USERDIR/$HOSTNAME/scanimage ]
	then
	    $S_FIND -L >> /$USERDIR/$HOSTNAME/scanimage
	else
	    $S_FIND -L > /$USERDIR/$HOSTNAME/scanimage
	fi
    fi
done

#===============================================================================

# Сбор версий программ из каталога /home/lscan/bin 32-bit
#===============================================================================
export LD_LIBRARY_PATH=/home/lscan/lib
for LSCANBIN in `echo $LISTBIN_L` `$LISTTOOLS_L`
do
if [ -d $LSCANBIN ] && [ `ls $LSCANBIN/ | wc -l` != 0 ]
then
	mkdir -p /$USERDIR/$HOSTNAME/$LSCANBIN
#	su - st -c "export LD_LIBRARY_PATH=/home/lscan/lib; script -qc '/home/lscan/bin/l_scan -v' >> /var/tmp/$HOSTNAME/home/lscan/bin/l_scan64bit.version"
#	su - st -c "export LD_LIBRARY_PATH=/home/lscan/lib; script -qc '/home/lscan/bin/l_scan -v' >> /var/tmp/$HOSTNAME/home/lscan/bin/l_scan.version"
	LSCANBIN_N=`echo $(basename $LSCANBIN) | tr [a-z] [A-Z]`
	ls -la $LSCANBIN/ >> /$USERDIR/$HOSTNAME/home/lsbin.$LSCANBIN_N
	for i in `ls -1 $LSCANBIN | grep -v CHANGES | grep -v test | grep -v kino | grep -v glue | grep -v grb`
#	for i in `ls -1 $LSCANBIN | grep -v CHANGES | grep -v kino | grep -v glue | grep -v grb`
	do
		file $LSCANBIN/$i | grep -q "ELF 32-bit LSB ex"
#		file $LSCANBIN/$i | grep -q "ELF 64-bit LSB ex"
		if [ $? = 0 ]
		then
			$LSCANBIN/$i -v > /dev/null
			REZULT=$?
			echo $i - 0
		if [ $REZULT = 0 ]
		then
			echo $i | grep -q l_scan
			REZULT_L=$?
				if [ "$REZULT_L" = "0" ]
				then
					echo $i - 1
					touch /$USERDIR/$HOSTNAME/$LSCANBIN/$i.version
					chown st.afis /$USERDIR/$HOSTNAME/$LSCANBIN/$i.version
					su - st -c "script -qc '$LSCANBIN/$i -v;sleep 3' /$USERDIR/$HOSTNAME/home/$LSCANBIN/$i.version"

					md5sum $LSCANBIN/$i >> /$USERDIR/$HOSTNAME/$LSCANBIN/$LSCANBIN_N.md5
#					su - st -c "export LD_LIBRARY_PATH=/home/lscan/lib; script -qc '/home/lscan/bin/l_scan -v' >> /var/tmp/$HOSTNAME/home/lscan/bin/l_scan.version"
				else
					echo $i - 2
					$LSCANBIN/$i -v > /$USERDIR/$HOSTNAME/$LSCANBIN/$i.version
					md5sum $LSCANBIN/$i >> /$USERDIR/$HOSTNAME/$LSCANBIN/$LSCANBIN_N.md5
					TEST_FILE=`cat /$USERDIR/$HOSTNAME/$LSCANBIN/$i.version`
					if [ -z "$TEST_FILE" ]
					then
						script -qc "$LSCANBIN/$i -v;sleep 1" /$USERDIR/$HOSTNAME/$LSCANBIN/$i.version
					fi
					if [ $REZULT != 0 ]
					then
						echo $i - 3
						$LSCANBIN/$i -v 2&> /$USERDIR/$HOSTNAME/$LSCANBIN/$i.version
						md5sum $LSCANBIN/$i >> /$USERDIR/$HOSTNAME/$LSCANBIN/$LSCANBIN_N.md5
					fi
				fi
			else	
				echo $i - 7
				touch /$USERDIR/$HOSTNAME/$LSCANBIN/$i.version
				chown st.afis /$USERDIR/$HOSTNAME/$LSCANBIN/$i.version
				su - st -c "script -qc '$LSCANBIN/$i -v;sleep 3' /$USERDIR/$HOSTNAME/$LSCANBIN/$i.version"
				md5sum $LSCANBIN/$i >> /$USERDIR/$HOSTNAME/$LSCANBIN/$LSCANBIN_N.md5
			fi
		fi
	done
else
	echo "- Сбор версий исполняемых файлов из $LSCANBIN - нет каталога или пуст" | tee -a "$ADDLOG"
fi
unset $LD_LIBRARY_PATH
done
#===============================================================================

#===============================================================================

# Сбор версий программ из каталога /home/lscan/bin 64-bit
#===============================================================================
export LD_LIBRARY_PATH=/home/lscan/lib
for LSCANBIN in `echo $LISTBIN_L` `$LISTTOOLS_L`
do
if [ -d $LSCANBIN ] && [ `ls $LSCANBIN/ | wc -l` != 0 ]
then
	mkdir -p /$USERDIR/$HOSTNAME/$LSCANBIN
#	su - st -c "export LD_LIBRARY_PATH=/home/lscan/lib; script -qc '/home/lscan/bin/l_scan -v' >> /var/tmp/$HOSTNAME/home/lscan/bin/l_scan64bit.version"
#	su - st -c "export LD_LIBRARY_PATH=/home/lscan/lib; script -qc '/home/lscan/bin/l_scan -v' >> /var/tmp/$HOSTNAME/home/lscan/bin/l_scan.version"
	LSCANBIN_N=`echo $(basename $LSCANBIN) | tr [a-z] [A-Z]`
	ls -la $LSCANBIN/ >> /$USERDIR/$HOSTNAME/home/lsbin.$LSCANBIN_N
	for i in `ls -1 $LSCANBIN | grep -v CHANGES | grep -v test | grep -v kino | grep -v glue | grep -v grb`
#	for i in `ls -1 $LSCANBIN | grep -v CHANGES | grep -v kino | grep -v glue | grep -v grb`
	do
#		file $LSCANBIN/$i | grep -q "ELF 32-bit LSB ex"
		file $LSCANBIN/$i | grep -q "ELF 64-bit LSB ex"
		if [ $? = 0 ]
		then
			$LSCANBIN/$i -v > /dev/null
			REZULT=$?
			echo $i - 0
		if [ $REZULT = 0 ]
		then
			echo $i | grep -q l_scan
			REZULT_L=$?
				if [ "$REZULT_L" = "0" ]
				then
					echo $i - 1
					touch /$USERDIR/$HOSTNAME/$LSCANBIN/$i.version
					chown st.afis /$USERDIR/$HOSTNAME/$LSCANBIN/$i.version
					su - st -c "script -qc '$LSCANBIN/$i -v;sleep 3' /$USERDIR/$HOSTNAME/home/$LSCANBIN/$i.version"

					md5sum $LSCANBIN/$i >> /$USERDIR/$HOSTNAME/$LSCANBIN/$LSCANBIN_N.md5
#					su - st -c "export LD_LIBRARY_PATH=/home/lscan/lib; script -qc '/home/lscan/bin/l_scan -v' >> /var/tmp/$HOSTNAME/home/lscan/bin/l_scan.version"
				else
					echo $i - 2
					$LSCANBIN/$i -v > /$USERDIR/$HOSTNAME/$LSCANBIN/$i.version
					md5sum $LSCANBIN/$i >> /$USERDIR/$HOSTNAME/$LSCANBIN/$LSCANBIN_N.md5
					TEST_FILE=`cat /$USERDIR/$HOSTNAME/$LSCANBIN/$i.version`
					if [ -z "$TEST_FILE" ]
					then
						script -qc "$LSCANBIN/$i -v;sleep 1" /$USERDIR/$HOSTNAME/$LSCANBIN/$i.version
					fi
					if [ $REZULT != 0 ]
					then
						echo $i - 3
						$LSCANBIN/$i -v 2&> /$USERDIR/$HOSTNAME/$LSCANBIN/$i.version
						md5sum $LSCANBIN/$i >> /$USERDIR/$HOSTNAME/$LSCANBIN/$LSCANBIN_N.md5
					fi
				fi
			else	
				echo $i - 7
				touch /$USERDIR/$HOSTNAME/$LSCANBIN/$i.version
				chown st.afis /$USERDIR/$HOSTNAME/$LSCANBIN/$i.version
				su - st -c "script -qc '$LSCANBIN/$i -v;sleep 3' /$USERDIR/$HOSTNAME/$LSCANBIN/$i.version"
				md5sum $LSCANBIN/$i >> /$USERDIR/$HOSTNAME/$LSCANBIN/$LSCANBIN_N.md5
			fi
		fi
	done
else
	echo "- Сбор версий исполняемых файлов из $LSCANBIN - нет каталога или пуст" | tee -a "$ADDLOG"
fi
unset $LD_LIBRARY_PATH
done
#===============================================================================


# ARSENAL
#===============================================================================

# Проверка наличия пользоватедя ars с gid=1001
#===============================================================================

id arsenal | grep -q "gid=1001"
REZ=$?
if [ $REZ = 0 ]
then
ARS_CONFIG=`grep -r "ARSENAL=/" /etc/sysconfig/ | head -n 1 | awk -F ":" '{ print $1 }' | sort | uniq`
. $ARS_CONFIG
export LD_LIBRARY_PATH=$LIBDIR:$LD_LIBRARY_PATH

# Сбор версий программ из каталога ARSENAL
#===============================================================================
if [ -d $ARSENAL ] && [ `ls /$ARSENAL/ | wc -l` != 0 ]
then
	mkdir -p /$USERDIR/$HOSTNAME/$BINDIR
	mkdir -p /$USERDIR/$HOSTNAME/$ARSENAL/protocol
	mkdir -p /$USERDIR/$HOSTNAME/$ARSENAL/conf
	mkdir -p /$USERDIR/$HOSTNAME/$ARSENAL/cfg
	mkdir -p /$USERDIR/$HOSTNAME/$ARSENAL/wrk0
	mkdir -p /$USERDIR/$HOSTNAME/$ARSENAL/wrk1
	mkdir -p /$USERDIR/$HOSTNAME/$ARSENAL/wrk2
	mkdir -p /$USERDIR/$HOSTNAME/$ARSENAL/tmp
	# Для Арсенала
	chmod -R 777 /$USERDIR/$HOSTNAME/$ARSENAL/
	chown -R ars.arsenal /$USERDIR/$HOSTNAME/$ARSENAL/
	rsync -lavr /$ARSENAL/protocol/*.pr /$USERDIR/$HOSTNAME/$ARSENAL/protocol
	rsync -lavr /$ARSENAL/protocol/*.pr~ /$USERDIR/$HOSTNAME/$ARSENAL/protocol
	rsync -lavr /$ARSENAL/protocol/*.log /$USERDIR/$HOSTNAME/$ARSENAL/protocol
	rsync -lavr /$ARSENAL/protocol/*.err /$USERDIR/$HOSTNAME/$ARSENAL/protocol
	rsync -lavr /$ARSENAL/conf /$USERDIR/$HOSTNAME/$ARSENAL/
	rsync -lavr /$ARSENAL/cfg /$USERDIR/$HOSTNAME/$ARSENAL/
	ls -la /$BINDIR/ >> /$USERDIR/$HOSTNAME/$ARSENAL/ls_bin
	ls -la /$ARSENAL/ >> /$USERDIR/$HOSTNAME/$ARSENAL/ls_ars
	ls -la /$ARSENAL/wrk0 >> /$USERDIR/$HOSTNAME/$ARSENAL/wrk0/ls_wrk0
	ls -la /$ARSENAL/wrk1 >> /$USERDIR/$HOSTNAME/$ARSENAL/wrk1/ls_wrk1
	ls -la /$ARSENAL/wrk2 >> /$USERDIR/$HOSTNAME/$ARSENAL/wrk2/ls_wrk2
	ls -la /$ARSENAL/tmp >> /$USERDIR/$HOSTNAME/$ARSENAL/tmp/ls_tmp
	tree -lfsDN /$ARSENAL/ >> /$USERDIR/$HOSTNAME/$ARSENAL/tree_ars
	tree -lfsDN /$ARSENAL/wrk2 >> /$USERDIR/$HOSTNAME/$ARSENAL/wrk2/tree_wrk2
	# Для firebird
	if [ -d /opt/firebird ] && [ `ls /opt/firebird/ | wc -l` != 0 ]
	then
	    FB_DIR=/opt/firebird
	    mkdir -p /$USERDIR/$HOSTNAME/$FB_DIR
	    tree -l /$FB_DIR/ >> /$USERDIR/$HOSTNAME/$FB_DIR/tree_opt_firebird
	    # Версия FIREBIRD
	    /$FB_DIR/bin/fb_config --version >> /$USERDIR/$HOSTNAME/$FB_DIR/FIREBIRD.ver
	    rsync -lavr /$FB_DIR/*.conf /$USERDIR/$HOSTNAME/$FB_DIR/
	    rsync -lavr /$FB_DIR/*.log  /$USERDIR/$HOSTNAME/$FB_DIR/
	    rsync -lavr /$FB_DIR/SYSDBA.password /$USERDIR/$HOSTNAME/$FB_DIR/
	else
	    echo "- Проверка наличия каталога $FB_DIR - нет каталога или пуст" | tee -a "$ADDLOG"
	fi
	# Проверка соединений SQL сервера по локальному и сетевому интерфейсу
	#Узнать пароль пользователя SYSDBA (только от root):
	CONNECT_PASSWD_SYS=`grep ISC_PASSWD /$FB_DIR/SYSDBA.password | cut -f 2 -d '='`
	#Узнать пароль пользователя SYSDBA:
	A_CONNECT_NAME=`cat $ARSENAL/conf/arsenal.ini | grep "LocalName" | grep -v "^;" | cut -f 2 -d '='`
	L=`grep -n $A_CONNECT_NAME $ARSENAL/conf/dbconnect.ini | cut -f 1 -d ':'`
	NL=`cat $ARSENAL/conf/dbconnect.ini | wc -l`
	TL=`echo $NL-$L | bc -l`
	CONNECT_PASSWD=`tail -n $TL $ARSENAL/conf/dbconnect.ini | grep "^User_Passwd=" | head -1 | cut -f 2 -d '='`
	CONNECT_NAME=`tail -n $TL $ARSENAL/conf/dbconnect.ini | grep "^Name=" | head -1 | cut -f 2 -d '='`
	FILE_Q=/var/tmp/quit.sql
	echo -e "quit;\n" > $FILE_Q
	# echo $A_CONNECT_NAME $L $TL $CONNECT_PASSWD $CONNECT_NAME $CONNECT_PASSWD_SYS
	if [ -f /opt/firebird/bin/isql ]
	then
	    DB_CON=/opt/firebird/bin/isql
	    if [ -f /$CONNECT_NAME ]
	    then
	    	$DB_CON -u sysdba -p $CONNECT_PASSWD $CONNECT_NAME -i $FILE_Q 2> /$USERDIR/$HOSTNAME/$ARSENAL/check_con_err
	    	# Удаление файла check_con_err если размер 0
	    	FILE_SIZE=`cat /$USERDIR/$HOSTNAME/$ARSENAL/check_con_err | wc -L`
	    	if [ $FILE_SIZE = 0 ]
	    	then
	    	    rm /$USERDIR/$HOSTNAME/$ARSENAL/check_con_err
		    echo "- Удаление файла /$USERDIR/$HOSTNAME/$ARSENAL/check_con_err - размер файла 0" | tee -a "$ADDLOG"
		fi
	    	$DB_CON -u sysdba -p $CONNECT_PASSWD localhost:$CONNECT_NAME -i $FILE_Q 2> /$USERDIR/$HOSTNAME/$ARSENAL/check_con_l_err
	    	# Удаление файла check_con_l_err если размер 0
	    	FILE_SIZE=`cat /$USERDIR/$HOSTNAME/$ARSENAL/check_con_l_err | wc -L`
	    	if [ $FILE_SIZE = 0 ]
	    	then
	    	    rm /$USERDIR/$HOSTNAME/$ARSENAL/check_con_l_err
		    echo "- Удаление файла /$USERDIR/$HOSTNAME/$ARSENAL/check_con_l_err - размер файла 0" | tee -a "$ADDLOG"
		fi
	    	# Удаление файла quit.sql после выполнения запросов
	    	rm $FILE_Q
	    else
	    	echo "- Проверка наличия файла /$CONNECT_NAME - нет файла" | tee -a "$ADDLOG"
	    fi
	else
	echo "- Проверка налиичя файла $DB_CON - нет файла" | tee -a "$ADDLOG"
	fi
	for i in `ls -1 /$BINDIR | grep -v CHANGES | grep -v kino | grep -v "pv"`
	do
		file /$BINDIR/$i 
		#| grep -q "ELF 32-bit LSB ex"
		if [ $? = 0 ]
		then
			/$BINDIR/$i -v > /dev/null
			REZULT=$?

		if [ $REZULT = 0 ]
		then
			echo $i
			su - ars -c "script -qc '/$BINDIR/$i -v;sleep 1' /$USERDIR/$HOSTNAME/$BINDIR/$i.version"
			md5sum /$BINDIR/$i >> /$USERDIR/$HOSTNAME/$BINDIR/ARSENAL.md5
#			TEST_FILE=`cat /$USERDIR/$HOSTNAME/$BINDIR/$i.version`
#				if [ -z "$TEST_FILE" ]
#				then
#					su - ars -c "script -qc '/$BINDIR/$i -v;sleep 1' /$USERDIR/$HOSTNAME/$BINDIR/$i.version"
#				fi
					if [ $REZULT != 0 ]
					then
						echo $i
						su - ars -c "script -qc '/$BINDIR/$i -v;sleep 1' /$USERDIR/$HOSTNAME/$BINDIR/$i.version"
						md5sum /$BINDIR/$i >> /$USERDIR/$HOSTNAME/$BINDIR/ARSENAL.md5
					fi
				fi	
			fi
	done
else
	echo "- Сбор версий исполняемых файлов из $ARSENAL - нет каталога или пуст" | tee -a "$ADDLOG"
fi
fi
# Для сбора данных о пропускных системах (GWI)
#===============================================================================

if [ -d /var/db/ibdata ]
then
	# для сервера
	mkdir -p /$USERDIR/$HOSTNAME/GWI/SERVER
	ls -lh /var/db/ibdata >> /$USERDIR/$HOSTNAME/GWI/SERVER/ls_db.txt
	# Проверяю наличие каталога /var/www/html
	if [ -d /var/www/html ]
	then
	mkdir -p /$USERDIR/$HOSTNAME/var/www/html/GWI
	ls -lh /var/www/html/ >> /$USERDIR/$HOSTNAME/GWI/SERVER/ls_html.txt
	ls -lh /var/www/html/GWI >> /$USERDIR/$HOSTNAME/GWI/SERVER/ls_htmlGWI.txt
	rsync -lavr /var/www/html/* /$USERDIR/$HOSTNAME/var/www/html/
	else
		echo "- Копирование каталога /var/www/html - нет каталога" | tee -a "$ADDLOG"
	fi
	# для клиента
	if [ -d /root/ibrep ]
	then
		mkdir -p /$USERDIR/$HOSTNAME/root/ibrep
		ls -lh /root/ibrep >> /$USERDIR/$HOSTNAME/root/ibrep/ls_ibrep.txt
		rsync -lavr /root/ibrep/* /$USERDIR/$HOSTNAME/root/ibrep/
	else
		echo "- Копирование каталога /root/ibrep - нет каталога" | tee -a "$ADDLOG"
	fi
	else
		echo "- Копирование каталога /var/db/ibdata - нет каталога" | tee -a "$ADDLOG"
fi
#===============================================================================

# Для сбора данных о видеосистемах (VOCH)
#===============================================================================
if [ -d $VOCH ]
then
    mkdir -p /$USERDIR/$HOSTNAME/$VOCH/bin
    mkdir -p /$USERDIR/$HOSTNAME/$VOCH/lib
    mkdir -p /$USERDIR/$HOSTNAME/usr/local/Trolltech
    ls -lah /$VOCH >> /$USERDIR/$HOSTNAME/$VOCH/voch.txt
    tree -lfsDN /$VOCH >> /$USERDIR/$HOSTNAME/$VOCH/voch.txt
    tree -lfsDN /usr/local/Trolltech >> /$USERDIR/$HOSTNAME/usr/local/Trolltech/trolltech.txt
    tree -lfsDN /$VOCH > /$USERDIR/$HOSTNAME/$VOCH/dir_tree
    ls -la /$VOCH/bin/ > /$USERDIR/$HOSTNAME/$VOCH/bin/ls_bin.txt
    ls -la /$VOCH/lib > /$USERDIR/$HOSTNAME/$VOCH/lib/ls_lib.txt
    # получение версии файла videoserver (Д. Лазуков)
    `su - apache &`
     export LD_LIBRARY_PATH=/usr/local/Trolltech/Qt-4.7.1/lib:/usr/local/voch/lib:$LD_LIBRARY_PATH     2>/dev/null
     cd /$VOCH/bin    2>/dev/null
    ./videoserver -v > /$USERDIR/$HOSTNAME/usr/local/voch/bin/videosever.ver   2>/dev/null
    logout;

    if [ -d /var/www/html ]
    then
	if [ -d /$USERDIR/$HOSTNAME/var/www/ ]
	then
	    echo "- Создание каталога /$USERDIR/$HOSTNAME/var/www/html - уже создан" | tee -a "$ADDLOG"
	else
	    mkdir -p /$USERDIR/$HOSTNAME/var/www/
	fi
	# Копируем все из /var/www/html за исключением каталогов video с содержимым
	rsync -lavr --exclude 'web_export/video/' --exclude 'web_export/pics' --exclude 'old/' --exclude 'web_play/video/' --exclude 'Vss/img_rez/'  /var/www/html /$USERDIR/$HOSTNAME/var/www/
    else
	echo "- Копирование каталога /var/www/html - нет каталога" | tee -a "$ADDLOG"
    fi
    # Список каталогов для копирования
    for DIRNAME_VOCH in bin conf log sql
    do
    if [ -d /$VOCH/$DIRNAME_VOCH ]
    then
	rsync -lavr /$VOCH/$DIRNAME_VOCH /$USERDIR/$HOSTNAME/$VOCH/
    else
	echo "- Копирование каталога /usr/local/voch/$DIRNAME_VOCH - нет каталога" | tee -a "$ADDLOG"
    fi
    done
else
    echo "- Копирование каталога $VOCH - нет каталога" | tee -a "$ADDLOG"
fi

# Удаление core.* файлов
#===============================================================================
for corefile in `find /$USERDIR/$HOSTNAME -type f -name "core.*"`
do
	rm $corefile
done
#===============================================================================

# Сбор информации об оборудовании (lshw) проверкой
#===============================================================================
#which lshw > /dev/null
#if [ $? = 0 ]
#then
#	lshw > /$USERDIR/$HOSTNAME/lshw.txt
#else
#	if [ "$DISTR" = "Mandrakelinux" ] || [ "$DISTR" = "Mandriva" ] || [ "$DISTR" = "ROSA" ] || [ "$DISTR" = "OS" ]
#	then
#		urpmi lshw
#		if [ $? = 0 ]
#		then
#			lshw > /$USERDIR/$HOSTNAME/lshw.txt
#		else
#			echo "- Не настроен urpmi или не установлен lshw" | tee -a "$ADDLOG"
#		fi
#	else
#		if [ "$DISTR" = "Red" ] || [ "$DISTR" = "CENTOS" ]
#		then
#			yum install -y lshw
#			if [ $? = 0 ]
#			then
#				lshw > /$USERDIR/$HOSTNAME/lshw.txt
#			else
#				echo "Не настроен yum или не установлен lshw" | tee -a "$ADDLOG"
#			fi
#		fi
#	fi
#fi
# Сбор информации об оборудовании (lshw) проверкой Astra
#===============================================================================
#which lshw > /dev/null
#if [ $? = 0 ]
#then
#	lshw > /$USERDIR/$HOSTNAME/lshw.txt
#else
#	if [ "$DISTR" = "ASTRA" ]
#	then
#		aptitude install lshw
#		if [ $? = 0 ]
#		then
#			lshw > /$USERDIR/$HOSTNAME/lshw.txt
#		else
#			echo "- Не настроен apt-get или не установлен lshw" | tee -a "$ADDLOG"
#		fi
#fi

hardinfo -r > /$USERDIR/$HOSTNAME/hardinfo.txt
hwinfo > /$USERDIR/$HOSTNAME/hwinfo.txt


which lsusb > /dev/null
lsusb -v > /$USERDIR/$HOSTNAME/lsusb.txt
chown st.afis /var/tmp/$HOSTNAME/home/lscan/bin
#/home/lscan/bin/ds45utest -v > /var/tmp/$HOSTNAME/home/lscan/bin/ds45utest.version
su - st -c "export LD_LIBRARY_PATH=/home/lscan/lib; script -qc '/home/lscan/bin/l_scan -v' >> /var/tmp/$HOSTNAME/home/lscan/bin/l_scan.version"
su - st -c "export LD_LIBRARY_PATH=/home/lscan/lib; script -qc '/home/lscan/bin/ds45utest -v' >> /var/tmp/$HOSTNAME/home/lscan/bin/ds45utest.version"
su - st -c "export LD_LIBRARY_PATH=/home/lscan/lib; script -qc '/home/lscan/bin/x7cvrf -v' >> /var/tmp/$HOSTNAME/home/lscan/bin/x7cvrf.version"
su - st -c "export LD_LIBRARY_PATH=/home/lscan/lib; script -qc '/home/lscan/bin/ds30ntest -v' >> /var/tmp/$HOSTNAME/home/lscan/bin/ds30ntest.version"
#===============================================================================

# Конвертируем в UTF-8 протоколов
#===============================================================================
for FILES in $USERCONFLOG $USERCONFVER
do
if [ -f /$USERDIR/$HOSTNAME/$FILES ]
then
    iconv -f koi8-r -t utf8 /$USERDIR/$HOSTNAME/$FILES > /$USERDIR/$HOSTNAME/$FILES.utf8
else
    echo "- Нет файла /$USERDIR/$HOSTNAME/$FILES" | tee -a "$ADDLOG"
fi
done
#===============================================================================


# Время окончания сбора userconf
#===============================================================================

date >>  /$USERDIR/$HOSTNAME/$USERCONFVER >> /$USERDIR/$HOSTNAME/$USERCONFVER.utf8
#===============================================================================

# Переходим в /var/tmp для заворачивания каталога в архив
#===============================================================================
cd  /$USERDIR
#===============================================================================

# Создание архива конфигурации
#===============================================================================
tar cjf $HOSTNAME.$DATEFILE.tar.bz2 $HOSTNAME
if [ $? = 0 ]
then
	if [ $LANG_MESSAGE = 0 ]
	then
		echo -e "==================================================="
		echo -e " Создан архив конфигурации $HOSTNAME.$DATEFILE.tgz "
		echo -e "==================================================="
	else
		echo -e "======================================================"
		echo -e " Created configuration file $HOSTNAME.$DATEFILE.tgz "
		echo -e "======================================================"
	fi 
	# Удаляем сжатый каталог
	rm -fr /$USERDIR/$HOSTNAME
else
	if [ $LANG_MESSAGE = 0 ]
	then
		echo -e "========================================================="
		echo -e " Создание архива конфигурации завершилось не корректно "
		echo -e "========================================================="
	else
		echo -e "============================================================"
		echo -e " Creating a configuration file is not completed correctly "
		echo -e "============================================================"
	fi
fi
#===============================================================================
