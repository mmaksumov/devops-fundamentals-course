#!/usr/bin/env bash

COLOR_GREEN='\e[32m'
COLOR_YELLOW='\e[33m'
COLOR_RESET='\e[0m'
TAB="\t"

REPOSITORY_URL='https://github.com/EPAM-JS-Competency-center/shop-angular-cloudfront.git'
SOURCE_DIR='./temp'
REPO_DIR=$(basename -s .git "$REPOSITORY_URL")

DEPENDENCIES=(git npm zip)

show_usage() {
    SCRIPT="$(basename "$0")"

    echo "Usage:"
    echo -e "${TAB}${COLOR_GREEN}${SCRIPT}${COLOR_RESET}${TAB}${TAB}${TAB}${TAB}to build the client app with \$ENV_CONFIGURATION env configuration"
    echo -e "${TAB}${COLOR_GREEN}${SCRIPT} -e ENV_CONFIGURATION${COLOR_RESET}${TAB}to set the ENV_CONFIGURATION and build the client app"
    echo -e "${TAB}${COLOR_GREEN}${SCRIPT} -h${COLOR_RESET}${TAB}${TAB}${TAB}to show this help message"
    exit 0
}

# Check for script dependencies
for DEPENDENCY in "${DEPENDENCIES[@]}"; do
    if ! command -v "$DEPENDENCY" >/dev/null 2>&1; then
        echo -e "${COLOR_YELLOW}Error: $DEPENDENCY is not installed. Please install it and try again${COLOR_RESET}"
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

# Set and use the ENV_CONFIGURATION (production or empty string for development configuration) env variable to specify the app’s configuration to use during the build.
while getopts "e:h" opt; do
    case $opt in
    e)
        if [[ $OPTARG = 'production' ]]; then
            ENV_CONFIGURATION='production'
            echo "Setting ENV_CONFIGURATION to $ENV_CONFIGURATION"
        else
            ENV_CONFIGURATION=''
            echo "Setting ENV_CONFIGURATION to '' (empty string)"
        fi
        ;;
    h | *)
        show_usage
        ;;
    esac
done

declare -a CONDITIONAL_FILE=(
    ""
    ""
    ""
    "client-app.zip"
    ""
)

declare -a MESSAGES=(
    "Changing directory to '${SOURCE_DIR}/${REPO_DIR}'"
    "Installing npm dependencies"
    "Building the client app"
    "Removing existing client-app.zip"
    "Compressing the client app"
)

declare -a COMMANDS=(
    "cd ${SOURCE_DIR}/${REPO_DIR}"
    "npm install"
    "npm run build -- --configuration=$ENV_CONFIGURATION"
    "rm -f client-app.zip"
    "zip -r client-app.zip dist"
)

for i in {0..4}; do
    if [[ (-z "${CONDITIONAL_FILE[$i]}") || (-f "${CONDITIONAL_FILE[$i]}") ]]; then
        echo -n "${MESSAGES[$i]}... "
        if eval "${COMMANDS[$i]} >/dev/null 2>&1"; then
            echo -e "${COLOR_GREEN}[done]${COLOR_RESET}"
        else
            echo -e "${COLOR_YELLOW}[fail]${COLOR_RESET}"
            exit 1
        fi
    fi
done
