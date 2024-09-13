#!/bin/bash


#                                      
#               Jnnngs                  
#                                      
#       GitLab to GitHub Migration Tool

# Function to check if a command exists
check_command() {
    if ! [ -x "$(command -v "$1")" ]; then
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

# Check and install Git if not installed
check_command git
if [ $? -ne 0 ]; then
    install_package git
fi

# Enable Git credential caching for 1 hour
git config --global credential.helper 'cache --timeout=3600'

# Prompt for GitLab repository URL
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

# Check if GitHub Personal Access Token (PAT) exists as an environment variable
if [ -z "$GITHUB_PAT" ]; then
    read -sp "Enter your GitHub Personal Access Token: " github_token
    echo ""
else
    read -p "GitHub Personal Access Token found in environment. Do you want to use it? (y/n): " use_env_pat
    if [ "$use_env_pat" == "y" ]; then
        github_token=$GITHUB_PAT
    else
        read -sp "Enter your GitHub Personal Access Token: " github_token
        echo ""
    fi
fi

# Prompt for GitLab Personal Access Token (PAT)
read -sp "Enter your GitLab Personal Access Token: " gitlab_token
echo ""

# Prompt for GitHub user account
read -p "Enter your GitHub username: " github_user

# Prompt for GitHub repository details
read -p "Enter the new GitHub repository name: " new_repo_name
read -p "Enter a description for the GitHub repository: " repo_description
read -p "Should the repository be private? (y/n): " repo_private

# Convert 'y'/'n' input to true/false
if [ "$repo_private" == "y" ]; then
    private=true
else
    private=false
fi

# Check if the GitHub repository already exists
repo_check=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $github_token" \
    "https://api.github.com/repos/$github_user/$new_repo_name")

if [ "$repo_check" == "200" ]; then
    echo "Repository '$new_repo_name' already exists on GitHub."
    read -p "Do you want to (s)kip creating it, (o)verwrite it, or (a)bort the script? (s/o/a): " github_repo_action
    case "$github_repo_action" in
        s)
            echo "Skipping GitHub repository creation and proceeding..."
            ;;
        o)
            echo "Overwriting the existing repository on GitHub..."
            # Delete the existing GitHub repository
            delete_repo_response=$(curl -s -X DELETE -H "Authorization: token $github_token" \
                "https://api.github.com/repos/$github_user/$new_repo_name")

            if [ "$?" -ne 0 ]; then
                echo "Error: Failed to delete the existing repository on GitHub."
                exit 1
            fi

            # Recreate the GitHub repository
            create_repo_response=$(curl -s -H "Authorization: token $github_token" \
                -d "{\"name\": \"$new_repo_name\", \"description\": \"$repo_description\", \"private\": $private}" \
                https://api.github.com/user/repos)

            if echo "$create_repo_response" | grep -q '"full_name":'; then
                echo "Repository '$new_repo_name' recreated successfully on GitHub."
                github_url=$(echo "$create_repo_response" | grep -o '"clone_url": "[^"]*' | grep -o '[^"]*$')
            else
                echo "Error: Failed to recreate the repository on GitHub."
                echo "Response: $create_repo_response"
                exit 1
            fi
            ;;
        a)
            echo "Aborting the script."
            exit 1
            ;;
        *)
            echo "Invalid option. Aborting."
            exit 1
            ;;
    esac
else
    # Create the new GitHub repository using GitHub API
    echo "Creating the new repository on GitHub..."
    create_repo_response=$(curl -s -H "Authorization: token $github_token" \
        -d "{\"name\": \"$new_repo_name\", \"description\": \"$repo_description\", \"private\": $private}" \
        https://api.github.com/user/repos)

    # Check if the repository creation was successful
    if echo "$create_repo_response" | grep -q '"full_name":'; then
        echo "Repository '$new_repo_name' created successfully on GitHub."
        # Extract the new repository's clone URL
        github_url=$(echo "$create_repo_response" | grep -o '"clone_url": "[^"]*' | grep -o '[^"]*$')
    else
        echo "Error: Failed to create the repository on GitHub."
        echo "Response: $create_repo_response"
        exit 1
    fi
fi

# Modify the GitLab URL to include the GitLab PAT for authentication
if [[ "$gitlab_url" == http* ]]; then
    gitlab_url_with_token=$(echo "$gitlab_url" | sed "s#https://#https://oauth2:$gitlab_token@#")
elif [[ "$gitlab_url" == git@* ]]; then
    echo "SSH URL detected. Please ensure your SSH keys are set up correctly."
    gitlab_url_with_token="$gitlab_url"
else
    echo "Error: Unsupported GitLab URL format."
    exit 1
fi

# Clone the GitLab repository
echo "Cloning GitLab repository into '$repo_name'..."
git clone "$gitlab_url_with_token" "$repo_name"
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

echo "Migration complete!"
