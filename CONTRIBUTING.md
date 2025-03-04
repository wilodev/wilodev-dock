# Contributing to WiloDev Dock

Thank you for considering contributing to WiloDev Dock! This document outlines the process for contributing to the project and helps ensure a smooth collaboration experience.

## Table of Contents

- [Contributing to WiloDev Dock](#contributing-to-wilodev-dock)
  - [Table of Contents](#table-of-contents)
  - [Code of Conduct](#code-of-conduct)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Setting Up Your Development Environment](#setting-up-your-development-environment)
  - [Development Workflow](#development-workflow)
  - [Pull Request Process](#pull-request-process)
    - [PR Review Criteria](#pr-review-criteria)
  - [Coding Standards](#coding-standards)
    - [Shell Scripts](#shell-scripts)
    - [YAML Configuration](#yaml-configuration)
    - [Directory Structure](#directory-structure)
  - [Testing](#testing)
  - [Documentation](#documentation)
  - [Community](#community)
  - [Recognition](#recognition)

## Code of Conduct

This project adheres to a Code of Conduct that sets the expectations for participation in our community. By participating, you are expected to uphold this code. Please read the [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) file for details.

> **Note for Image:** For a Code of Conduct illustration, you could use the prompt: "Create a simple, professional illustration representing community guidelines and code of conduct. Show diverse developers collaborating respectfully with symbols of inclusion and teamwork. Use a clean, modern style with blue and teal accents."

## Getting Started

### Prerequisites

Before you begin contributing, ensure you have:

- Docker Engine 20.10+
- Docker Compose 2.0+
- Git
- A GitHub account
- Basic knowledge of Docker, Bash, and YAML

### Setting Up Your Development Environment

1. Fork the repository on GitHub
2. Clone your fork locally:

   ```bash
   git clone https://github.com/YOUR-USERNAME/wilodev-dock.git
   cd wilodev-dock
   ```

3. Add the upstream repository as a remote:

   ```bash
   git remote add upstream https://github.com/wilodev/wilodev-dock.git
   ```

4. Create a branch for your work:

   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

1. Keep your fork updated with the upstream repository:

   ```bash
   git fetch upstream
   git merge upstream/main
   ```

2. Make your changes in your feature branch:
   - Follow the [coding standards](#coding-standards)
   - Keep commits focused and with clear messages
   - Reference issue numbers in commit messages when applicable

3. Test your changes thoroughly (see [Testing](#testing))

4. Document your changes (see [Documentation](#documentation))

## Pull Request Process

1. Update your fork with the latest upstream changes
2. Push your changes to your fork
3. Submit a pull request (PR) from your branch to the upstream's `main` branch
4. In your PR description:
   - Clearly describe the changes
   - Link to any related issues
   - Include screenshots if applicable
   - Complete the PR template
5. Participate in the code review process:
   - Be responsive to feedback
   - Make requested changes
   - Discuss alternatives when necessary

### PR Review Criteria

PRs are reviewed based on:

- Code quality and adherence to standards
- Functionality and reliability
- Security considerations
- Documentation completeness
- Test coverage

## Coding Standards

### Shell Scripts

- Use `#!/bin/bash` for shell scripts
- Include proper shebang and file header comments
- Use `set -euo pipefail` for safer script execution
- Format functions as:

  ```bash
  function_name() {
      # Function description
      local variable1="value"
      
      # Logic here
  }
  ```

- Use meaningful variable and function names
- Add comments for complex logic

### YAML Configuration

- Use 2-space indentation
- Include descriptive comments
- Group related configurations
- Use environment variables for configurable values
- Keep lines under 100 characters when possible

### Directory Structure

Maintain the established directory structure:

```bash
wilodev-dock/
├── docker-compose.yml
├── .env.example
├── setup.sh
├── traefik/
├── mysql/
├── mongo/
├── projects/
└── docs/
```

## Testing

Before submitting a PR, please test:

1. Full installation from scratch:

   ```bash
   ./setup.sh
   ```

2. Service functionality:
   - Traefik dashboard access
   - MySQL and MongoDB connectivity
   - MailHog email reception
   - Monitoring stack (if applicable)

3. Edge cases:
   - Installation on different operating systems
   - Various configurations via .env
   - Error handling and recovery

## Documentation

Document any changes you make:

1. Update the README.md if you change user-facing features
2. Update or create documentation in the docs/ directory
3. Include clear code comments
4. Update configuration examples if needed

Documentation should be:

- Clear and concise
- Accessible to users of all levels
- Available in English (Spanish translations are welcome)
- Properly formatted in Markdown

> **Note for Image:** For a documentation illustration, you could use the prompt: "Create a clean, minimalist illustration representing technical documentation. Show organized documents, code snippets, and diagrams with a focus on clarity and structure. Use a professional style with blue accents."

## Community

Stay connected with the WiloDev Dock community:

- Follow us on [GitHub](https://github.com/wilodev)
- Join our discussions in [GitHub Discussions](https://github.com/wilodev/wilodev-dock/discussions)
- Report bugs in [GitHub Issues](https://github.com/wilodev/wilodev-dock/issues)

## Recognition

Contributors are recognized in:

- The project's README
- Release notes
- The [CONTRIBUTORS.md](CONTRIBUTORS.md) file

Thank you for contributing to WiloDev Dock!
