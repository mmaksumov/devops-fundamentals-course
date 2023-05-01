#!/usr/bin/env bash

# declare vars
COLOR_RED='\e[31m'
COLOR_YELLOW='\e[33m'
COLOR_RESET='\e[0m'
CURRENT_DATE=$(date +%Y-%m-%d)

SCRIPT_NAME=$(basename "$0")

# calculate output file name
OUTPUT_FILE="./pipeline-${CURRENT_DATE}.json"

BRANCH_NAME="main"
OWNER_NAME=""
REPO_NAME=""
POLL_FOR_SOURCE_CHANGES=false
CONFIGURATION=""

ADDITIONAL_PARAMETERS=false

# show usage function
usage() {
    echo -e "\nUsage:
    ${SCRIPT_NAME} --help
    ${SCRIPT_NAME} <path-to-pipeline.json>
    ${SCRIPT_NAME} <path-to-pipeline.json> <options>

        where options are:
            --owner <owner>
            --repo <repo>
            [--configuration <configuration>]
            [--branch <branch>]
            [--poll-for-source-changes]

        N.B.:
            1) without <options> script performs basic JSON transformation (steps 1.1 and 1.2)
            2) --owner and --repo are necessary for additional JSON transformation"

    exit "$1"
}

if [[ ($# -lt 1) || ($1 == '--help') ]]; then
    usage 0
fi

# validate if $1 is the path to the file (with pipeline definition JSON file).
# If not, it should throw an error and stop execution
if ! jq -e '.' "$1" >/dev/null 2>&1; then
    echo -e "${COLOR_RED}Error: $1 is not a JSON file."
    echo -e "${COLOR_YELLOW}Please specify the path to the file with pipeline definition JSON file as the first argument and try again${COLOR_RESET}\n"
    usage 2
fi

JSON_FILE="$1"

if [[ "$#" -gt 0 ]]; then
    ADDITIONAL_PARAMETERS=true
    PARSED_ARGUMENTS=$(getopt -n "$SCRIPT_NAME" -l configuration:,branch:,owner:,repo:,poll-for-source-changes -- "$@")

    eval set -- "$PARSED_ARGUMENTS"

    while true; do
        case $1 in
        --owner)
            OWNER_NAME="$2"
            shift 2
            ;;
        --repo)
            REPO_NAME="$2"
            shift 2
            ;;
        --configuration)
            CONFIGURATION="$2"
            shift 2
            ;;
        --branch)
            BRANCH_NAME="$2"
            shift 2
            ;;
        --poll-for-source-changes)
            POLL_FOR_SOURCE_CHANGES=true
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo -e "${COLOR_RED}Error: unrecognized option $1${COLOR_RESET}"
            usage 2
            ;;
        esac
    done

    if [[ -z "$OWNER_NAME" || -z "$REPO_NAME" ]]; then
        echo -e "${COLOR_RED}Error: --owner and --repo are required parameters if any options are set${COLOR_RESET}"
        usage 2
    fi
fi

# The script should validate if JQ is installed on the host OS.
# If not, display commands on how to install it on different platforms and stop script execution.
if ! command -v jq >/dev/null 2>&1; then
    echo -e "${COLOR_YELLOW}Error: jq is not installed. Please install it and try again${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Installation instructions available on https://stedolan.github.io/jq/download/{COLOR_RESET}"

    exit 1
fi

# basic JSON transforming
BASE_TRANSFORMING=$(jq 'del(.metadata) | .pipeline.version += 1' "$JSON_FILE")

if $ADDITIONAL_PARAMETERS; then
    # additional JSON transforming
    echo "$BASE_TRANSFORMING" | jq \
        --arg branch_name "$BRANCH_NAME" \
        --arg owner_name "$OWNER_NAME" \
        --arg repo_name "$REPO_NAME" \
        --arg poll_for_source_changes "$POLL_FOR_SOURCE_CHANGES" \
        --arg configuration "$CONFIGURATION" \
        'walk(
            if type == "object"
                and has("configuration")
                and has("name")
                and .name=="Source"
            then . + { configuration:
                        {
                            Branch: $branch_name,
                            OAuthToken: .configuration.OAuthToken,
                            Owner: $owner_name,
                            PollForSourceChanges: ($poll_for_source_changes != "false"),
                            Repo: $repo_name
                        }
                    }
            else
                .
            end
        )
        | walk (
            if type == "object"
                and has("EnvironmentVariables")
                and $configuration != ""
            then
                . + {
                    EnvironmentVariables: $configuration,
                    ProjectName
                }
            else
                .
            end
        )' >"$OUTPUT_FILE"
else
    echo "$BASE_TRANSFORMING" >"$OUTPUT_FILE"
fi
