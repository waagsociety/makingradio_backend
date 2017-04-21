GIT_DIR="${1}"
REPO="${2}"
MY_USER=${3}
CONF_FILE=${4}

if [ ! -d "${GIT_DIR}" ]
then
	sudo su $MY_USER -c "git clone ${REPO} ${GIT_DIR}"
else
	if sudo su $MY_USER -c "git -C ${GIT_DIR} remote -v update 2>&1" | grep master | grep 'origin/master' | grep 'up to date' >/dev/null
	then
	  echo "Code not changed"
		NO_UPDATE="TRUE"
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

if [ "${NO_UPDATE} " = " " ]
then
	sudo su $MY_USER -c bundler
fi

MY_FILENAME=$(basename ${CONF_FILE})

if [ ! -f ${GIT_DIR}/gammaserver/${MY_FILENAME} ] || ! diff ${GIT_DIR}/gammaserver/${MY_FILENAME} ${CONF_FILE}
then
	mv ${CONF_FILE} ${GIT_DIR}/gammaserver/
	sudo passenger stop
fi

sudo passenger start

sudo passenger-config restart-app /
