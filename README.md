# GitLab to GitHub Migration Script (`gitlab_to_github.sh`)

A bash script to seamlessly migrate repositories from **GitLab** to **GitHub**. This tool automates the process of cloning a GitLab repository and pushing it to a new repository on GitHub, preserving branches and tags.

## Features

- **Automated Git Installation**: Checks for Git and installs it if not present.
- **GitLab Repository Cloning**: Clones repositories from GitLab, including private ones using a Personal Access Token (PAT).
- **GitHub Repository Creation**: Creates a new repository on GitHub using the GitHub API.
- **Full Repository Migration**: Pushes all branches and tags to the new GitHub repository.
- **User-Friendly Prompts**: Guides you through each step with clear prompts and options.

## Prerequisites

- **Operating System**: Linux or macOS.
- **Bash Shell**: The script is written for bash.
- **Git**: The script checks for Git and can install it if necessary.
- **Curl**: Required for making API requests to GitHub.
- **Personal Access Tokens**:
  - **GitHub PAT**: Must have permissions to create repositories and push code (`repo` scope).
  - **GitLab PAT**: Required if cloning private repositories (with `read_repository` scope).

## Installation

You can run the script directly from GitHub using the following command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jnnngs/gitlab_to_github.sh/main/gitlab_to_github.sh)"
```

Alternatively, download the script manually:

1. **Download the Script**:

   ```bash
   curl -o gitlab_to_github.sh https://raw.githubusercontent.com/jnnngs/gitlab_to_github.sh/main/gitlab_to_github.sh
   ```

2. **Make it Executable**:

   ```bash
   chmod +x gitlab_to_github.sh
   ```

3. **Run the Script**:

   ```bash
   ./gitlab_to_github.sh
   ```

## Usage

When you run the script, it will prompt you for:

- **GitLab Repository URL**: The HTTPS or SSH URL of the GitLab repository you want to migrate.
- **GitHub Personal Access Token**: For authentication with GitHub's API.
- **GitLab Personal Access Token**: For cloning private repositories from GitLab.
- **GitHub Username**: Your GitHub username where the new repository will be created.
- **New GitHub Repository Name**: The name for your new repository on GitHub.
- **Repository Description**: A brief description of your repository.
- **Repository Privacy**: Option to make the new GitHub repository private or public.

### Example Session

```
Enter the GitLab repository URL: https://gitlab.com/username/old-repo.git
Enter your GitHub Personal Access Token: ********
Enter your GitLab Personal Access Token: ********
Enter your GitHub username: your-github-username
Enter the new GitHub repository name: new-repo
Enter a description for the GitHub repository: This is my migrated repository.
Should the repository be private? (y/n): y
```

### Notes on Prompts

- **Deleting Existing Directories**: If a directory with the same name as the repository exists locally, you'll be prompted to delete it or choose a different directory.
- **Handling Existing GitHub Repositories**: If a repository with the same name exists on GitHub, you can choose to skip creation, overwrite it, or abort the script.

## Permissions and Scopes

- **GitHub PAT**: Needs at least the `repo` scope to create repositories and push code.
- **GitLab PAT**: Needs the `read_repository` scope to clone private repositories.

## Important Considerations

- **Private Repositories**: The script supports migrating private repositories. Ensure your PATs have the necessary permissions.
- **SSH vs HTTPS**:
  - If using an **HTTPS URL**, the script modifies the URL to include your GitLab PAT for authentication.
  - If using an **SSH URL**, ensure your SSH keys are properly configured.
- **Migration Scope**: This script migrates the repository code, branches, and tags. It does **not** migrate issues, merge requests, wiki pages, or other metadata.

## Troubleshooting

- **Authentication Failures**: Double-check your PATs and ensure they have the correct scopes.
- **Permission Denied Errors**: Ensure you have the necessary permissions on both GitLab and GitHub.
- **Unsupported GitLab URL Format**: The script supports standard HTTPS and SSH URLs.

## Contributing

Contributions are welcome! If you find a bug or have a feature request, please open an issue or submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).

## Disclaimer

This script is provided "as is" without warranty of any kind. Use it at your own risk.
