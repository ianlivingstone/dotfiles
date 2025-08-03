# Global NPM Packages

This directory contains the configuration for global npm packages that should be available across all development environments.

## Usage

The `package.json` in this directory defines the global packages that will be automatically installed when you run:

```bash
dotfiles update
```

## Adding Packages

To add a new global package:

1. Edit `package.json` and add the package to the `dependencies` section
2. Commit the changes to the dotfiles repository
3. Run `dotfiles update` to install the new package
4. The package will be available on all machines after they pull and update

## Current Global Packages

- **@anthropic-ai/claude-code** - AI-powered coding assistant
- **npm-check-updates** - Update package.json dependencies to latest versions
- **http-server** - Simple HTTP server for local development
- **nodemon** - Monitor for file changes and restart applications
- **prettier** - Code formatter
- **eslint** - JavaScript/TypeScript linter  
- **typescript** - TypeScript compiler

## Package Versions

All packages are set to `"latest"` to ensure you always get the most current version when updating your environment.

## Manual Installation

If you need to install these packages manually:

```bash
cd npm-globals/
npm install -g $(jq -r '.dependencies | keys[]' package.json | tr '\n' ' ')
```