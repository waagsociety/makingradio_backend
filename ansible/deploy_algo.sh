MY_USER=${1}
GIT_DIR="${2}"
DEST_DIR="${3}"
REPO="${4}"
BRANCH="${5}"

if [ ! -d "${GIT_DIR}" ]
then
	sudo su $MY_USER -c "git clone ${REPO} ${GIT_DIR}"
elif sudo su $MY_USER -c "git -C ${GIT_DIR} remote -v update" 2>&1 | grep ${BRANCH} | grep "origin/${BRANCH}" | grep 'up to date' >/dev/null
then
  echo "Code not changed"
  exit 0
fi

cd ${GIT_DIR};

if ! sudo su $MY_USER -c "git fetch && git checkout ${BRANCH}"
then
    echo "ERROR checking out branch ${BRANCH}"
    exit 1
fi

if ! sudo su $MY_USER -c "git pull"
then
    echo "ERROR pulling"
    exit 1
fi

if [ -d "${DEST_DIR}" ]
then
    sudo rm -rf ${DEST_DIR}
fi

sudo mkdir ${DEST_DIR}

sudo cp -r index.html src/ ${DEST_DIR}
sudo chown -R www-data:www-data ${DEST_DIR}
sudo chmod -R ug-w,o-rwx ${DEST_DIR}
