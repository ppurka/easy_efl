#!/usr/bin/env bash

#############################################################################
# This script is a result of the ideas from the people of different e       #
# channels at irc.freenode.net                                              #
# It will checkout the repository and compile efl and enlightenment.        #
#                                                                           #
# License: BSD licence                                                      #
# Get the latest version at http://omicron.homeip.net/projects/             #
# Coded by Brian 'morlenxus' Miculcy (morlenxus@gmx.net)                    #
#                                                                           #
version="1.6.2"                                                             #
version_mark="dev"                                                          #
#############################################################################


############# STOP ####################################### STOP #############
#                                                                           #
# INTERNAL VARIABLES, RUN EASY_EFL.SH --HELP TO GET A CLEANER WAY!          #
# YOU CAN ADD YOUR OWN SOURCES USING --custompackage !                      #
#                                                                           #
############# STOP ####################################### STOP #############

# Package Sources
git_baseurl="http://git.enlightenment.org/"
svn_baseurl="http://svn.enlightenment.org/svn/e/trunk"

git_branch="origin/master"

# Packages
declare -a base_libs
base_libs+=("efl|git|$git_baseurl/core/efl.git|$git_branch")
base_libs+=("evas_generic_loaders|git|$git_baseurl/core/evas_generic_loaders.git|$git_branch")
base_libs+=("elementary|git|$git_baseurl/core/elementary.git|$git_branch")
declare -a base_apps
base_apps+=("enlightenment|git|$git_baseurl/core/enlightenment.git|$git_branch")
base_apps+=("entrance|git|$git_baseurl/misc/entrance.git|$git_branch")
base_apps+=("eruler|git|$git_baseurl/apps/eruler.git|$git_branch")
base_apps+=("terminology|git|$git_baseurl/apps/terminology.git|$git_branch")
declare -a base_modules
base_modules+=("alarm|git|$git_baseurl/enlightenment/modules/alarm.git|$git_branch")
base_modules+=("cpu|git|$git_baseurl/enlightenment/modules/cpu.git|$git_branch")
base_modules+=("diskio|git|$git_baseurl/enlightenment/modules/diskio.git|$git_branch")
base_modules+=("forecasts|git|$git_baseurl/enlightenment/modules/forecasts.git|$git_branch")
base_modules+=("mail|git|$git_baseurl/enlightenment/modules/mail.git|$git_branch")
base_modules+=("moon|git|$git_baseurl/enlightenment/modules/moon.git|$git_branch")
base_modules+=("mpdule|git|$git_baseurl/enlightenment/modules/mpdule.git|$git_branch")
base_modules+=("net|git|$git_baseurl/enlightenment/modules/net.git|$git_branch")
base_modules+=("news|git|$git_baseurl/enlightenment/modules/news.git|$git_branch")
base_modules+=("penguins|git|$git_baseurl/enlightenment/modules/penguins.git|$git_branch")
base_modules+=("places|git|$git_baseurl/enlightenment/modules/places.git|$git_branch")
base_modules+=("tclock|git|$git_baseurl/enlightenment/modules/tclock.git|$git_branch")
declare -a extra_apps
extra_apps+=("enventor|git|$git_baseurl/tools/enventor.git|$git_branch")
declare -a extra_games
extra_games+=("etrophy|git|$git_baseurl/games/etrophy.git|$git_branch")
extra_games+=("elemines|git|$git_baseurl/games/elemines.git|$git_branch")
declare -a custom_packages
# see --custompackage


# Prepare Packages List
for package in ${base_libs[*]}
{	package_name=`echo "$package" | cut -d'|' -f1`
	base_libs_list="$base_libs_list $package_name"
}
for package in ${base_apps[*]}
{	package_name=`echo "$package" | cut -d'|' -f1`
	base_apps_list="$base_apps_list $package_name"
}
for package in ${base_modules[*]}
{	package_name=`echo "$package" | cut -d'|' -f1`
	base_modules_list="$base_modules_list $package_name"
}
for package in ${extra_apps[*]}
{	package_name=`echo "$package" | cut -d'|' -f1`
	extra_games_list="$extra_apps_list $package_name"
}
for package in ${extra_games[*]}
{	package_name=`echo "$package" | cut -d'|' -f1`
	extra_games_list="$extra_games_list $package_name"
}

# Basic Dependencies
deps_bin="automake byacc|yacc g++ gcc git libtool pkg-config svn"
deps_dev="dbus-1 fontconfig freetype GL jpeg lua|lua5.1 png rsvg-2 udev xml2 X11 Xext Xrandr xcb"



#############################################################################
# SCRIPT DEFAULTS, RUN EASY_EFL.SH --HELP TO GET A CLEANER WAY!             #
#############################################################################
tmp_path="/tmp/easy_efl"
tmp_compile_dir="$tmp_path/compile"
tmp_install_dir="$tmp_path/install"
logs_path="$tmp_path/install_logs"
status_path="$tmp_path/status"
build_path="$tmp_path/build"
src_path="$HOME/efl_src"
conf_files="/etc/easy_efl.conf $HOME/.config/easy_efl/easy_efl.conf $HOME/.easy_efl.conf $PWD/.easy_efl.conf"
autogen_args=""		# evas:--enable-gl-x11
linux_distri=""		# if your distribution is wrongly detected, define it here
nice_level=0		# nice level (19 == low, -20 == high)
os=$(uname)			# operating system
username=`whoami`
threads=2			# make -j <threads>

EASY_PWD=`pwd`
accache=""
easy_options=""
command_options=$@
clean=0
mkdir -p "$HOME/.config/easy_efl" || {
    echo >&2 "ERROR: Can not create config directory $HOME/.config/easy_efl"
    exit 1
}

animation="star"
online_source="http://omicron.homeip.net/projects/easy_efl/dev/easy_efl.sh"


#############################################################################
# FUNCTIONS                                                                 #
#############################################################################
function package_find ()
{
	name=$1

	found=0
	for package in ${base_libs[*]} ${base_apps[*]} ${base_modules[*]} ${extra_apps[*]} ${extra_games[*]} ${custom_packages[*]}
	{
		package_name=`echo "$package" | cut -d'|' -f1`
		if [ "$package_name" = "$name" ]; then
			found=1
			echo "$package"
		fi

		if [ $found -eq 1 ]; then return; fi
	}
}

#############################################################################
function logo ()
{
	clear
	if [ "$version_mark" ]; then
		echo -e "\033[1m-------------------------------\033[7m Easy_EFL.sh $version-$version_mark \033[0m\033[1m--------------------------\033[0m"
	else
		echo -e "\033[1m-------------------------------\033[7m Easy_EFL.sh $version \033[0m\033[1m------------------------------\033[0m"
	fi
	echo -e "\033[1m  Updates:\033[0m         http://omicron.homeip.net/projects/"
	echo -e "\033[1m  Support:\033[0m         #e.de (irc.freenode.net)"
	echo -e "                   morlenxus@gmx.net (Brian 'morlenxus' Miculcy)"
	echo -e "\033[1m  Patches:\033[0m         Generally accepted, please contact me!"
	echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
	echo
	echo -e "\033[1m-----------------------------\033[7m Current Configuration \033[0m\033[1m----------------------------\033[0m"
	echo "  Install path:    $install_path"
	echo "  Logs path:       $logs_path"
	if [ "$linux_distri" ]; then
		echo "  OS:              $os (Distribution: $linux_distri)"
	else
		echo "  OS:              $os"
	fi
	if [ "$skip" ]; then echo "  Skipping:        $skip"; fi
	if [ "$only" ]; then echo "  Only:            $only"; fi
	if [ -z "$action" ]; then action="MISSING!"; fi
	echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
	echo
	
	if [ "$action" == "script" ]; then return; fi	

	if [ $1 == 0 ]; then
		if [ "$2" ]; then
			echo -e "\033[1m-------------------------------\033[7m Bad script argument \033[0m\033[1m----------------------------\033[0m"
			echo -e "  \033[1m$2\033[0m"
		fi
	else
		echo -e "\033[1m--------------------------------\033[7m Build phase $1/3 \033[0m\033[1m-------------------------------\033[0m"
	fi

	if [ -z "$2" ]; then
		case $1 in
			0)
				if [ "$os" == "not supported" ]; then
					echo -e "\033[1m-------------------------------\033[7m Not supported OS \033[0m\033[1m------------------------------\033[0m"
				  	echo "  Your operating system '$os' is not supported by this script."
					echo "  If possible please provide a patch."
				else if [ -z "$fullhelp" ]; then
					echo -e "\033[1m-----------------\033[7m Short help 'easy_efl.sh <ACTION> <OPTIONS...>' \033[0m\033[1m---------------\033[0m"
					echo "  -i, --install                         = install efl+enlightenment"
					echo "  -u, --update                          = update your installed software"
					echo
					echo "      --packagelist=<list>              = software package list:"
					echo "                           - basic      (efl+enlightenment+custom)"
					echo "                           - full       (efl+enlightenment+e-modules+apps+custom)"
					echo "                           - custom     (custompackages)"
					echo
					echo "      --help                            = full help, many more options"
				else
					echo -e "\033[1m-----------------\033[7m Full help 'easy_efl.sh <ACTION> <OPTIONS...>' \033[0m\033[1m----------------\033[0m"
					echo -e "  \033[1mACTION (ONLY SELECT ONE):\033[0m"
					echo "  -i, --install                         = install efl+enlightenment"
					echo "  -u, --update                          = update installed software"
					echo "      --only=<name1>,<name2>,...        = install ONLY named libs/apps"
					echo "      --srcupdate                       = update only the sources"
					echo "  -v, --check-script-version            = check for a newer release of easy_efl"
					echo "      --help                            = this help"
					echo
					echo -e "  \033[1mPACKAGELIST:\033[0m"
					echo "      --packagelist=<list>              = software package list:"
					echo "                           - basic        (efl+enlightenment+custom)"
					echo "                           - full         (efl+enlightenment+e-modules+apps+custom)"
					echo "                           - custom       (custompackages)"
					echo "      --custompackage=<n>:<g/s>,<u>,<b> = add custom package:"
					echo "                                          <name>:<git/svn>,<url>,<branch>"
					echo
					echo -e "  \033[1mOPTIONS:\033[0m"
					echo "      --conf=<file>                     = use an alternate configuration file path"
					echo "      --instpath=<path>                 = change the default install path"
					echo "      --srcpath=<path>                  = change the default source path"
					echo "      --asuser                          = do everything as the user, not as root"
					echo "      --no-sudopwd                      = sudo don't need a password..."
					echo "  -c, --clean                           = clean the sources before building"
					echo "                                          (more --cleans means more cleaning, up"
					echo "                                          to a maximum of three, which will"
					echo "                                          uninstall efl+enlightenment)"
					echo "  -s, --skip-srcupdate                  = don't update sources"
					echo "  -a, --ask-on-src-conflicts            = ask what to do with a conflicting"
					echo "                                          source file"
					echo "      --skip=<name1>,<name2>,...        = this will skip installing the named"
					echo "                                          libs/apps"
					echo "  -d, --docs                            = generate programmers documentation"
					echo "      --postscript=<name>               = full path to a script to run as root"
					echo "                                          after installation"
					echo "  -e, --skip-errors                     = continue compiling even if there is"
					echo "                                          an error"
					echo "  -w, --wait                            = don't exit the script after finishing,"
					echo "                                          this allows 'xterm -e ./easy_efl.sh -i'"
					echo "                                          without closing the xterm"
					echo "      --anim=<animation>                = build animation:"
					echo "                                          - star: rotating star (default)"
					echo "                                          - weeh: waving man"
					echo "  -n  --disable-notification            = disable the osd notification"
					echo "  -k, --keep                            = keep all log files (default: error logs)"
					echo
					echo "  -l, --low                             = use lowest nice level (19, slowest,"
					echo "                                          takes more time to compile, select"
					echo "                                          this if you need to work on the pc"
					echo "                                          while compiling)"
					echo "      --normal                          = default nice level ($nice_level),"
					echo "                                          will be automatically used"
					echo "  -h, --high                            = use highest nice level (-20, fastest,"
					echo "                                          slows down the pc)"
					echo "      --cache                           = Use a common configure cache and"
					echo "                                          ccache if available"
					echo "      --threads=<int>                   = 'make' can use threads, recommended on"
					echo "                                          smp systems (default: 2 threads)"
					echo "      --autogen_args=<n1>:<o1>+<o2>     = pass some options to autogen:"
					echo "                                          <name1>:<opt1>+<opt2>,<name2>:<opt1>+..."
					echo "      --cflags=<flag1>,<flag2>,...      = pass cflags to the gcc"
					echo "      --ldflags=<flag1>,<flag2>,...     = pass ldflags to the gcc"
					echo "      --pkg_config_path=<path1>,...     = pass pkg-config path"
					echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
					echo
					echo -e "\033[1m----------------------\033[7m Configurationfile '~/.easy_efl.conf' \033[0m\033[1m--------------------\033[0m"
					echo "  Just create this file and save your favourite arguments."
					echo "  Example: If you use a diffent source path, add this line:"
					echo "           --srcpath=$HOME/enlightenment/efl_src"
				fi fi
				;;
			1)
				echo "- running some basic system checks"
				echo "- source checkout/update"
				;;
			2)
				echo "- lib-compilation and installation"
				echo "- apps-compilation and installation"
				;;
			3)
				echo "- cleaning"
				echo "- install notes"
				;;
		esac
	fi
	echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
	echo
	echo
}

#############################################################################
function define_os_vars ()
{
	case $os in
		Darwin)
			install_path="/opt/efl"
			# FIXME: Someone with Darwin seeing this should check availability:
			# ldconfig="/sbin/ldconfig"
			make="make"
			export ACLOCAL_FLAGS="$ACLOCAL_FLAGS -I /opt/local/share/aclocal"
			export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/local/lib/pkgconfig"
			export CPPFLAGS="$CPPFLAGS -I/opt/local/include"
			export LDFLAGS="$LDFLAGS -Wl,-L/opt/local/lib"
			;;
		FreeBSD)
			install_path="/usr/local/efl"
			ldconfig="/sbin/ldconfig"
			make="gmake"
			export ACLOCAL_FLAGS=" -I /usr/local/share/aclocal"
			export CPPFLAGS="$CPPFLAGS -I/usr/local/include -I/usr/X11R6/include -I$install_path/include"
			# FIXME: Someone with FreeBSD seeing this should check if includes are needed here:
			export CFLAGS="$CFLAGS -lintl -liconv -L/usr/local/lib -L/usr/X11R6/lib -L$install_path/lib -I/usr/local/include -I/usr/X11R6/include -I$install_path/include"
			export LDFLAGS="$LDFLAGS -lexecinfo"
			;;
		NetBSD)
			install_path="/usr/pkg/efl"
			ldconfig="config"
			make="make"
			export CFLAGS="$CFLAGS -I/usr/pkg/include -I/usr/X11R7/include"
			export CPPFLAGS="$CPPFLAGS -I/usr/pkg/include -I/usr/X11R7/include"
			export LDFLAGS="$LDFLAGS -L/usr/pkg/include -L/usr/pkg/lib -L/usr/X11R7/lib"
			;;

		Linux)
			install_path="/opt/efl"
			ldconfig="/sbin/ldconfig"
			make="make"
			export CFLAGS="$CFLAGS -fvisibility=hidden"

			if [ -z "$linux_distri" ]; then
				if [ -e "/etc/debian_version" ]; then linux_distri="debian"; fi
				if [ -e "/etc/gentoo-release" ]; then linux_distri="gentoo"; fi
				if [ -e "/etc/redhat-release" ]; then linux_distri="redhat"; fi
				if [ -e "/etc/SuSE-release" ];   then linux_distri="suse";	 fi
			fi
			;;
		SunOS)
			install_path="/opt/efl"
			ldconfig="$(which crle) -u"	# there is no command like ldconfig on solaris! "crle" does nearly the same.
			make="make"
			;;
		*)
			os="not supported"
			logo 0
			set_title
			exit 0
			;;
	esac
}

#############################################################################
function run_command ()
{
	name=$1
	path=$2
	title=$3
	log_title=$4
	mode_needed=$5
	cmd=$6

	set_title "$name: $title ($pkg_pos/$pkg_total)"
	echo -n "$log_title"
	logfile_banner "$cmd" "$logs_path/$name.log"

	if [ $mode_needed == "rootonly" ]; then
		mode_needed=$mode
	else
		if [ $nice_level -ge 0 ]; then
			mode_needed="user"
		fi
	fi
	rm -f $status_path/$name.noerrors
	case "$mode_needed" in
		"sudo")
			echo "$sudopwd" | sudo -S PKG_CONFIG_PATH="$PKG_CONFIG_PATH" PYTHONPATH="$PYTHONPATH" \
					 		  nice -n $nice_level $cmd >> "$logs_path/$name.log" 2>&1 && touch $status_path/$name.noerrors &
			;;
		*)
			nice -n $nice_level $cmd >> "$logs_path/$name.log" 2>&1 && touch $status_path/$name.noerrors &
			;;
	esac	

	pid="$!"
	rotate "$pid" "$name"
}

#############################################################################
function write_name ()
{
	name=$1
	hidden=$2
	cnt=${#name}
	max=27

	if [ "$hidden" ]; then
		c=-3
		while [ ! $c = $cnt ]; do
			echo -n " "
			c=$(($c+1))
		done
	else
		echo -n "- $name "
	fi

	while [ ! $cnt = $max ]; do
		echo -n "."
		cnt=$(($cnt+1))
	done
	echo -n " "
}

#############################################################################
function compile ()
{
	name=$1
	path="$src_path/$name"
	local curr_dir="$PWD"
	local installed_files="$HOME/.config/easy_efl/${name}.installed"

	write_name "$name"
	
	for one in $skip; do
		if [ "$name" == "$one" ]; then
			echo "SKIPPED"
			touch $status_path/$name.skipped
			return
		fi
	done
	if [ "$only" ] || [ "$action" == "update" ]; then
		found=0
		for one in $only; do
			if [ "$name" == "$one" ]; then found=1; fi
		done
		if [ $found -eq 0 ]; then
			echo "SKIPPED"
			touch $status_path/$name.skipped
			return
		else
			rm -rf $status_path/$name.skipped
		fi
	fi

	pkg_pos=$(($pkg_pos+1))

	if [ -e "$status_path/$name.installed" ]; then
		echo "previously installed"
		return
	fi
	if [ ! -d "$path" ]; then
		echo "SOURCEDIR NOT FOUND"
		set_notification "critical" "Package '$name': sourcedir not found."
		return
	fi

	# Copy source files to tmp_compile_dir and change to that directory
	cp -Rp "$path" "$tmp_compile_dir"
	path="$tmp_compile_dir/$name"
	cd "$path"

	rm -f "$status_path/$name.noerrors"
	rm -f "$logs_path/$name.log"

	if [ $clean -ge 1 ]; then
		if [ -e "Makefile" ]; then
			if [ $clean -eq 1 ]; then
				run_command "$name" "$path" "clean" "clean  : " "$mode" "$make -j $threads clean"
				if [ ! -e "$status_path/$name.noerrors" ]; then
					if [ "$skip_errors" ]; then
						write_name "$name" "hidden"	# clean might fail, that's ok
					else
						return
					fi
				fi
			fi
			if [ $clean -eq 2 ]; then
				run_command "$name" "$path" "distclean" "distcln: " "$mode" "$make -j $threads clean distclean"
				if [ ! -e "$status_path/$name.noerrors" ]; then
					if [ "$skip_errors" ]; then
						write_name "$name" "hidden"	# distclean might fail, that's ok
					else
						return
					fi
				fi
			fi
			if [ $clean -ge 3 ]; then
				run_command "$name" "$path" "uninstall" "uninst : " "rootonly" "$make -j $threads uninstall clean distclean"
				if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi

			    # It's no longer installed if we just uninstalled it.
			    # Even if the uninstall failed, it's best to mark it as uninstalled so that a partial uninstall gets fixed later.
			    rm -f $status_path/$name.installed
			fi
		fi
	fi

	# get autogen arguments
	args=""
	for app_arg in `echo $autogen_args | tr -s '\,' ' '`; do
		app=`echo $app_arg | cut -d':' -f1`
		if [ "$app" == "$name" ]; then
			args="$args `echo $app_arg | cut -d':' -f2- | tr -s '+' ' '`"
		fi
	done
	
	if [ -e "autogen.sh" ]; then
		run_command "$name" "$path" "autogen" "autogen: " "$mode"    "./autogen.sh --prefix=$install_path $accache $args"
		if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
		run_command "$name" "$path" "make"    "make:    " "$mode"    "$make -j $threads"
		if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
		run_command "$name" "$path" "install" "install: " "rootonly" "$make DESTDIR=$tmp_install_dir install"
		if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
	elif [ -e "bootstrap" ]; then
		run_command "$name" "$path" "bootstrap" "bootstr: " "$mode"    "./bootstrap"
		if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
		run_command "$name" "$path" "configure" "config:  " "$mode"    "./configure --prefix=$install_path $accache $args"
		if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
		run_command "$name" "$path" "make"      "make:    " "$mode"    "$make -j $threads"
		if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
		run_command "$name" "$path" "install"   "install: " "rootonly" "$make DESTDIR=$tmp_install_dir install"
		if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
	elif [ -e "Makefile.PL" ]; then
		run_command "$name" "$path" "perl"    "perl:    " "$mode"    "perl Makefile.PL prefix=$install_path $args"
		if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
		run_command "$name" "$path" "make"    "make:    " "$mode"    "$make -j $threads"
		if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
		run_command "$name" "$path" "install" "install: " "rootonly" "$make DESTDIR=$tmp_install_dir install"
		if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
	elif [ -e "setup.py" ]; then
		run_command "$name" "$path" "python"   "python:  " "$mode"    "python setup.py build build_ext --include-dirs=$PYTHONINCLUDE $args"
		if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
		run_command "$name" "$path" "install"  "install: " "rootonly" "python setup.py install --root=$tmp_install_dir --prefix=$install_path install_headers --install-dir=$PYTHONINCLUDE"
		if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
	elif [ -e "Makefile" ]; then
		make_extra="PREFIX=$install_path"
		run_command "$name" "$path" "make"    "make:    " "$mode"    "$make $make_extra -j $threads"
		if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
		run_command "$name" "$path" "install" "install: " "rootonly" "$make $make_extra DESTDIR=$tmp_install_dir install"
		if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
	elif [ -e "build.sh" ]; then
		run_command "$name" "$path" "build" "build:     " "$mode"    "./build.sh -i"
		if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
	else
		echo "no build system"
		set_notification "critical" "Package '$name': no build system."
		touch $status_path/$name.nobuild
		return
	fi

	# Now remove the files that were installed previously
	[ -e "$installed_files" ] && {
		cat "$installed_files" | xargs rm -f
	}
	# Now move the files in $tmp_install_dir to $install_path
	run_command "$name" "$path" "install" "cp:     " "rootonly"  "cp -Rpf ${tmp_install_dir}${install_path}/* ${install_path}"
	if [ ! -e "$status_path/$name.noerrors" ] ; then
		rm -rf "${tmp_install_dir}/${install_path}"
		return
	fi
	# Now update the file which records the installed files
	find "$tmp_install_dir" -type f -o -type l -o -type s -o -type p | sed -e "s@^${tmp_install_dir}@@" > "$installed_files"
	
	if [ "$gen_docs" ]; then
		if [ -e "gendoc" ]; then
			run_command "$name" "$path" "docs" "docs   : " "$mode" "sh gendoc"
			if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
		fi
	fi

	# All done, mark it as installed OK.
	touch $status_path/$name.installed
	rm -f $status_path/$name.noerrors
	echo "ok"
	set_notification "normal" "Package '$name': build successful."
	rm -rf "${tmp_install_dir}/${install_path}"
	rm -rf "${tmp_compile_dir}/${name}"
	cd "$curr_dir"
}

#############################################################################
function rotate ()
{
	pid=$1
	name=$2
	animation_state=1
	log_line=""
	
	case $animation in
		"weeh") echo -n "     " ;;
		*)		echo -n "   " ;;
	esac
	while [ "`ps -p $pid -o comm=`" ]; do
		last_line=`tail -1 "$logs_path/$name.log"`
		if [ ! "$log_line" = "$last_line" ]; then
			case $animation in
				"weeh")
					# waving man
					echo -e -n "\b\b\b\b\b"
					case $animation_state in
						1)
							echo -n "["
							echo -n -e "\033[1m"
							echo -n "\\o\\"
							echo -n -e "\033[0m"
							echo -n "]"
							animation_state=2
							;;
						2)
							echo -n "["
							echo -n -e "\033[1m|o|\033[0m"
							echo -n "]"
							animation_state=3
							;;
						3)
							echo -n "["
							echo -n -e "\033[1m/o/\033[0m"
							echo -n "]"
							animation_state=4
							;;
						4)
							echo -n "["
							echo -n -e "\033[1m|o|\033[0m"
							echo -n "]"
							animation_state=5
							;;
						5)
							echo -n "["
							echo -n -e "\033[1m"
							echo -n "\\o/"
							echo -n -e "\033[0m"
							echo -n "]"
							animation_state=6
							;;
						6)
							echo -n "["
							echo -n -e "\033[1m|o|\033[0m"
							echo -n "]"
							animation_state=1
							;;

					esac
					;;
				*)
					# rotating star
					echo -e -n "\b\b\b"
					case $animation_state in
						1)
							echo -n "["
							echo -n -e "\033[1m|\033[0m"
							echo -n "]"
							animation_state=2
							;;
						2)
							echo -n "["
							echo -n -e "\033[1m/\033[0m"
							echo -n "]"
							animation_state=3
							;;
						3)
							echo -n "["
							echo -n -e "\033[1m-\033[0m"
							echo -n "]"
							animation_state=4
							;;
						4)
							echo -n "["
							echo -n -e "\033[1m"
							echo -n "\\"
							echo -n -e "\033[0m"
							echo -n "]"
							animation_state=1
							;;
					esac
					;;
				esac
			log_line=$last_line
		fi
		sleep 1
	done

	if [ -e "$status_path/$name.noerrors" ]; then
		case $animation in
			"weeh")	del_lines 14 ;;
			*)		del_lines 12 ;;
		esac
	else
		case $animation in
			"weeh")	del_lines 5 ;;
			*)		del_lines 3 ;;
		esac

		echo -e "\033[1mERROR!\033[0m"
		set_notification "critical" "Package '$name': build failed."

		if [ ! "$skip_errors" ]; then
        	set_title "$name: ERROR"
			echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
			echo
			echo -e "\033[1m-----------------------------------\033[7m Last loglines \033[0m\033[1m------------------------------\033[0m"
			echo -n -e "\033[1m"
			tail -25 "$logs_path/$name.log"
			echo -n -e "\033[0m"
			echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
			echo
			echo "-> Get more informations by checking the log file '$logs_path/$name.log'!"
			echo

			# exit script or wait?
			if [ "$wait" ]; then
				echo
				echo -e -n "\033[1mThe script is waiting here - simply press [enter] to exit.\033[0m"
				read
			fi	

			set_title
			exit 2
		fi
	fi
}

#############################################################################
function del_lines ()
{
	cnt=0
	max=$1
	while [ ! "$cnt" == "$max" ]; do
		echo -n -e "\b \b"
		cnt=$(($cnt+1))
	done
}

#############################################################################
function error ()
{
	echo -e "\n\n\033[1mERROR: $1\033[0m\n\n"
    set_title "ERROR: $1"
	set_notification "critical" "Error: $1."

	# exit script or wait?
	if [ "$wait" ]; then
		echo
		echo -e -n "\033[1mThe script is waiting here - simply press [enter] to exit.\033[0m"
		read
	fi	

	exit 2
}

#############################################################################
function set_title ()
{
	if [ "$1" ]; then message="- $1"; fi

	if [ "$DISPLAY" ]; then
	    case "$TERM" in
			xterm*|rxvt*|Eterm|eterm|Aterm|aterm)
	        	echo -ne "\033]0;Easy_EFL.sh $message\007"
				;;
	    esac
	fi	
}

#############################################################################
function set_notification ()
{
	urgency=$1
	text=$2

	if [ -z "$DISPLAY" ] || [ "$notification_disabled" ]; then return; fi

	notifier="$install_path/bin/e-notify-send"
	if [ ! -e "$notifier" ]; then
		notifier="`which e-notify-send`"
	fi
	if [ ! -e "$notifier" ]; then
		notifier="`which notify-send`"
	fi
	if [ ! -e "$notifier" ]; then return; fi

	$notifier -u "$urgency" -t 5000 -i "$install_path/share/enlightenment/data/images/enlightenment.png" \
			  "Easy_EFL.sh" "$text" &>/dev/null
}

#############################################################################
function logfile_banner ()
{
	cmd=$1
	logfile=$2
	echo "-------------------------------------------------------------------------------" >> "$logfile"
	echo "EASY_EFL $version CMD: $cmd"													   >> "$logfile"
	echo "-------------------------------------------------------------------------------" >> "$logfile"
}

#############################################################################
function cnt_pkgs () {
    pkg_total=0
    pkg_pos=0
    
    if [ -n "$only" ]; then
		pkg_total=`echo "$only" | wc -w`
    else
		pkg_total=`echo "$packages" | wc -w`
    fi
} 

#############################################################################
function check_script_version ()
{
	echo "- local version .............. $version"
	source=`wget $online_source -q -U "easy_efl.sh/$version" -O -`
	if [ "$source" ]; then
		echo -n "- update available ........... "
		if [ `echo "$source" | diff - "$0" &>/dev/null; echo $?` -eq 1 ]; then
				echo -e "\033[1mYES!\033[0m"
		else	echo "no"; fi
	else
		echo -e "\033[1mERROR!\033[0m"
	fi
}


#############################################################################
# SCRIPT                                                                    #
#############################################################################
set_title 
define_os_vars

# parse --conf: alternative config file path defined?
test_options=$command_options
for arg in $test_options; do
	option=`echo "'$arg'" | cut -d'=' -f1 | tr -d "'"`
	value=`echo "'$arg'" | cut -d'=' -f2- | tr -d "'"`
	if [ "$value" == "$option" ]; then value=""; fi
	if [ "$option" == "--conf" ]; then conf_files="$conf_files $value"; fi 
done

# remove duplicated configfile entries	#FIXME[morlenxus]: After config file loading?
for filea in $conf_files; do
	exists=0
	for fileb in $tmp_conf_files; do
		if [ "$filea" == "$fileb" ]; then
			exists=1
			break
		fi
	done

	if [ $exists -eq 0 ]; then tmp_conf_files="$tmp_conf_files $filea"; fi
done
conf_files=$tmp_conf_files

for file in $conf_files; do
	if [ -e "$file" ]; then
		# load configfile 
		for option in `cat "$file"`; do
			easy_options="$easy_options $option"
		done
	fi
done

# append arguments
easy_options="$easy_options $command_options" 

# check options
for arg in $easy_options
do
	option=`echo "'$arg'" | cut -d'=' -f1 | tr -d "'"`
	value=`echo "'$arg'" | cut -d'=' -f2- | tr -d "'"`
	if [ "$value" == "$option" ]; then value=""; fi

	# $action can't be set twice
	if [ "$action" ]; then 
		if [ "$option" == "-i" ] ||
		   [ "$option" == "--install" ] ||
		   [ "$option" == "-u" ] ||
		   [ "$option" == "--update" ] ||
		   [ "$option" == "--only" ] ||
		   [ "$option" == "--srcupdate" ] ||
		   [ "$option" == "-v" ] ||
		   [ "$option" == "--check-script-version" ]; then
			logo 0 "Only one action allowed (you selected '--$action' and '$option')!"
			exit 1
		fi
	fi
	
	case "$option" in
		-i|--install)				action="install" ;;
		-u|--update)				action="update" ;;
		--packagelist)			;;	# has it's own parsing section
		--custompackage)
			if [ -z "$value" ]; then
				logo 0 "Missing value for argument '$option'!"
				exit 1
			fi
			app=`echo $value | cut -d':' -f1`
			vcs=`echo $value | cut -d':' -f2 -s | cut -d',' -f1`
			url=`echo $value | cut -d':' -f2- -s | cut -d',' -f2`
			branch=`echo $value | cut -d':' -f2- -s | cut -d',' -f3`
			if [ -z "$branch" ]; then
				branch=$git_branch 
			fi
			custom_packages+=("$app|$vcs|$url|$branch")
			;;
		--conf)					;;	# has it's own parsing section
		--only)
			if [ -z "$value" ]; then
				logo 0 "Missing value for argument '$option'!"
				exit 1
			fi
			action="only"
			only="`echo "$value" | tr -s '\,' '\ '` $only"
			;;
		-v|--check-script-version)	action="script" ;;
		--srcupdate)
			action="srcupdate"
			skip="$packages"
			;;
		--instpath)					install_path="$value" ;;
		--srcpath)					src_path="$value" ;;
		--asuser)					asuser=1 ;;
		--no-sudopwd)				no_sudopwd=1 ;;
		-c|--clean)					clean=$(($clean + 1))	;;
		-d|--docs)					gen_docs=1 ;;
		--postscript)				easy_efl_post_script="$value" ;;
		-s|--skip-srcupdate)		skip_srcupdate=1 ;;
#		-a|--ask-on-src-conflicts)	ask_on_src_conflicts=1 ;;	// FIXME[morlenxus]
		--skip)
			if [ -z "$value" ]; then
				logo 0 "Missing value for argument '$option'!"
				exit 1
			fi
			skip="`echo "$value" | tr -s '\,' '\ '` $skip"
			;;
		-e|--skip-errors)			skip_errors=1 ;;		
		-w|--wait)					wait=1 ;;
		--anim)
			case $value in
				"weeh")	animation="weeh" ;;
				*)		animation="star" ;;
			esac
			;;
		-n|--disable-notification)	notification_disabled=1 ;;
		-k|--keep)					keep=1 ;;

		-l|--low) 					nice_level=19 ;;
		--normal) ;;
		-h|--high) 					nice_level=-20 ;;
		--cache)
			accache=" --cache-file=$tmp_path/easy_efl.cache"
			ccache=`whereis ccache`
			if [ ! "$ccache" = "ccache:" ]; then
			    export CC="ccache gcc"
			fi
			;;
		--threads)
			if [ -z "$value" ] || ! expr "$value" : "[0-9]*$" >/dev/null || [ "$value" -lt 1 ]; then
				logo 0 "Missing value for argument '$option'!"
				exit 1
			fi
			threads=$value
			;;
		--autogen_args)	
			if [ -z "$value" ]; then
				logo 0 "Missing value for argument '$option'!"
				exit 1
			fi
			autogen_args="$value"
			;;
		--cflags)
			if [ -z "$value" ]; then
				logo 0 "Missing value for argument '$option'!"
				exit 1
			fi
			CFLAGS="$CFLAGS `echo "$value" | tr -s '\,' '\ '`"
			;;
		--ldflags)
			if [ -z "$value" ]; then
				logo 0 "Missing value for argument '$option'!"
				exit 1
			fi
			LDFLAGS="$LDFLAGS `echo "$value" | tr -s '\,' '\ '`"
			;;
		--pkg_config_path)
			if [ -z "$value" ]; then
				logo 0 "Missing value for argument '$option'!"
				exit 1
			fi
			PKG_CONFIG_PATH="$PKG_CONFIG_PATH:`echo "$value" | tr -s '\,' '\ '`"
			;;
		--help)
			fullhelp=1
			logo 0
			exit 0
			;;
		*)
			logo 0 "Unknown argument '$option'!"
			exit 1
			;;
	esac
done


# Sanity check stuff if doing everything as user.
if [ "$asuser" ] && [ $nice_level -lt 0 ]; then
	nice_level=0
fi

# Fix issues with a slash at the end
if [ ! "${src_path:$((${#src_path}-1)):1}" == "/" ]; then
	src_path="$src_path/"
fi

# quit if some basic option is missing
if [ -z "$action" ] || [ -z "$install_path" ] || [ -z "$src_path" ]; then
	logo 0
	exit 1
fi

# check for script updates
if [ "$action" == "script" ]; then
	logo 0
	echo -e "\033[1m-------------------------------------\033[7m AUTHORS \033[0m\033[1m----------------------------------\033[0m"
	echo -e "\033[1m  Developers:\033[0m      Brian 'morlenxus' Miculcy"
	echo -e "                   David 'onefang' Seikel"
	echo -e "\033[1m  Contributors:\033[0m    Tim 'amon' Zebulla"
	echo -e "                   Daniel G. '_ke' Siegel"
	echo -e "                   Stefan 'slax' Langner"
	echo -e "                   Massimiliano 'Massi' Calamelli"
	echo -e "                   Thomas 'thomasg' Gstaedtner"
	echo -e "                   Roberto 'rex' Sigalotti"
	echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
	echo
	echo -e "\033[1m------------------------------\033[7m Check script version \033[0m\033[1m----------------------------\033[0m"
	check_script_version
	echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
	echo
	exit 0
fi


# add custom packages to packagelist
for package in ${custom_packages[*]}
{	package_name=`echo "$package" | cut -d'|' -f1`
	custom_packages_list="$custom_packages_list $package_name"
}

# create packagelists
packages_basic="$base_libs_list$base_apps_list$base_modules_list$custom_packages_list"
packages_full="$base_libs_list$base_apps_list$base_modules_list$extra_apps_list$extra_games_list$custom_packages_list"
packages_custom="$custom_packages_list"

# parse --packagelist: select packagelist
packages="$packages_basic"
for arg in $easy_options
do
	option=`echo "'$arg'" | cut -d'=' -f1 | tr -d "'"`
	value=`echo "'$arg'" | cut -d'=' -f2- | tr -d "'"`
	if [ "$value" == "$option" ]; then value=""; fi

	if [ "$option" == "--packagelist" ]; then
		case $value in
			"custom")			packages="$packages_custom" ;;
			"full")				packages="$packages_full" ;;
		esac
	fi 
done


# run script normally
logo 1
set_title "Basic system checks"
echo -e "\033[1m-------------------------------\033[7m Basic system checks \033[0m\033[1m----------------------------\033[0m"
echo -n "- creating dirs .... "
mkdir -p "$tmp_path"		2>/dev/null
mkdir -p "$tmp_compile_dir"	2>/dev/null
mkdir -p "$tmp_install_dir"	2>/dev/null
mkdir -p "$logs_path"		2>/dev/null
mkdir -p "$status_path"		2>/dev/null
mkdir -p "$src_path"		2>/dev/null
chmod 700 "$tmp_path"
echo "ok"

echo "- basic dependency check:"
max=23
for deps in $deps_bin $make; do
	found=0
	for dep in `echo "$deps" | tr '|' ' '`; do
		cnt=${#dep}

		echo -n "  - '$dep' "
		while [ ! $cnt = $max ]; do
			echo -n "."
			cnt=$(($cnt+1))
		done
		echo -n " "

		if [ `type $dep &>/dev/null; echo $?` -ne 0 ]; then
			echo -e "\033[1mMISSING, TRYING ALTERNATIVE COMMAND\033[0m"
		else
			found=1
			echo "ok"
			break
		fi
	done

	if [ $found -eq 0 ]; then
		error "Required command missing!"
	fi
done

compfile="$tmp_path/include_test.c"
echo "main(){}" >$compfile
for deps in $deps_dev; do
	found=0
	for dep in `echo "$deps" | tr '|' ' '`; do
		cnt=${#dep}

		echo -n "  - '$dep' "
	    while [ ! $cnt = $max ]; do
			echo -n "."
			cnt=$(($cnt+1))
		done
		echo -n " "
	
		if [ `gcc -o /dev/null $compfile -l$dep &>/dev/null; echo $?` -ne 0 ]; then
			echo -e "\033[1mMISSING, TRYING ALTERNATIVE INCLUDE\033[0m"
		else
			found=1
			echo "ok"
			break
		fi
	done

	if [ $found -eq 0 ]; then
		error "Required include missing!"
	fi
done
rm -rf $compfile 2>/dev/null


if [ ! "$action"  == "srcupdate" ]; then
	echo -n "- build-user ................. "
	if [ ! "$username" == "root" ]; then
		if [ "$asuser" ]; then
			echo "$username (as user)"
			mode="user"
		else
			echo "$username (non-root)"
			echo -n "- sudo available ............. "
			sudotest=`type sudo &>/dev/null ; echo $?`
			if [ "$sudotest" == 0 ]; then
				if [ "$no_sudopwd" == 1 ]; then
					echo "ok"
				else
					sudo -K
					if [ -e "$tmp_path/sudo.test" ]; then
						rm -f "$tmp_path/sudo.test"
					fi
					while [ -z "$sudopwd" ]; do
						echo -n "enter sudo-password: "
						stty -echo
						read sudopwd
						stty echo
			
						# password check
						echo "$sudopwd" | sudo -S touch "$tmp_path/sudo.test" &>/dev/null
						if [ ! -e "$tmp_path/sudo.test" ]; then
							sudopwd=""
						fi
					done
					rm -f "$tmp_path/sudo.test"
				fi
				echo 
				mode="sudo"
			else
				error "You're not root and sudo isn't available. Please run this script as root!"
			fi
		fi
	else
		echo "root"
		mode="root"
	fi


	echo -n "- setting env variables ...... " 
	export PATH="$install_path/bin:$PATH"
	export ACLOCAL_FLAGS="-I $install_path/share/aclocal $ACLOCAL_FLAGS"
	export LD_LIBRARY_PATH="$install_path/lib:$LD_LIBRARY_PATH"
	export PKG_CONFIG_PATH="$install_path/lib/pkgconfig:$PKG_CONFIG_PATH"
	export CPPFLAGS="$CPPFLAGS -I$install_path/include"
	export LDFLAGS="$LDFLAGS -L$install_path/lib"
	export CFLAGS="$CFLAGS"
	export PYTHONPATH=`python -c "import distutils.sysconfig; print distutils.sysconfig.get_python_lib(prefix='$install_path')" 2>/dev/null`
	export PYTHONINCLUDE=`python -c "import distutils.sysconfig; print distutils.sysconfig.get_python_inc(prefix='$install_path')" 2>/dev/null`
	echo "ok"

	echo -n "- creating destination dirs .. " 
	case "$mode" in
		user|root)	mkdir -p "$install_path/share/aclocal" ;;
		sudo)		echo "$sudopwd" | sudo -S mkdir -p "$install_path/share/aclocal" ;;
	esac
	# PYTHON BINDING FIXES
	if [ "$PYTHONPATH" ]; then
		case "$mode" in
			user|root)	mkdir -p "$PYTHONPATH" ;;
			sudo)		echo "$sudopwd" | sudo -S mkdir -p "$PYTHONPATH" ;;
		esac
	fi
	if [ "$PYTHONINCLUDE" ]; then
		case "$mode" in
			user|root)	mkdir -p "$PYTHONINCLUDE" ;;
			sudo)		echo "$sudopwd" | sudo -S mkdir -p "$PYTHONINCLUDE" ;;
		esac
	fi
	echo "ok"
	
	echo -n "- checking lib-path in ld .... "
	case $os in
		FreeBSD) ;; # TODO: placeholder
		SunOS)	 ;; # TODO: need more testing of adding libraries on different solaris versions. atm this is not working
		Linux)
			libpath="`grep -r -l -i -m 1 $install_path/lib /etc/ld.so.conf*`"
			if [ -z "$libpath" ]; then
				case $linux_distri in
					gentoo)
						eflldcfg="/etc/env.d/40eflpaths"
						echo -e "PATH=$install_path/bin\nROOTPATH=$install_path/sbin:$install_path/bin\nLDPATH=$install_path/lib\nPKG_CONFIG_PATH=$install_path/lib/pkgconfig" > $eflldcfg 
						env-update &> /dev/null
						echo "ok (path has been added to $eflldcfg)";
						;;

					*)
						if [ "`grep -l 'include /etc/ld.so.conf.d/' /etc/ld.so.conf`" ]; then
							eflldcfg="/etc/ld.so.conf.d/efl.conf"
						else
							eflldcfg="/etc/ld.so.conf";
							cp $eflldcfg $tmp_path;
						fi

						case "$mode" in
							"user") ;;
							"root")	echo "$install_path/lib" >>$eflldcfg ;;
							"sudo")
								echo "$install_path/lib" >> $tmp_path/`basename $eflldcfg`
								echo "$sudopwd" | sudo -S mv -f $tmp_path/`basename $eflldcfg` $eflldcfg
								;;
						esac
						if [ "$asuser" ]; then
								echo "skipped (running as user)";
						else	echo "ok (path has been added to $eflldcfg)"; fi
						;;
				esac
			else
				echo "ok ($libpath)";
			fi
			;;
	esac

	if [ "$only" ]; then
		echo
		echo "- matching packages with package lists (basic/full/custom)..."

		monly=$only
		only=""
		for opkg in $monly; do
			found=0;
			echo -n "  - $opkg: "

			for pkg in $packages; do
				if [ "$opkg" == "$pkg" ]; then
					found=1;
				fi
			done

			case $found in
				"1")
					echo "ok"
					only="$only $opkg"
					;;
				*)
					echo -e "\033[1mNOT FOUND!\033[0m"
					;;
			esac
		done
	fi
fi
echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
echo


# sources
echo -e "\033[1m------------------------\033[7m Source clone/checkout/update \033[0m\033[1m--------------------------\033[0m"
if [ -z "$skip_srcupdate" ]; then
	packages_updated=""

	# Walk through packages
	for package_name in $packages; do
		package_path="$src_path/$package_name"
		package_info=`package_find $package_name`
		if [ -z "$package_info" ]; then
			echo "UNKNOWN PACKAGE"
			continue
		fi
		package_vcs=`echo "$package_info" | cut -d'|' -f2`
		package_url=`echo "$package_info" | cut -d'|' -f3`
		package_branch=`echo "$package_info" | cut -d'|' -f4`

		error=0
		attempt=1
		maxerrors=5
		retrytimer=15

		update_done=0
		file_svnupdate="$tmp_path/svnupdate.log"
		if [ -e "$file_svnupdate" ]; then
			rm "$file_svnupdate"
		fi

		while [ 1 ]; do 
			write_name "$package_name"

			if [ "$only" ]; then
				found=0
				for one in $only; do
					if [ "$package_name" == "$one" ]; then found=1; fi
				done
				if [ $found -eq 0 ]; then
					echo "SKIPPED"
					break
				fi
			fi

			if [ "$skip" ]; then
				found=0
				for one in $skip; do
					if [ "$package_name" == "$one" ]; then found=1; fi
				done
				if [ $found -eq 1 ]; then
					echo "SKIPPED"
					break
				fi
			fi

			if [ ! -d "$package_path" ]; then
				mkdir -p "$package_path"
			fi
			cd "$package_path"
	
			case $package_vcs in
				"git")
					if [ -d ".git" ]; then
						# Repository found
						echo "FETCH/REBASE:"

						# Add user token
						if [ -z "`git config user.name`" ]; then
							git config --global user.name "$username"
						fi
						if [ -z "`git config user.email`" ]; then
							git config --global user.email "$username@localhost"
						fi

						git stash	# save local changes, restore defaults
						error=$?
						if [ $error -eq 0 ]; then
							git fetch	# update branch, don't apply
							error=$?
						fi
						if [ $error -eq 0 ] && [ "`git diff --name-only $package_branch`" ]; then
							git checkout $package_branch
							update_done=1
						fi
					else
						# Clean directory, new Clone/Checkout
						echo "CLONE/CHECKOUT:"

						git clone $package_url .
						error=$?
						if [ $error -eq 0 ]; then
							git checkout $package_branch
							error=$?
						fi
						if [ $error -eq 0 ]; then
							update_done=1
						fi
					fi
					;;

				"svn")
					if [ -d ".svn" ]; then
						# Repository found
						echo "UPDATE:"

						svn update --accept theirs-full -r HEAD | tee -a "$file_svnupdate"
						error=${PIPESTATUS[0]}
						if [ $error -eq 0 ]; then
							if [ `egrep -q "^[A|D|G|U] " "$file_svnupdate"; echo $?` -eq 0 ]; then
								update_done=1
							fi
						fi
					else
						# Clean directory, new Checkout
						echo "CHECKOUT:"

						svn checkout -r HEAD $package_url .
						error=$?
						update_done=1
					fi
					;;

				*)
					echo "UNKNOWN VCS $package_vcs"
					break
					;;
			esac

			if [ $attempt -eq $maxerrors ]; then
				echo -e "\n\033[1mFAILED! Skipping update...\033[0m"
				break
			fi

			if [ $error -gt 0 ]; then
				attempt=$(($attempt+1))
 				set_title "Source update of $package_name failed, trying again in $retrytimer seconds..."
				echo -e "\n\033[1mFAILED! Next attempt $attempt/$maxerrors in $retrytimer seconds...\033[0m"
				sleep $retrytimer
			else
				if [ $update_done -gt 0 ]; then
					packages_updated="$packages_updated $package_name"
				fi
				break
			fi
		done

		if [ -e "$file_svnupdate" ]; then
			rm "$file_svnupdate"
		fi
	done

	if [ "$action" == "update" ]; then
		only="$packages_updated"
	fi
else
	echo -e "\n                                - - - SKIPPED - - -\n"
fi
echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
echo

echo -n "-> PREPARING FOR PHASE 2..."
set_title "Preparing for phase 2... compilation & installation"
sleep 5

if [ "$action" == "install" ]; then
	set_notification "normal" "Now building packages..."
elif [ "$action" == "only" ]; then
	set_notification "normal" "Now building following packages: $only"
elif [ "$action" == "update" ]; then
	if [ "$only" ]; then
			set_notification "normal" "Now building following packages: $only"
	else	set_notification "normal" "Everything is up to date, nothing to build."; fi
fi
logo 2
echo -e "\033[1m-----------------------\033[7m Compiling and installing packages \033[0m\033[1m----------------------\033[0m"
cnt_pkgs
for package_name in $packages; do
	compile $package_name
done
echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
echo

# Restore current directory in case post processing wants to be pathless.
cd $EASY_PWD

echo -e "\033[1m-----------------------------\033[7m Finishing installation \033[0m\033[1m---------------------------\033[0m"
echo -n "- registering libraries ...... "
if [ -z "$asuser" ]; then
	case "$mode" in
		"sudo") echo "$sudopwd" | sudo -S nice -n $nice_level $ldconfig > /dev/null 2>&1 ;;
		*) nice -n $nice_level $ldconfig > /dev/null 2>&1 ;;
	esac
	echo "ok"
else
	echo "skipped"
fi
echo -n "- post install script ........ "
if [ "$easy_efl_post_script" ]; then
	echo -n " '$easy_efl_post_script' ... "
	case "$mode" in
		"sudo") echo "$sudopwd" | sudo -S nice -n $nice_level $easy_efl_post_script ;;
		*) nice -n $nice_level $easy_efl_post_script ;;
	esac
	echo "ok"
else	
	echo "skipped"
fi
echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
echo


echo -n "-> PREPARING FOR PHASE 3..."
set_title "Preparing for phase 3..."
sleep 5

logo 3
set_title "Finished"

for pkg in $packages; do
	if [ -e "$status_path/$pkg.installed" ]; then
		packages_installed="$packages_installed $pkg"
	else
		if [ -e "$status_path/$pkg.skipped" ]; then
			packages_skipped="$packages_skipped $pkg"
		else
			packages_failed="$packages_failed $pkg"
		fi
	fi
done

echo -e "\033[1m--------------------------------\033[7m Cleaning temp dir \033[0m\033[1m-----------------------------\033[0m"
echo -n "- deleting status dir ........ "
rm -rf $status_path 2>/dev/null
echo "ok"

if [ -z "$keep" ]; then
	if [ "$packages_failed" ]; then
		echo -n "- cleaning log dir ........... "	
		for pkg in $packages_installed $packages_skipped; do
			rm "$logs_path/$pkg.log" 2>/dev/null
		done
	else
		echo -n "- deleting temp dir .......... "
		rm -rf $tmp_path 2>/dev/null
	fi	
	echo "ok"
else	
	echo "- keeping log files .......... ok"
fi
echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
echo

if [ "$packages_installed" ]; then
	echo -e "\033[1m-------------------------------\033[7m Installed packages \033[0m\033[1m-----------------------------\033[0m"
	for pkg in $packages_installed; do
		echo "- $pkg"
	done
	echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
	echo 
fi

if [ "$packages_failed" ]; then
	echo -e "\033[1m---------------------------------\033[7m Failed packages \033[0m\033[1m------------------------------\033[0m"
	for pkg in $packages_failed; do
		echo -n "- $pkg"
		if [ -e "$logs_path/$pkg.log" ]; then
			echo -n " (error log: $logs_path/$pkg.log)"
		fi
		echo
	done
	echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
	echo 
	set_notification "critical" "Script finished with build errors."
else
	set_notification "normal" "Script finished successful."
fi

if [ "$action" == "install" ]; then
	echo
	echo "INSTALL NOTES:"
	echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
	echo "To start enlightenment you need to create a file ~/.xsession with these lines:"
	echo "--------- 8< ----------"
	echo "export PATH=\"$install_path/bin:\$PATH\""
	echo "export XDG_DATA_DIRS=\"/opt/efl/share:\$XDG_DATA_DIRS\""
	echo "export PYTHONPATH=\"`python -c \"import distutils.sysconfig; print distutils.sysconfig.get_python_lib(prefix='$install_path')\" 2>/dev/null`:\$PYTHONPATH\""
	echo "exec $install_path/bin/enlightenment_start"
	echo "--------- >8 ----------"
	echo "Add a link to this file using 'ln -s ~/.xsession ~/.xinitrc' ."
	echo
	echo "If you're using a login manager (GDM/KDM), select the session type 'default'"
	echo "in them. If you're using the startx command, siply execute it now."
	echo
	echo "Hint: From now on you can easily keep your installation up to date."
	echo "Simply run easy_efl.sh with -u instead of -i ."
	echo
	echo "We hope you will enjoy enlightenment... Have fun!"
	echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
fi

# Clear this out if we ever set it.
export CC=""

# exit script or wait?
if [ "$wait" ]; then
	echo
	echo -e -n "\033[1mThe script is waiting here - simply press [enter] to exit.\033[0m"
	read
fi	

set_title
if [ "$packages_failed" ]; then
		exit 2
else	exit 0; fi
