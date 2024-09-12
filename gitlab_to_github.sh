#!/bin/bash

# Function to check if a command exists
check_command() {
    if ! [ -x "$(command -v $1)" ]; then
        return 1
    fi
    return 0
}

# Function to install a package
install_package() {
    local package=$1
    read -p "The package '$package' is not installed. Do you want to install it? (y/n): " install_choice
    if [ "$install_choice" == "y" ]; then
        if [ "$(uname)" == "Linux" ]; then
            if [ -x "$(command -v apt-get)" ]; then
                sudo apt-get update
                sudo apt-get install -y "$package"
            elif [ -x "$(command -v yum)" ]; then
                sudo yum install -y "$package"
            elif [ -x "$(command -v dnf)" ]; then
                sudo dnf install -y "$package"
            else
                echo "Error: Unable to determine package manager. Please install $package manually."
                exit 1
            fi
        elif [ "$(uname)" == "Darwin" ]; then
            if [ -x "$(command -v brew)" ]; then
                brew install "$package"
            else
                echo "Error: Homebrew is not installed. Please install Homebrew to proceed."
                exit 1
            fi
        else
            echo "Error: Unsupported OS. Please install $package manually."
            exit 1
        fi
    else
        echo "The script cannot continue without $package. Exiting."
        exit 1
    fi
}

# Enable Git credential caching
echo "Configuring Git to cache credentials for 1 hour..."
git config --global credential.helper 'cache --timeout=3600'

# Check and install Git if not installed
check_command git
if [ $? -ne 0 ]; then
    install_package git
fi

# Prompt the user for GitLab repository URL
read -p "Enter the GitLab repository URL: " gitlab_url

# Extract repository name from the GitLab URL
repo_name=$(basename -s .git "$gitlab_url")

# Check if the repository directory already exists
if [ -d "$repo_name" ]; then
    echo "Directory '$repo_name' already exists."
    read -p "Do you want to delete the existing directory and continue? (y/n): " delete_choice
    if [ "$delete_choice" == "y" ]; then
        rm -rf "$repo_name"
        echo "Directory deleted."
    else
        read -p "Do you want to clone into a different directory? (y/n): " clone_choice
        if [ "$clone_choice" == "y" ]; then
            read -p "Enter the new directory name: " new_dir_name
            repo_name=$new_dir_name
        else
            echo "Aborting the script. Please resolve the directory conflict and try again."
            exit 1
        fi
    fi
fi

# Prompt the user for GitHub repository URL
read -p "Enter the GitHub repository URL: " github_url

# Clone the GitLab repository
echo "Cloning GitLab repository into '$repo_name'..."
git clone "$gitlab_url" "$repo_name"
if [ $? -ne 0 ]; then
    echo "Error: Failed to clone GitLab repository."
    exit 1
fi

# Navigate into the cloned repository
cd "$repo_name" || exit

# Add GitHub as a new remote
echo "Adding GitHub as a new remote..."
git remote add github "$github_url"
if [ $? -ne 0 ]; then
    echo "Error: Failed to add GitHub remote."
    exit 1
fi

# Push all branches to GitHub
echo "Pushing all branches to GitHub..."
git push github --all
if [ $? -ne 0 ]; then
    echo "Error: Failed to push branches to GitHub."
    exit 1
fi

# Push all tags to GitHub
echo "Pushing all tags to GitHub..."
git push github --tags
if [ $? -ne 0 ]; then
    echo "Error: Failed to push tags to GitHub."
    exit 1
fi

# Ask the user if they want to remove the GitLab remote
read -p "Do you want to remove the GitLab remote? (y/n): " remove_gitlab

if [ "$remove_gitlab" == "y" ]; then
    echo "Removing GitLab remote..."
    git remote remove origin
    if [ $? -ne 0 ]; then
        echo "Error: Failed to remove GitLab remote."
        exit 1
    fi
fi

# Check if the 'origin' remote already exists
if git remote get-url origin >/dev/null 2>&1; then
    echo "Remote 'origin' already exists."
    read -p "Do you want to rename the GitHub remote to 'origin-force'? (y/n): " rename_github
    if [ "$rename_github" == "y" ]; then
        echo "Renaming GitHub remote to 'origin-force'..."
        git remote rename github origin-force
        if [ $? -ne 0 ]; then
            echo "Error: Failed to rename GitHub remote."
            exit 1
        fi
    else
        echo "Keeping the remote as 'github'."
    fi
else
    read -p "Do you want to rename the GitHub remote to 'origin'? (y/n): " rename_github
    if [ "$rename_github" == "y" ]; then
        echo "Renaming GitHub remote to 'origin'..."
        git remote rename github origin
        if [ $? -ne 0 ]; then
            echo "Error: Failed to rename GitHub remote."
            exit 1
        fi
    fi
fi

echo "Migration complete!"

