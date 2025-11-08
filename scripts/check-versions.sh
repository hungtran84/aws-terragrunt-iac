#!/bin/bash
# Version checker script for Terraform and Terragrunt
# Ensures correct versions are installed before running Terragrunt commands
# Automatically installs Terragrunt if not available

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Required versions
REQUIRED_TERRAFORM_VERSION="1.6.0"
REQUIRED_TERRAGRUNT_VERSION="0.55.0"

# Detect OS and architecture
detect_os() {
    local os=""
    local arch=""
    
    case "$(uname -s)" in
        Darwin*)
            os="darwin"
            ;;
        Linux*)
            os="linux"
            ;;
        *)
            echo -e "${RED}Unsupported OS: $(uname -s)${NC}"
            exit 1
            ;;
    esac
    
    case "$(uname -m)" in
        x86_64|amd64)
            arch="amd64"
            ;;
        arm64|aarch64)
            arch="arm64"
            ;;
        *)
            echo -e "${RED}Unsupported architecture: $(uname -m)${NC}"
            exit 1
            ;;
    esac
    
    echo "${os}_${arch}"
}

# Install tfenv if not available
install_tfenv() {
    if command -v tfenv &> /dev/null; then
        return 0
    fi
    
    echo -e "${BLUE}tfenv is not available. Installing tfenv...${NC}"
    
    # Check if Homebrew is available (macOS)
    if command -v brew &> /dev/null; then
        # Check if terraform is installed and linked (conflicts with tfenv)
        # Always unlink terraform if it exists, as tfenv needs to manage terraform
        if brew list terraform &> /dev/null; then
            echo -e "${YELLOW}terraform is installed via Homebrew. Unlinking to avoid conflict with tfenv...${NC}"
            brew unlink terraform 2>/dev/null || true
            # Also check if it's still linked after unlinking
            if [ -L /opt/homebrew/bin/terraform ] || [ -L /usr/local/bin/terraform ]; then
                echo -e "${YELLOW}Removing terraform symlink...${NC}"
                rm -f /opt/homebrew/bin/terraform /usr/local/bin/terraform 2>/dev/null || true
            fi
        fi
        
        # Check if tfenv is installed but not linked
        if brew list tfenv &> /dev/null; then
            echo -e "${YELLOW}tfenv is installed but not linked. Uninstalling and reinstalling...${NC}"
            brew uninstall tfenv 2>/dev/null || true
        fi
        
        echo -e "${BLUE}Installing tfenv via Homebrew...${NC}"
        if brew install tfenv; then
            # Link tfenv with --overwrite to handle any conflicts
            if ! command -v tfenv &> /dev/null; then
                echo -e "${BLUE}Linking tfenv (this may overwrite terraform symlink)...${NC}"
                # Use --overwrite directly to handle terraform conflict
                if brew link --overwrite tfenv 2>/dev/null; then
                    echo -e "${GREEN}✓ tfenv linked successfully${NC}"
                else
                    echo -e "${YELLOW}Link failed, but tfenv may still be usable${NC}"
                fi
            fi
            
            # Verify installation
            if command -v tfenv &> /dev/null; then
                echo -e "${GREEN}✓ tfenv installed and linked successfully${NC}"
                return 0
            else
                # Try adding to PATH manually
                local tfenv_path=$(brew --prefix tfenv 2>/dev/null)/bin
                if [ -d "$tfenv_path" ]; then
                    export PATH="$tfenv_path:$PATH"
                    if command -v tfenv &> /dev/null; then
                        echo -e "${GREEN}✓ tfenv installed successfully${NC}"
                        echo -e "${YELLOW}Note: Added tfenv to PATH for this session${NC}"
                        return 0
                    fi
                fi
                echo -e "${RED}Failed to link tfenv. Please run: brew link --overwrite tfenv${NC}"
                return 1
            fi
        else
            return 1
        fi
    fi
    
    # Manual installation for Linux
    echo -e "${BLUE}Installing tfenv manually...${NC}"
    local tfenv_dir="$HOME/.tfenv"
    
    if [ -d "$tfenv_dir" ]; then
        echo -e "${YELLOW}tfenv directory already exists at $tfenv_dir${NC}"
    else
        git clone https://github.com/tfutils/tfenv.git "$tfenv_dir"
    fi
    
    # Add to PATH
    export PATH="$tfenv_dir/bin:$PATH"
    
    # Add to shell config if not already there
    local shell_config=""
    if [ -n "$ZSH_VERSION" ]; then
        shell_config="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_config="$HOME/.bashrc"
    fi
    
    if [ -n "$shell_config" ] && ! grep -q "tfenv/bin" "$shell_config" 2>/dev/null; then
        echo -e "${YELLOW}Adding tfenv to PATH in $shell_config${NC}"
        echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> "$shell_config"
    fi
    
    if command -v tfenv &> /dev/null; then
        echo -e "${GREEN}✓ tfenv installed successfully${NC}"
        return 0
    else
        echo -e "${RED}Failed to install tfenv${NC}"
        echo -e "${YELLOW}Please install tfenv manually or add $tfenv_dir/bin to your PATH${NC}"
        return 1
    fi
}

# Install Terraform using tfenv
install_terraform() {
    echo -e "${BLUE}Installing Terraform ${REQUIRED_TERRAFORM_VERSION} using tfenv...${NC}"
    
    # Install tfenv if not available
    if ! install_tfenv; then
        return 1
    fi
    
    # Ensure tfenv is in PATH
    if ! command -v tfenv &> /dev/null; then
        export PATH="$HOME/.tfenv/bin:$PATH"
    fi
    
    # Install the required version
    echo -e "${BLUE}Installing Terraform ${REQUIRED_TERRAFORM_VERSION}...${NC}"
    if tfenv install "$REQUIRED_TERRAFORM_VERSION"; then
        echo -e "${GREEN}✓ Terraform ${REQUIRED_TERRAFORM_VERSION} installed${NC}"
    else
        echo -e "${RED}Failed to install Terraform ${REQUIRED_TERRAFORM_VERSION}${NC}"
        return 1
    fi
    
    # Switch to the required version
    echo -e "${BLUE}Switching to Terraform ${REQUIRED_TERRAFORM_VERSION}...${NC}"
    if tfenv use "$REQUIRED_TERRAFORM_VERSION"; then
        echo -e "${GREEN}✓ Switched to Terraform ${REQUIRED_TERRAFORM_VERSION}${NC}"
        
        # Verify installation
        if command -v terraform &> /dev/null; then
            local installed_version
            if command -v jq &> /dev/null; then
                installed_version=$(terraform version -json | jq -r '.terraform_version')
            else
                installed_version=$(terraform version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
            fi
            
            if [ "$installed_version" == "$REQUIRED_TERRAFORM_VERSION" ]; then
                echo -e "${GREEN}✓ Terraform installation verified (version $installed_version)${NC}"
                return 0
            else
                echo -e "${YELLOW}Warning: Terraform version mismatch. Installed: $installed_version, Required: $REQUIRED_TERRAFORM_VERSION${NC}"
                return 1
            fi
        else
            echo -e "${YELLOW}Note: Terraform installed but not in PATH. Please restart your shell.${NC}"
            return 1
        fi
    else
        echo -e "${RED}Failed to switch to Terraform ${REQUIRED_TERRAFORM_VERSION}${NC}"
        return 1
    fi
}

# Install Terragrunt
install_terragrunt() {
    local os_arch=$(detect_os)
    local download_url="https://github.com/gruntwork-io/terragrunt/releases/download/v${REQUIRED_TERRAGRUNT_VERSION}/terragrunt_${os_arch}"
    local install_dir="/usr/local/bin"
    local temp_file="/tmp/terragrunt_${os_arch}"
    
    echo -e "${BLUE}Installing Terragrunt ${REQUIRED_TERRAGRUNT_VERSION}...${NC}"
    
    # Check if we have write permissions to /usr/local/bin
    if [ ! -w "$install_dir" ]; then
        echo -e "${YELLOW}Note: sudo may be required to install to $install_dir${NC}"
        echo -e "${BLUE}Downloading Terragrunt...${NC}"
        
        if command -v curl &> /dev/null; then
            curl -L -o "$temp_file" "$download_url"
        elif command -v wget &> /dev/null; then
            wget -O "$temp_file" "$download_url"
        else
            echo -e "${RED}Error: Neither curl nor wget is available${NC}"
            return 1
        fi
        
        chmod +x "$temp_file"
        
        # Try to move to /usr/local/bin (may require sudo)
        if sudo mv "$temp_file" "$install_dir/terragrunt" 2>/dev/null; then
            echo -e "${GREEN}✓ Terragrunt installed to $install_dir/terragrunt${NC}"
        else
            # Try without sudo (user may have permissions)
            if mv "$temp_file" "$install_dir/terragrunt" 2>/dev/null; then
                echo -e "${GREEN}✓ Terragrunt installed to $install_dir/terragrunt${NC}"
            else
                # Install to local bin directory
                local local_bin="$HOME/.local/bin"
                mkdir -p "$local_bin"
                mv "$temp_file" "$local_bin/terragrunt"
                echo -e "${GREEN}✓ Terragrunt installed to $local_bin/terragrunt${NC}"
                echo -e "${YELLOW}Please add $local_bin to your PATH:${NC}"
                echo -e "  export PATH=\"\$PATH:$local_bin\""
                echo -e "  Add this to your ~/.bashrc, ~/.zshrc, or ~/.profile"
            fi
        fi
    else
        # We have write permissions, install directly
        if command -v curl &> /dev/null; then
            curl -L -o "$temp_file" "$download_url"
        elif command -v wget &> /dev/null; then
            wget -O "$temp_file" "$download_url"
        else
            echo -e "${RED}Error: Neither curl nor wget is available${NC}"
            return 1
        fi
        
        chmod +x "$temp_file"
        mv "$temp_file" "$install_dir/terragrunt"
        echo -e "${GREEN}✓ Terragrunt installed to $install_dir/terragrunt${NC}"
    fi
    
    # Verify installation
    if command -v terragrunt &> /dev/null; then
        echo -e "${GREEN}✓ Terragrunt installation verified${NC}"
        return 0
    else
        echo -e "${YELLOW}Note: Terragrunt installed but not in PATH. Please restart your shell or add to PATH.${NC}"
        return 1
    fi
}

# Function to check version
check_version() {
    local tool=$1
    local required_version=$2
    local current_version
    local auto_install=${3:-false}
    local original_dir=$(pwd)
    
    # For terragrunt, change to a temp directory to avoid parsing config files
    if [ "$tool" == "terragrunt" ]; then
        local temp_dir=$(mktemp -d)
        cd "$temp_dir" 2>/dev/null || true
    fi
    
    if ! command -v $tool &> /dev/null; then
        if [ "$tool" == "terragrunt" ]; then
            cd "$original_dir" 2>/dev/null || true
            rm -rf "$temp_dir" 2>/dev/null || true
        fi
        echo -e "${RED}✗ $tool is not installed${NC}"
        
        # Auto-install if requested
        if [ "$auto_install" == "true" ]; then
            if [ "$tool" == "terraform" ]; then
                echo -e "${YELLOW}Attempting to install Terraform automatically using tfenv...${NC}"
                if install_terraform; then
                    # Re-check after installation
                    if command -v $tool &> /dev/null; then
                        echo -e "${GREEN}✓ $tool installed successfully${NC}"
                    else
                        echo -e "${YELLOW}Note: $tool was installed but may not be in PATH. Please restart your shell.${NC}"
                        return 1
                    fi
                else
                    echo -e "${RED}Failed to install $tool automatically${NC}"
                    return 1
                fi
            elif [ "$tool" == "terragrunt" ]; then
                echo -e "${YELLOW}Attempting to install Terragrunt automatically...${NC}"
                if install_terragrunt; then
                    # Re-check after installation
                    if command -v $tool &> /dev/null; then
                        echo -e "${GREEN}✓ $tool installed successfully${NC}"
                    else
                        echo -e "${YELLOW}Note: $tool was installed but may not be in PATH. Please restart your shell.${NC}"
                        return 1
                    fi
                else
                    echo -e "${RED}Failed to install $tool automatically${NC}"
                    return 1
                fi
            else
                return 1
            fi
        else
            return 1
        fi
    fi
    
    if [ "$tool" == "terraform" ]; then
        if command -v jq &> /dev/null; then
            current_version=$(terraform version -json 2>/dev/null | jq -r '.terraform_version')
        else
            current_version=$(terraform version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        fi
    elif [ "$tool" == "terragrunt" ]; then
        # Get version without parsing config files
        # Try --version first (doesn't parse config), fallback to version command
        current_version=$(terragrunt --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed 's/v//' || \
                         terragrunt version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed 's/v//' || \
                         echo "")
    fi
    
    # Return to original directory for terragrunt
    if [ "$tool" == "terragrunt" ]; then
        cd "$original_dir" 2>/dev/null || true
        rm -rf "$temp_dir" 2>/dev/null || true
    fi
    
    if [ "$current_version" == "$required_version" ]; then
        echo -e "${GREEN}✓ $tool version $current_version is correct${NC}"
        return 0
    else
        echo -e "${RED}✗ $tool version mismatch${NC}"
        echo -e "  Required: $required_version"
        echo -e "  Current:  $current_version"
        
        # Auto-install/switch if requested
        if [ "$auto_install" == "true" ]; then
            if [ "$tool" == "terraform" ]; then
                echo -e "${YELLOW}Switching to Terraform ${required_version} using tfenv...${NC}"
                # Install tfenv if not available
                if ! install_tfenv; then
                    echo -e "${RED}Failed to install tfenv${NC}"
                    return 1
                fi
                
                # Ensure tfenv is in PATH
                if ! command -v tfenv &> /dev/null; then
                    export PATH="$HOME/.tfenv/bin:$PATH"
                fi
                
                # Install the required version if not already installed
                if ! tfenv list 2>/dev/null | grep -q "$required_version"; then
                    echo -e "${BLUE}Installing Terraform ${required_version}...${NC}"
                    if ! tfenv install "$required_version"; then
                        echo -e "${RED}Failed to install Terraform ${required_version}${NC}"
                        return 1
                    fi
                fi
                
                # Switch to the required version
                echo -e "${BLUE}Switching to Terraform ${required_version}...${NC}"
                if tfenv use "$required_version"; then
                    echo -e "${GREEN}✓ Switched to Terraform ${required_version}${NC}"
                    return 0
                else
                    echo -e "${RED}Failed to switch to Terraform ${required_version}${NC}"
                    return 1
                fi
            elif [ "$tool" == "terragrunt" ]; then
                echo -e "${YELLOW}Reinstalling Terragrunt ${required_version}...${NC}"
                if install_terragrunt; then
                    return 0
                else
                    return 1
                fi
            fi
        else
            echo -e "${YELLOW}Please install the correct version:${NC}"
            if [ "$tool" == "terraform" ]; then
                echo -e "  Run with --auto-install to switch automatically:"
                echo -e "  ./scripts/check-versions.sh --auto-install"
                echo -e ""
                echo -e "  Or switch manually:"
                echo -e "  tfenv install $required_version && tfenv use $required_version"
            elif [ "$tool" == "terragrunt" ]; then
                echo -e "  Run with --auto-install to install automatically:"
                echo -e "  ./scripts/check-versions.sh --auto-install"
                echo -e ""
                echo -e "  Or install manually:"
                echo -e "  tgswitch install $required_version && tgswitch use $required_version"
            fi
            return 1
        fi
    fi
}

# Check if auto-install is requested
AUTO_INSTALL=${AUTO_INSTALL:-false}
if [ "$1" == "--auto-install" ] || [ "$1" == "-a" ]; then
    AUTO_INSTALL=true
fi

# Check versions
echo "Checking required tool versions..."
echo ""

TERRAFORM_OK=false
TERRAGRUNT_OK=false

if check_version "terraform" "$REQUIRED_TERRAFORM_VERSION" "$AUTO_INSTALL"; then
    TERRAFORM_OK=true
fi

if check_version "terragrunt" "$REQUIRED_TERRAGRUNT_VERSION" "$AUTO_INSTALL"; then
    TERRAGRUNT_OK=true
fi

echo ""

if [ "$TERRAFORM_OK" = true ] && [ "$TERRAGRUNT_OK" = true ]; then
    echo -e "${GREEN}All versions are correct! ✓${NC}"
    exit 0
else
    echo -e "${RED}Version check failed.${NC}"
    if [ "$AUTO_INSTALL" != "true" ]; then
        echo -e "${YELLOW}Tip: Run with --auto-install to automatically install missing tools:${NC}"
        echo -e "  ./scripts/check-versions.sh --auto-install"
    fi
    exit 1
fi

