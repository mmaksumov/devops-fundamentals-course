#!/usr/bin/env bash

# declare vars
COLOR_GREEN='\e[32m'
COLOR_YELLOW='\e[33m'
COLOR_RESET='\e[0m'
REPOSITORY_URL='https://github.com/EPAM-JS-Competency-center/shop-angular-cloudfront.git'
SCRIPT_FULL_PATH="$(realpath "$0")"
SCRIPT_DIR_PATH="$(dirname "$SCRIPT_FULL_PATH")"
SOURCE_DIR=$SCRIPT_DIR_PATH'/temp'
REPO_DIR=$(basename -s .git "$REPOSITORY_URL")

# declare script dependencies
declare -a DEPENDENCIES=(git npm ng google-chrome)

# check that all dependecies are installed and exit if not
for DEPENDENCY in "${DEPENDENCIES[@]}"; do
    if ! command -v "$DEPENDENCY" >/dev/null 2>&1; then
        echo "Error: $DEPENDENCY is not installed. Please install it and try again"
        exit 1
    fi
done

# git clone repo if we hasn't package.json in directory for source already
if [ ! -f "${SOURCE_DIR}/${REPO_DIR}/package.json" ]; then
    echo -n "Cloning the repository... "
    git clone --single-branch $REPOSITORY_URL "${SOURCE_DIR}/${REPO_DIR}" >/dev/null 2>&1
    echo -e "${COLOR_GREEN}[done]${COLOR_RESET}"
else
    echo "Directory for repository already exists and isn't empty. Skipping repo cloning..."
fi

# start quality check
declare -a MESSAGES=(
    "Changing directory to '${SOURCE_DIR}/${REPO_DIR}'"
    "Installing dependencies"
    "Checking npm audit results"
    "Checking linting"
    "Replace Karma config"
    "Testing the client app"
)

declare -a COMMANDS=(
    "cd ${SOURCE_DIR}/${REPO_DIR}"
    "npm install"
    "npm audit --only=prod"
    "npm run lint"
    "cp -f ${SCRIPT_DIR_PATH}/karma.conf.js ./karma.conf.js"
    "npm run test"
)

for i in {0..5}; do
    echo -n "${MESSAGES[$i]}... "
    if eval "${COMMANDS[$i]} >/dev/null 2>&1"; then
        echo -e "${COLOR_GREEN}[Success]${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}[Fail]${COLOR_RESET}"
        exit 1
    fi
done
