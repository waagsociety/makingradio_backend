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

if [ -f ${CONF_FILE} ]
then
	if [ ! -f ${GIT_DIR}/gammaserver/${MY_FILENAME} ] || ! diff ${GIT_DIR}/gammaserver/${MY_FILENAME} ${CONF_FILE} >/dev/null
	then
		mv ${CONF_FILE} ${GIT_DIR}/gammaserver/
		sudo passenger stop
	fi
fi

PASG_FILE=Passengerfile.json

if ! dpkg -s jq >/dev/null
then
	sudo apt-get install jq
fi

PASG_USER=$(jq '.user' ${PASG_FILE} | tr  -d '"' )
PASG_LOG=$(jq '.log_file' ${PASG_FILE} | tr  -d '"' )
PASG_PID=$(jq '.pid_file' ${PASG_FILE} | tr  -d '"' )

PASG_LOG_DIR=$(dirname ${PASG_LOG})
PASG_PID_DIR=$(dirname ${PASG_PID})

if [ ! -d "${PASG_LOG_DIR}" ]
then
	sudo mkdir -P ${PASG_LOG_DIR}
fi

sudo chown -R ${PASG_USER}:${PASG_USER} ${PASG_LOG_DIR}

if [ ! -d "${PASG_PID_DIR}" ]
then
	sudo mkdir -P ${PASG_PID_DIR}
fi

# sudo chmod ${PASG_USER}:${PASG_USER} ${PASG_LOG_DIR}

sudo passenger start

sudo passenger-config restart-app /
