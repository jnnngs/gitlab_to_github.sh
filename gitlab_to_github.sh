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

# Prompt the user for GitHub Personal Access Token (PAT)
read -sp "Enter your GitHub Personal Access Token: " github_token
echo ""

# Prompt the user for GitHub repository details
read -p "Enter the new GitHub repository name: " new_repo_name
read -p "Enter a description for the GitHub repository: " repo_description
read -p "Should the repository be private? (y/n): " repo_private

# Convert 'y'/'n' input to true/false
if [ "$repo_private" == "y" ]; then
    private=true
else
    private=false
fi

# Create the new Git

