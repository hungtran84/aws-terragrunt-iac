# Version Management Guide

This repository uses version pinning to ensure consistency across all environments and team members.

## Required Versions

- **Terraform**: `1.6.0` (see `.terraform-version`)
- **Terragrunt**: `0.55.0` (see `.terragrunt-version`)

## Version Files

This repository includes version specification files for different version managers:

- `.terraform-version` - For `tfenv` (Terraform version manager)
- `.terragrunt-version` - For `tgswitch` (Terragrunt version manager)
- `.tool-versions` - For `asdf` (universal version manager)

## Installation Methods

### Method 1: Using Version Managers (Recommended)

#### tfenv (Terraform Version Manager)

```bash
# Install tfenv
brew install tfenv  # macOS
# or
git clone https://github.com/tfutils/tfenv.git ~/.tfenv  # Linux
export PATH="$HOME/.tfenv/bin:$PATH"

# Install and use Terraform version
cd /path/to/aws-terragrunt-iac
tfenv install
tfenv use
```

#### tgswitch (Terragrunt Version Manager)

```bash
# Install tgswitch
brew install warrensbox/tap/tgswitch  # macOS
# or
curl -L https://raw.githubusercontent.com/warrensbox/tgswitch/release/install.sh | bash  # Linux

# Install and use Terragrunt version
cd /path/to/aws-terragrunt-iac
tgswitch install
tgswitch use
```

#### asdf (Universal Version Manager)

```bash
# Install asdf
brew install asdf  # macOS
# or
git clone https://github.com/asdf-vm/asdf.git ~/.asdf  # Linux

# Install Terraform and Terragrunt plugins
asdf plugin add terraform
asdf plugin add terragrunt https://github.com/ohmer/asdf-terragrunt.git

# Install versions
cd /path/to/aws-terragrunt-iac
asdf install
```

### Method 2: Manual Installation

If you prefer manual installation:

#### Terraform

```bash
# Download and install Terraform 1.6.0
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
chmod +x terraform
sudo mv terraform /usr/local/bin/
```

#### Terragrunt

```bash
# Download and install Terragrunt 0.55.0
wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.55.0/terragrunt_linux_amd64
chmod +x terragrunt_linux_amd64
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
```

## Verifying Versions

### Quick Check

```bash
terraform version
# Should show: Terraform v1.6.0

terragrunt version
# Should show: terragrunt version v0.55.0
```

### Using Version Check Script

This repository includes a version check script:

```bash
# Run the version checker
make check-versions
# or
./scripts/check-versions.sh
```

The script will:
- ✓ Check if Terraform and Terragrunt are installed
- ✓ Verify versions match requirements
- ✓ Provide installation instructions if versions don't match

## CI/CD Integration

### GitHub Actions

```yaml
name: Terraform and Terragrunt Setup

on: [push, pull_request]

jobs:
  setup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0
          
      - name: Setup Terragrunt
        run: |
          wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.55.0/terragrunt_linux_amd64
          chmod +x terragrunt_linux_amd64
          sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
          
      - name: Verify versions
        run: |
          terraform version
          terragrunt version
```

### GitLab CI

```yaml
image: alpine:latest

before_script:
  - apk add --no-cache curl unzip
  - |
    # Install Terraform
    wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
    unzip terraform_1.6.0_linux_amd64.zip
    mv terraform /usr/local/bin/
  - |
    # Install Terragrunt
    wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.55.0/terragrunt_linux_amd64
    chmod +x terragrunt_linux_amd64
    mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
```

## Pre-commit Hooks

This repository includes pre-commit hooks that automatically check versions:

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Now version checks run automatically on commit
```

## Updating Versions

When updating versions:

1. Update `.terraform-version` and `.terragrunt-version`
2. Update `.tool-versions` (if using asdf)
3. Update `README.md` Tech Stack section
4. Update `VERSION_MANAGEMENT.md` (this file)
5. Test with the version check script
6. Update CI/CD pipelines if needed

## Troubleshooting

### Version Mismatch Error

If you see version mismatch errors:

```bash
# Check current versions
terraform version
terragrunt version

# Use version manager to switch
tfenv use 1.6.0
tgswitch use 0.55.0
```

### Version Manager Not Working

If version managers aren't working:

1. Ensure version files are in the repository root
2. Check PATH includes version manager binaries
3. Verify version manager is installed correctly
4. Try manual installation as fallback

### CI/CD Version Issues

If CI/CD fails with version errors:

1. Check CI/CD configuration matches required versions
2. Verify download URLs are correct
3. Ensure proper permissions for installation
4. Check logs for specific error messages

## Best Practices

1. **Always use version managers** - Ensures consistency across team
2. **Check versions before work** - Run `make check-versions` before starting
3. **Update versions together** - Update Terraform and Terragrunt together when needed
4. **Document version changes** - Update documentation when versions change
5. **Test in CI/CD** - Ensure CI/CD uses same versions as local

