#!/bin/bash

# Navigate to the script directory
pushd "$(dirname "$0")" > /dev/null

echo "Checking Git installation"
if ! command -v git &> /dev/null; then
    echo "Git is not installed on this system. Skipping update."
    echo "If you installed with a zip file, you will need to download the new zip and install it manually."
    exit 1
fi

# Checking current branch
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo "Current branch: $CURRENT_BRANCH"

# Checking for automatic branch switching configuration
AUTO_SWITCH=$(git config --local script.autoSwitch)

TARGET_BRANCH="$CURRENT_BRANCH"

if [[ -n "$AUTO_SWITCH" ]]; then
    case "$AUTO_SWITCH" in
        s|staging)
            echo "Auto-switching to staging branch"
            git checkout staging
            TARGET_BRANCH="staging"
            ;;
        r|release)
            echo "Auto-switching to release branch"
            git checkout release
            TARGET_BRANCH="release"
            ;;
        *)
            echo "Auto-switching defined to stay on current branch"
            ;;
    esac
else
    if [[ "$CURRENT_BRANCH" != "staging" && "$CURRENT_BRANCH" != "release" ]]; then
        echo "You are not on 'staging' or 'release'. You are on '$CURRENT_BRANCH'."
        read -p "Do you want to switch to 'staging' (s), 'release' (r), or stay (any other key)? " CHOICE
        case "$CHOICE" in
            s|S)
                echo "Switching to staging branch"
                git checkout staging
                TARGET_BRANCH="staging"
                ;;
            r|R)
                echo "Switching to release branch"
                git checkout release
                TARGET_BRANCH="release"
                ;;
            *)
                echo "Staying on the current branch"
                ;;
        esac
    else
        echo "Staying on the current branch"
    fi
fi

update_and_merge() {
    local remote_name=$1
    echo "Fetching updates from '$remote_name'"
    git fetch $remote_name && echo "Merging updates against '$remote_name'" && git merge $remote_name/$TARGET_BRANCH

    if [[ $? -ne 0 ]]; then
        echo "There were errors while merging from $remote_name. Please check manually."
        exit 1
    fi
}

if [[ "$TARGET_BRANCH" == "release" ]]; then
    # Fetch from upstream and merge/rebase updates
    update_and_merge "upstream"

    # Fetch from origin and merge/rebase updates
    update_and_merge "origin"

else
    # Default behavior for non-release branches or if no choice was made for release branch
    update_and_merge "origin"
fi

source start.sh