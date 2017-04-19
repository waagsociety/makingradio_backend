GIT_DIR="${1}"
REPO="${2}"
MY_USER=${3}
CONF_FILE=${4}

if [ ! -d "${GIT_DIR}" ]
then
	sudo su $MY_USER -c "git clone ${REPO} ${GIT_DIR}"
else
	if sudo su $MY_USER -c "git -C ${GIT_DIR} remote -v update" | grep master | grep 'origin/master' | grep -v 'up to date' >/dev/null
	then
	  echo "Code not changed"
		exit 0
	else
		cd ${GIT_DIR};
		if ! sudo su $MY_USER -c "git pull"
		then
		    echo "ERROR pulling"
		    exit 1
		fi
	fi
fi

cd ${GIT_DIR}/gammaserver

sudo su $MY_USER -c bundler

sudo passenger stop

mv ${CONF_FILE} ${GIT_DIR}/gammaserver/

sudo passenger start
