#!/bin/bash

# git-repo-installer.sh
# Script to list GitHub repositories, clone a selected one, and optionally run Docker

# ANSI color codes for better user interface
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Banner function
show_banner() {
    echo -e "${BLUE}"
    echo "  _____  _  _      _____                       _____            _             _  _               "
    echo " / ____|| |(_)    |  __ \\                     |_   _|          | |           | || |              "
    echo "| |  __ | | _  ___| |__) |  ___  _ __   ___     | |   _ __  ___| |_   __   _ | || |  ___  _ __  "
    echo "| | |_ || || |/ __|  _  /  / _ \\| '_ \\ / _ \\    | |  | '__|/ __| __| / _\\ | || || |/ _ \\| '__|"
    echo "| |__| || || |\\__ \\ | \\ \\ |  __/| |_) | (_) |  _| |_ | |  | (__| |_ | (_| || || ||  __/| |    "
    echo " \\_____||_||_||___/_|  \\_\\ \\___|| .__/ \\___/  |_____||_|   \\___|\\__| \\__,_||_||_| \\___||_|    "
    echo "                                 | |                                                              "
    echo "                                 |_|                                                              "
    echo -e "${NC}"
}

# Function to detect package manager
detect_package_manager() {
    if command -v apt &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    elif command -v brew &> /dev/null; then
        echo "brew"
    else
        echo "unknown"
    fi
}

# Function to install missing tools
install_missing_tools() {
    local tools=("$@")
    local package_manager=$(detect_package_manager)
    
    echo -e "${YELLOW}Attempting to install missing tools using $package_manager...${NC}"
    
    if [ "$package_manager" = "unknown" ]; then
        echo -e "${RED}Could not detect package manager. Please install the missing tools manually.${NC}"
        return 1
    fi
    
    case "$package_manager" in
        apt)
            echo -e "${BLUE}Updating package lists...${NC}"
            sudo apt update -y
            
            for tool in "${tools[@]}"; do
                case "$tool" in
                    jq)
                        echo -e "${BLUE}Installing jq...${NC}"
                        sudo apt install -y jq
                        ;;
                    docker)
                        echo -e "${BLUE}Installing Docker...${NC}"
                        sudo apt install -y docker.io
                        sudo systemctl enable --now docker
                        ;;
                    docker-compose)
                        echo -e "${BLUE}Installing Docker Compose...${NC}"
                        sudo apt install -y docker-compose
                        ;;
                    *)
                        echo -e "${YELLOW}No predefined installation method for $tool with apt.${NC}"
                        ;;
                esac
            done
            ;;
        dnf|yum)
            local pm=$package_manager
            echo -e "${BLUE}Updating package lists...${NC}"
            sudo $pm check-update -y
            
            for tool in "${tools[@]}"; do
                case "$tool" in
                    jq)
                        echo -e "${BLUE}Installing jq...${NC}"
                        sudo $pm install -y jq
                        ;;
                    docker)
                        echo -e "${BLUE}Installing Docker...${NC}"
                        sudo $pm install -y docker
                        sudo systemctl enable --now docker
                        ;;
                    docker-compose)
                        echo -e "${BLUE}Installing Docker Compose...${NC}"
                        sudo $pm install -y docker-compose
                        ;;
                    *)
                        echo -e "${YELLOW}No predefined installation method for $tool with $pm.${NC}"
                        ;;
                esac
            done
            ;;
        pacman)
            echo -e "${BLUE}Updating package lists...${NC}"
            sudo pacman -Sy
            
            for tool in "${tools[@]}"; do
                case "$tool" in
                    jq)
                        echo -e "${BLUE}Installing jq...${NC}"
                        sudo pacman -S --noconfirm jq
                        ;;
                    docker)
                        echo -e "${BLUE}Installing Docker...${NC}"
                        sudo pacman -S --noconfirm docker
                        sudo systemctl enable --now docker
                        ;;
                    docker-compose)
                        echo -e "${BLUE}Installing Docker Compose...${NC}"
                        sudo pacman -S --noconfirm docker-compose
                        ;;
                    *)
                        echo -e "${YELLOW}No predefined installation method for $tool with pacman.${NC}"
                        ;;
                esac
            done
            ;;
        brew)
            echo -e "${BLUE}Updating Homebrew...${NC}"
            brew update
            
            for tool in "${tools[@]}"; do
                case "$tool" in
                    jq)
                        echo -e "${BLUE}Installing jq...${NC}"
                        brew install jq
                        ;;
                    docker)
                        echo -e "${BLUE}Installing Docker...${NC}"
                        echo -e "${YELLOW}Docker Desktop should be installed manually on macOS.${NC}"
                        echo -e "${YELLOW}Visit https://docs.docker.com/desktop/mac/install/${NC}"
                        ;;
                    docker-compose)
                        echo -e "${BLUE}Installing Docker Compose...${NC}"
                        brew install docker-compose
                        ;;
                    *)
                        echo -e "${YELLOW}No predefined installation method for $tool with Homebrew.${NC}"
                        ;;
                esac
            done
            ;;
        zypper)
            echo -e "${BLUE}Updating package lists...${NC}"
            sudo zypper refresh
            
            for tool in "${tools[@]}"; do
                case "$tool" in
                    jq)
                        echo -e "${BLUE}Installing jq...${NC}"
                        sudo zypper install -y jq
                        ;;
                    docker)
                        echo -e "${BLUE}Installing Docker...${NC}"
                        sudo zypper install -y docker
                        sudo systemctl enable --now docker
                        ;;
                    docker-compose)
                        echo -e "${BLUE}Installing Docker Compose...${NC}"
                        sudo zypper install -y docker-compose
                        ;;
                    *)
                        echo -e "${YELLOW}No predefined installation method for $tool with zypper.${NC}"
                        ;;
                esac
            done
            ;;
        *)
            echo -e "${RED}Unsupported package manager: $package_manager${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}Installation completed. Verifying tools...${NC}"
    return 0
}

# Function to check if required commands are available
check_requirements() {
    local missing_tools=()
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi
    
    # Check for jq
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
    fi
    
    # Check for docker
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi
    
    # Check for docker-compose (both traditional and plugin versions)
    if ! command -v docker-compose &> /dev/null; then
        if ! docker compose version &> /dev/null; then
            missing_tools+=("docker-compose")
        else
            echo -e "${GREEN}Found Docker Compose plugin (docker compose).${NC}"
        fi
    else
        echo -e "${GREEN}Found standalone docker-compose.${NC}"
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "${YELLOW}The following required tools are missing:${NC}"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        
        read -p "Do you want to attempt automatic installation of missing tools? [y/N] " INSTALL_TOOLS
        
        if [[ "$INSTALL_TOOLS" =~ ^[Yy]$ ]]; then
            install_missing_tools "${missing_tools[@]}"
            if [ $? -ne 0 ]; then
                echo -e "${RED}Installation failed.${NC}"
                echo -e "${YELLOW}Please install these tools manually before running this script.${NC}"
                exit 1
            fi
            
            # Verify installation success
            still_missing=false
            for tool in "${missing_tools[@]}"; do
                if [ "$tool" = "docker-compose" ]; then
                    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
                        echo -e "${RED}Error: $tool is still missing after installation attempt.${NC}"
                        still_missing=true
                    fi
                elif ! command -v $tool &> /dev/null; then
                    echo -e "${RED}Error: $tool is still missing after installation attempt.${NC}"
                    still_missing=true
                fi
            done
            
            if [ "$still_missing" = true ]; then
                echo -e "${YELLOW}Please install missing tools manually before running this script.${NC}"
                exit 1
            else
                echo -e "${GREEN}All required tools are now available.${NC}"
            fi
        else
            echo -e "${YELLOW}Please install these tools before running this script.${NC}"
            exit 1
        fi
    fi
}

# Function to read GitHub token from .env file
read_github_token() {
    if [ ! -f .env ]; then
        echo -e "${RED}Error: .env file not found.${NC}"
        echo -e "${YELLOW}Please create a .env file with GITHUB_TOKEN=your_token${NC}"
        exit 1
    fi
    
    # Using grep to extract the GITHUB_TOKEN from .env file
    GITHUB_TOKEN=$(grep -oP 'GITHUB_TOKEN=\K[^\s]+' .env)
    
    if [ -z "$GITHUB_TOKEN" ]; then
        echo -e "${RED}Error: GITHUB_TOKEN not found in .env file.${NC}"
        echo -e "${YELLOW}Please add GITHUB_TOKEN=your_token to your .env file.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}GitHub token found in .env file.${NC}"
}

# Function to fetch a list of organizations the user belongs to
fetch_organizations() {
    echo -e "${BLUE}Fetching organizations you have access to...${NC}"
    
    # Fetch organizations from GitHub API
    ORGS_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                  "https://api.github.com/user/orgs?per_page=100")
    
    # Check if the response contains an error message
    ERROR_MESSAGE=$(echo "$ORGS_RESPONSE" | jq -r '.message // empty')
    if [ ! -z "$ERROR_MESSAGE" ]; then
        echo -e "${RED}Error from GitHub API: $ERROR_MESSAGE${NC}"
        return 1
    fi
    
    # Extract organization information
    ORGS=$(echo "$ORGS_RESPONSE" | jq -r '.[] | "\(.login)|\(.description // "No description")"')
    
    if [ -z "$ORGS" ]; then
        echo -e "${YELLOW}No organizations found. You can only access your personal repositories.${NC}"
        ORGANIZATION=""
        return 1
    fi
    
    # Convert to array
    IFS=$'\n' read -d '' -ra ORG_ARRAY <<< "$ORGS"
    
    echo -e "${GREEN}Found ${#ORG_ARRAY[@]} organizations.${NC}"
    return 0
}

# Function to display organizations and get user selection
select_organization() {
    echo -e "${BLUE}Organizations you have access to:${NC}"
    echo "-----------------------------------------------------"
    
    # Add option for personal repositories
    echo -e "${YELLOW}0.${NC} ${GREEN}Personal repositories${NC}"
    echo "   Your personal GitHub repositories"
    echo "-----------------------------------------------------"
    
    for i in "${!ORG_ARRAY[@]}"; do
        local org_info=(${ORG_ARRAY[$i]//|/ })
        local org_name=${org_info[0]}
        local org_desc="${ORG_ARRAY[$i]#*|}"
        
        echo -e "${YELLOW}$((i+1)).${NC} ${GREEN}$org_name${NC}"
        if [ "$org_desc" != "No description" ]; then
            echo "   $org_desc"
        fi
        echo "-----------------------------------------------------"
    done
    
    read -p "Enter the number of the organization (0-${#ORG_ARRAY[@]}): " ORG_INDEX
    
    # Validate input
    if ! [[ "$ORG_INDEX" =~ ^[0-9]+$ ]] || [ "$ORG_INDEX" -lt 0 ] || [ "$ORG_INDEX" -gt "${#ORG_ARRAY[@]}" ]; then
        echo -e "${RED}Error: Invalid selection.${NC}"
        exit 1
    fi
    
    # Option 0 is for personal repositories
    if [ "$ORG_INDEX" -eq 0 ]; then
        ORGANIZATION=""
        echo -e "${GREEN}Selected: Personal repositories${NC}"
    else
        # Get the selected organization name
        SELECTED_ORG_INFO=${ORG_ARRAY[$((ORG_INDEX-1))]}
        ORGANIZATION=${SELECTED_ORG_INFO%%|*}
        echo -e "${GREEN}Selected organization: $ORGANIZATION${NC}"
    fi
}

# Function to get organization name (optional)
get_organization() {
    echo -e "${BLUE}Do you want to list repositories from:${NC}"
    echo "1. Your personal repositories"
    echo "2. An organization"
    
    read -p "Enter choice [1/2]: " org_choice
    
    if [[ "$org_choice" == "2" ]]; then
        # Try to fetch organizations
        if fetch_organizations; then
            # If organizations were found, let the user select one
            select_organization
        else
            # If no organizations were found or there was an error, 
            # fall back to manual entry
            if [ -z "$ORGANIZATION" ]; then
                echo -e "${YELLOW}Enter the organization name manually:${NC}"
                read -p "Organization name: " ORGANIZATION
                if [ -z "$ORGANIZATION" ]; then
                    echo -e "${YELLOW}No organization specified, falling back to personal repositories.${NC}"
                else
                    echo -e "${GREEN}Will list repositories from organization: ${ORGANIZATION}${NC}"
                fi
            fi
        fi
    else
        ORGANIZATION=""
        echo -e "${GREEN}Will list your personal repositories.${NC}"
    fi
}

# Function to fetch repositories from GitHub using the token
fetch_repositories() {
    echo -e "${BLUE}Fetching repositories from GitHub...${NC}"
    
    if [ -z "$ORGANIZATION" ]; then
        # Fetch user's repositories
        RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                  "https://api.github.com/user/repos?sort=updated&per_page=100")
    else
        # Fetch organization's repositories
        RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                  "https://api.github.com/orgs/$ORGANIZATION/repos?sort=updated&per_page=100")
    fi
    
    # Check if the response contains an error message
    ERROR_MESSAGE=$(echo "$RESPONSE" | jq -r '.message // empty')
    if [ ! -z "$ERROR_MESSAGE" ]; then
        echo -e "${RED}Error from GitHub API: $ERROR_MESSAGE${NC}"
        exit 1
    fi
    
    # Extract repository information
    REPOS=$(echo "$RESPONSE" | jq -r '.[] | "\(.name)|\(.description // "No description")"')
    
    if [ -z "$REPOS" ]; then
        echo -e "${RED}No repositories found.${NC}"
        exit 1
    fi
    
    # Convert to array
    IFS=$'\n' read -d '' -ra REPO_ARRAY <<< "$REPOS"
    
    echo -e "${GREEN}Found ${#REPO_ARRAY[@]} repositories.${NC}"
}

# Function to display repositories and get user selection
select_repository() {
    echo -e "${BLUE}Available repositories:${NC}"
    echo "-----------------------------------------------------"
    
    for i in "${!REPO_ARRAY[@]}"; do
        local repo_info=(${REPO_ARRAY[$i]//|/ })
        local repo_name=${repo_info[0]}
        local repo_desc="${REPO_ARRAY[$i]#*|}"
        
        echo -e "${YELLOW}$((i+1)).${NC} ${GREEN}$repo_name${NC}"
        echo "   $repo_desc"
        echo "-----------------------------------------------------"
    done
    
    read -p "Enter the number of the repository to clone (1-${#REPO_ARRAY[@]}): " REPO_INDEX
    
    # Validate input
    if ! [[ "$REPO_INDEX" =~ ^[0-9]+$ ]] || [ "$REPO_INDEX" -lt 1 ] || [ "$REPO_INDEX" -gt "${#REPO_ARRAY[@]}" ]; then
        echo -e "${RED}Error: Invalid selection.${NC}"
        exit 1
    fi
    
    # Get the selected repository name
    SELECTED_REPO_INFO=${REPO_ARRAY[$((REPO_INDEX-1))]}
    SELECTED_REPO=${SELECTED_REPO_INFO%%|*}
    
    echo -e "${GREEN}Selected repository: $SELECTED_REPO${NC}"
}

# Function to prompt for the target directory
get_target_directory() {
    echo -e "${BLUE}Where would you like to clone the repository?${NC}"
    echo -e "Press Enter to use current directory ($(pwd)) or specify a path:"
    read TARGET_DIR
    
    if [ -z "$TARGET_DIR" ]; then
        TARGET_DIR=$(pwd)
        echo -e "${GREEN}Using current directory: $TARGET_DIR${NC}"
    else
        # Expand the path if it starts with ~
        TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
        
        # Create directory if it doesn't exist
        if [ ! -d "$TARGET_DIR" ]; then
            read -p "Directory '$TARGET_DIR' doesn't exist. Create it? [Y/n] " CREATE_DIR
            if [[ "$CREATE_DIR" =~ ^[Nn]$ ]]; then
                echo -e "${RED}Aborted.${NC}"
                exit 1
            else
                mkdir -p "$TARGET_DIR"
                if [ $? -ne 0 ]; then
                    echo -e "${RED}Error: Failed to create directory.${NC}"
                    exit 1
                fi
                echo -e "${GREEN}Created directory: $TARGET_DIR${NC}"
            fi
        fi
    fi
    
    # Check if the target directory already contains the repository
    if [ -d "$TARGET_DIR/$SELECTED_REPO" ]; then
        read -p "Directory '$TARGET_DIR/$SELECTED_REPO' already exists. Overwrite? [y/N] " OVERWRITE
        if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
            echo -e "${RED}Aborted.${NC}"
            exit 1
        else
            echo -e "${YELLOW}Warning: Existing repository will be overwritten.${NC}"
        fi
    fi
}

# Function to clone the repository
clone_repository() {
    echo -e "${BLUE}Cloning repository...${NC}"
    
    # Construct the repository URL
    if [ -z "$ORGANIZATION" ]; then
        # Get the username from GitHub API
        USERNAME=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                  "https://api.github.com/user" | jq -r '.login')
        REPO_URL="https://${GITHUB_TOKEN}@github.com/${USERNAME}/${SELECTED_REPO}.git"
    else
        REPO_URL="https://${GITHUB_TOKEN}@github.com/${ORGANIZATION}/${SELECTED_REPO}.git"
    fi
    
    # Clone the repository (hide output with token)
    echo -e "Running: git clone [HIDDEN_URL] \"$TARGET_DIR/$SELECTED_REPO\""
    if [ -d "$TARGET_DIR/$SELECTED_REPO" ]; then
        rm -rf "$TARGET_DIR/$SELECTED_REPO"
    fi
    
    git clone "$REPO_URL" "$TARGET_DIR/$SELECTED_REPO" 2>&1 | sed "s/$GITHUB_TOKEN/[HIDDEN_TOKEN]/g"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to clone repository.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Repository cloned successfully to: $TARGET_DIR/$SELECTED_REPO${NC}"
    REPO_DIR="$TARGET_DIR/$SELECTED_REPO"
}

# Function to check for and install dependencies
check_dependencies() {
    echo -e "${BLUE}Checking for dependency files...${NC}"
    
    cd "$REPO_DIR"
    local found_dependencies=false
    local python_deps=false
    local node_deps=false
    
    # Check for Python requirements
    if [ -f "requirements.txt" ]; then
        echo -e "${GREEN}Found Python requirements.txt file.${NC}"
        python_deps=true
        found_dependencies=true
    fi
    
    # Check for pip-requirements.txt
    if [ -f "pip-requirements.txt" ]; then
        echo -e "${GREEN}Found pip-requirements.txt file.${NC}"
        python_deps=true
        found_dependencies=true
    fi
    
    # Check for Node.js dependencies
    if [ -f "package.json" ]; then
        echo -e "${GREEN}Found Node.js package.json file.${NC}"
        node_deps=true
        found_dependencies=true
    fi
    
    # Check for other common dependency files
    if [ -f "Gemfile" ]; then
        echo -e "${GREEN}Found Ruby Gemfile.${NC}"
        found_dependencies=true
    fi
    
    if [ -f "composer.json" ]; then
        echo -e "${GREEN}Found PHP composer.json file.${NC}"
        found_dependencies=true
    fi
    
    if [ -f "go.mod" ]; then
        echo -e "${GREEN}Found Go module file.${NC}"
        found_dependencies=true
    fi
    
    # If any dependencies were found, ask if user wants to install them
    if [ "$found_dependencies" = true ]; then
        read -p "Do you want to install the dependencies before starting Docker? [y/N] " INSTALL_DEPS
        
        if [[ "$INSTALL_DEPS" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Installing dependencies...${NC}"
            
            # Install Python dependencies
            if [ "$python_deps" = true ]; then
                echo -e "${BLUE}Installing Python dependencies...${NC}"
                
                # Check if python or python3 is available
                local python_cmd=""
                if command -v python3 &> /dev/null; then
                    python_cmd="python3"
                elif command -v python &> /dev/null; then
                    python_cmd="python"
                else
                    echo -e "${YELLOW}Python not found. Skipping Python dependencies.${NC}"
                    python_cmd=""
                fi
                
                if [ ! -z "$python_cmd" ]; then
                    # Check if pip is available
                    local pip_cmd=""
                    if command -v pip3 &> /dev/null; then
                        pip_cmd="pip3"
                    elif command -v pip &> /dev/null; then
                        pip_cmd="pip"
                    else
                        echo -e "${YELLOW}pip not found. Attempting to install it...${NC}"
                        if [ "$python_cmd" = "python3" ]; then
                            package_manager=$(detect_package_manager)
                            case "$package_manager" in
                                apt)
                                    sudo apt install -y python3-pip
                                    ;;
                                dnf|yum)
                                    sudo $package_manager install -y python3-pip
                                    ;;
                                pacman)
                                    sudo pacman -S --noconfirm python-pip
                                    ;;
                                brew)
                                    brew install python
                                    ;;
                                zypper)
                                    sudo zypper install -y python3-pip
                                    ;;
                                *)
                                    echo -e "${RED}Could not install pip. Please install it manually.${NC}"
                                    ;;
                            esac
                            
                            if command -v pip3 &> /dev/null; then
                                pip_cmd="pip3"
                            elif command -v pip &> /dev/null; then
                                pip_cmd="pip"
                            fi
                        fi
                    fi
                    
                    if [ ! -z "$pip_cmd" ]; then
                        # Install requirements
                        if [ -f "requirements.txt" ]; then
                            echo -e "${BLUE}Installing from requirements.txt...${NC}"
                            $pip_cmd install -r requirements.txt
                        fi
                        
                        if [ -f "pip-requirements.txt" ]; then
                            echo -e "${BLUE}Installing from pip-requirements.txt...${NC}"
                            $pip_cmd install -r pip-requirements.txt
                        fi
                    else
                        echo -e "${YELLOW}pip not available. Skipping Python dependencies.${NC}"
                    fi
                fi
            fi
            
            # Install Node.js dependencies
            if [ "$node_deps" = true ]; then
                echo -e "${BLUE}Installing Node.js dependencies...${NC}"
                
                # Check if npm is available
                if command -v npm &> /dev/null; then
                    npm install
                elif command -v yarn &> /dev/null; then
                    echo -e "${BLUE}Using yarn instead of npm...${NC}"
                    yarn install
                else
                    echo -e "${YELLOW}npm or yarn not found. Skipping Node.js dependencies.${NC}"
                fi
            fi
            
            # Handle other dependency managers based on found files
            if [ -f "Gemfile" ] && command -v bundle &> /dev/null; then
                echo -e "${BLUE}Installing Ruby dependencies...${NC}"
                bundle install
            fi
            
            if [ -f "composer.json" ] && command -v composer &> /dev/null; then
                echo -e "${BLUE}Installing PHP dependencies...${NC}"
                composer install
            fi
            
            if [ -f "go.mod" ] && command -v go &> /dev/null; then
                echo -e "${BLUE}Installing Go dependencies...${NC}"
                go mod download
            fi
            
            echo -e "${GREEN}Dependency installation completed.${NC}"
        else
            echo -e "${BLUE}Skipping dependency installation.${NC}"
        fi
    else
        echo -e "${BLUE}No dependency files found.${NC}"
    fi
    
    # Return to the original directory
    cd - > /dev/null
}

# Helper function to run docker compose with the right command format
run_docker_compose() {
    local cmd="$1"
    shift
    
    # Try standalone docker-compose first
    if command -v docker-compose &> /dev/null; then
        docker-compose $cmd "$@"
        return $?
    # Then try the plugin style
    elif docker compose version &> /dev/null; then
        docker compose $cmd "$@"
        return $?
    else
        echo -e "${RED}Neither docker-compose nor docker compose plugin found.${NC}"
        return 1
    fi
}

# Function to check for docker-compose and prompt for initialization
check_docker_compose() {
    # Check if docker-compose.yml or docker-compose.yaml exists
    if [ -f "$REPO_DIR/docker-compose.yml" ] || [ -f "$REPO_DIR/docker-compose.yaml" ]; then
        echo -e "${BLUE}Docker Compose file found in repository.${NC}"
        
        read -p "Do you want to initialize and start Docker containers? [y/N] " START_DOCKER
        
        if [[ "$START_DOCKER" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Starting Docker containers...${NC}"
            
            # Create .env file if it doesn't exist
            if [ ! -f "$REPO_DIR/.env" ]; then
                echo -e "${YELLOW}No .env file found. Creating one from .env.example if available...${NC}"
                if [ -f "$REPO_DIR/.env.example" ]; then
                    cp "$REPO_DIR/.env.example" "$REPO_DIR/.env"
                    echo -e "${GREEN}Created .env from example.${NC}"
                    echo -e "${YELLOW}You may need to edit $REPO_DIR/.env to set proper configuration values.${NC}"
                else
                    echo -e "${YELLOW}Warning: No .env.example file found. You may need to create a .env file manually.${NC}"
                    touch "$REPO_DIR/.env"
                fi
            fi
            
            # Change to the repository directory and start docker-compose
            cd "$REPO_DIR"
            
            # Check if start.sh exists and use it
            if [ -f "./start.sh" ]; then
                echo -e "${BLUE}Found start.sh script. Running it...${NC}"
                chmod +x ./start.sh
                ./start.sh
            else
                echo -e "${BLUE}Running Docker Compose...${NC}"
                run_docker_compose up -d
            fi
            
            if [ $? -ne 0 ]; then
                echo -e "${RED}Error: Failed to start Docker containers.${NC}"
                echo -e "${YELLOW}Please check the Docker configuration and try manually.${NC}"
            else
                echo -e "${GREEN}Docker containers started successfully.${NC}"
                
                # Check if there's a URL or port specified in docker-compose
                if [ -f "$REPO_DIR/docker-compose.yml" ]; then
                    COMPOSE_FILE="$REPO_DIR/docker-compose.yml"
                else
                    COMPOSE_FILE="$REPO_DIR/docker-compose.yaml"
                fi
                
                # Extract ports from docker-compose file
                PORTS=$(grep -oP '"\d+:\d+"' "$COMPOSE_FILE" | grep -oP '\d+$' | sort -u)
                
                if [ ! -z "$PORTS" ]; then
                    echo -e "${GREEN}The application may be available at:${NC}"
                    for PORT in $PORTS; do
                        echo -e "  ${BLUE}http://localhost:$PORT${NC}"
                    done
                fi
            fi
        else
            echo -e "${BLUE}Skipping Docker initialization.${NC}"
            echo -e "${YELLOW}To start Docker later, navigate to $REPO_DIR and run 'docker compose up -d' or 'docker-compose up -d'${NC}"
        fi
    else
        echo -e "${YELLOW}No Docker Compose file found in repository.${NC}"
    fi
}

# Function to save repository information to .env file
save_repo_info() {
    echo -e "${BLUE}Saving repository information to .env file...${NC}"
    
    # Check if .env exists
    if [ ! -f .env ]; then
        echo -e "${YELLOW}Creating new .env file...${NC}"
        touch .env
    fi
    
    # Get current branch
    cd "$REPO_DIR"
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    cd - > /dev/null
    
    # Remove existing repo info if present
    sed -i '/^GIT_REPO_ORG=/d' .env
    sed -i '/^GIT_REPO_NAME=/d' .env
    sed -i '/^GIT_REPO_BRANCH=/d' .env
    sed -i '/^GIT_REPO_PATH=/d' .env
    
    # Add new repo info
    if [ -z "$ORGANIZATION" ]; then
        # Get username for personal repos
        USERNAME=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                  "https://api.github.com/user" | jq -r '.login')
        echo "GIT_REPO_ORG=$USERNAME" >> .env
    else
        echo "GIT_REPO_ORG=$ORGANIZATION" >> .env
    fi
    
    echo "GIT_REPO_NAME=$SELECTED_REPO" >> .env
    echo "GIT_REPO_BRANCH=$CURRENT_BRANCH" >> .env
    echo "GIT_REPO_PATH=$REPO_DIR" >> .env
    
    echo -e "${GREEN}Repository information saved to .env file.${NC}"
}

# Function to check if a repository was previously cloned
check_previous_repo() {
    if [ ! -f .env ]; then
        return 1
    fi
    
    # Extract repository information from .env
    GIT_REPO_ORG=$(grep -oP '^GIT_REPO_ORG=\K[^\s]+' .env 2>/dev/null)
    GIT_REPO_NAME=$(grep -oP '^GIT_REPO_NAME=\K[^\s]+' .env 2>/dev/null)
    GIT_REPO_PATH=$(grep -oP '^GIT_REPO_PATH=\K[^\s]+' .env 2>/dev/null)
    
    if [ -z "$GIT_REPO_ORG" ] || [ -z "$GIT_REPO_NAME" ] || [ -z "$GIT_REPO_PATH" ]; then
        return 1
    fi
    
    # Check if the repository directory exists
    if [ ! -d "$GIT_REPO_PATH" ]; then
        echo -e "${YELLOW}Repository directory not found: $GIT_REPO_PATH${NC}"
        return 1
    fi
    
    # Check if it's a git repository
    if [ ! -d "$GIT_REPO_PATH/.git" ]; then
        echo -e "${YELLOW}Not a git repository: $GIT_REPO_PATH${NC}"
        return 1
    fi
    
    return 0
}

# Function to show repository options when a previous repo is detected
show_repo_options() {
    echo -e "${BLUE}Repository information found in .env file:${NC}"
    echo -e "Organization/User: ${GREEN}$GIT_REPO_ORG${NC}"
    echo -e "Repository: ${GREEN}$GIT_REPO_NAME${NC}"
    echo -e "Path: ${GREEN}$GIT_REPO_PATH${NC}"
    echo
    echo -e "${BLUE}What would you like to do?${NC}"
    echo "1. Clone a new repository"
    echo "2. Push changes back to the existing repository"
    
    read -p "Enter your choice [1/2]: " REPO_CHOICE
    
    if [[ "$REPO_CHOICE" == "2" ]]; then
        return 0  # User wants to push changes
    else
        return 1  # User wants to clone a new repo
    fi
}

# Function to get available branches for a repository
get_available_branches() {
    echo -e "${BLUE}Fetching available branches...${NC}"
    
    cd "$REPO_DIR"
    
    # Make sure we have the latest from remote
    git fetch --all 2>/dev/null
    
    # Get remote branches
    REMOTE_BRANCHES=$(git branch -r | grep -v HEAD | sed 's/origin\///' | sort)
    
    # Get current branch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    
    cd - > /dev/null
    
    echo -e "${GREEN}Available branches:${NC}"
    echo "$REMOTE_BRANCHES"
}

# Function to display repository status
display_repo_status() {
    cd "$REPO_DIR"
    
    echo -e "${BLUE}Repository Status:${NC}"
    echo -e "${BLUE}--------------------------------------------${NC}"
    echo -e "${GREEN}Repository:${NC} $GIT_REPO_ORG/$GIT_REPO_NAME"
    echo -e "${GREEN}Local Path:${NC} $REPO_DIR"
    echo -e "${GREEN}Current Branch:${NC} $(git rev-parse --abbrev-ref HEAD)"
    
    # Get file status
    local modified=$(git status --porcelain | grep -c "^ M\|^MM")
    local added=$(git status --porcelain | grep -c "^A\|^M")
    local deleted=$(git status --porcelain | grep -c "^ D\|^D")
    local untracked=$(git status --porcelain | grep -c "^??")
    
    echo -e "${GREEN}Modified files:${NC} $modified"
    echo -e "${GREEN}Added files:${NC} $added"
    echo -e "${GREEN}Deleted files:${NC} $deleted"
    echo -e "${GREEN}Untracked files:${NC} $untracked"
    echo -e "${BLUE}--------------------------------------------${NC}"
    
    cd - > /dev/null
}

# Function to push changes back to GitHub
push_changes_to_github() {
    echo -e "${BLUE}Preparing to push changes to GitHub...${NC}"
    
    # Navigate to the repository directory
    cd "$REPO_DIR"
    
    # Display repository status
    display_repo_status
    
    # Check if there are changes to commit
    if git diff --quiet && git diff --staged --quiet; then
        echo -e "${YELLOW}No changes detected in the repository.${NC}"
        read -p "Do you want to continue anyway? [y/N] " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Operation canceled.${NC}"
            cd - > /dev/null
            return 1
        fi
    else
        echo -e "${GREEN}Changes detected in the repository.${NC}"
    fi
    
    # Get the current branch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    echo -e "${BLUE}Current branch: ${GREEN}$CURRENT_BRANCH${NC}"
    
    # Fetch available branches
    get_available_branches
    
    # Ask the user if they want to use the current branch or create a new one
    echo -e "${BLUE}What branch would you like to push to?${NC}"
    echo "1. Current branch ($CURRENT_BRANCH)"
    echo "2. Create a new branch"
    echo "3. Select an existing branch"
    
    read -p "Enter your choice [1/2/3]: " BRANCH_CHOICE
    
    case "$BRANCH_CHOICE" in
        2)
            # Create a new branch
            read -p "Enter name for the new branch: " NEW_BRANCH
            if [ -z "$NEW_BRANCH" ]; then
                echo -e "${RED}Branch name cannot be empty.${NC}"
                cd - > /dev/null
                return 1
            fi
            
            echo -e "${BLUE}Creating new branch: ${GREEN}$NEW_BRANCH${NC}"
            git checkout -b "$NEW_BRANCH"
            if [ $? -ne 0 ]; then
                echo -e "${RED}Failed to create new branch.${NC}"
                cd - > /dev/null
                return 1
            fi
            TARGET_BRANCH="$NEW_BRANCH"
            ;;
        3)
            # Select an existing branch
            echo -e "${BLUE}Available branches:${NC}"
            branches=()
            i=1
            while read branch; do
                if [ ! -z "$branch" ]; then
                    echo "$i. $branch"
                    branches+=("$branch")
                    i=$((i+1))
                fi
            done <<< "$REMOTE_BRANCHES"
            
            if [ ${#branches[@]} -eq 0 ]; then
                echo -e "${YELLOW}No remote branches found. Using current branch.${NC}"
                TARGET_BRANCH="$CURRENT_BRANCH"
            else
                read -p "Enter the number of the branch to use: " BRANCH_INDEX
                if ! [[ "$BRANCH_INDEX" =~ ^[0-9]+$ ]] || [ "$BRANCH_INDEX" -lt 1 ] || [ "$BRANCH_INDEX" -gt "${#branches[@]}" ]; then
                    echo -e "${RED}Invalid selection. Using current branch.${NC}"
                    TARGET_BRANCH="$CURRENT_BRANCH"
                else
                    SELECTED_BRANCH="${branches[$((BRANCH_INDEX-1))]}"
                    echo -e "${BLUE}Checking out branch: ${GREEN}$SELECTED_BRANCH${NC}"
                    git checkout "$SELECTED_BRANCH"
                    if [ $? -ne 0 ]; then
                        echo -e "${RED}Failed to checkout branch. Using current branch.${NC}"
                        TARGET_BRANCH="$CURRENT_BRANCH"
                    else
                        TARGET_BRANCH="$SELECTED_BRANCH"
                    fi
                fi
            fi
            ;;
        *)
            # Use current branch
            TARGET_BRANCH="$CURRENT_BRANCH"
            ;;
    esac
    
    # Ask for commit message
    echo -e "${BLUE}Please enter a commit message:${NC}"
    read -p "Commit message (default: 'Update from script'): " COMMIT_MSG
    if [ -z "$COMMIT_MSG" ]; then
        COMMIT_MSG="Update from script"
    fi
    
    # Stage all changes
    echo -e "${BLUE}Staging changes...${NC}"
    git add -A
    
    # Commit changes
    echo -e "${BLUE}Committing changes...${NC}"
    git commit -m "$COMMIT_MSG"
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}No changes to commit or commit failed.${NC}"
        echo -e "${YELLOW}Note: If you're seeing 'nothing to commit', it might be due to file permissions or Git configuration.${NC}"
        read -p "Do you want to force push anyway? [y/N] " FORCE_PUSH
        if [[ ! "$FORCE_PUSH" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Operation canceled.${NC}"
            cd - > /dev/null
            return 1
        fi
    fi
    
    # Push changes to GitHub
    echo -e "${BLUE}Pushing changes to GitHub...${NC}"
    
    # Construct authenticated URL
    if [ -z "$GIT_REPO_ORG" ]; then
        USERNAME=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                 "https://api.github.com/user" | jq -r '.login')
        REPO_URL="https://${GITHUB_TOKEN}@github.com/${USERNAME}/${GIT_REPO_NAME}.git"
    else
        REPO_URL="https://${GITHUB_TOKEN}@github.com/${GIT_REPO_ORG}/${GIT_REPO_NAME}.git"
    fi
    
    # Set up remote if needed
    git remote -v | grep -q "^origin"
    if [ $? -ne 0 ]; then
        echo -e "${BLUE}Setting up origin remote...${NC}"
        git remote add origin "$REPO_URL"
    else
        echo -e "${BLUE}Updating origin remote...${NC}"
        git remote set-url origin "$REPO_URL"
    fi
    
    # First try regular push
    echo -e "${BLUE}Attempting to push to branch: ${GREEN}$TARGET_BRANCH${NC}"
    PUSH_OUTPUT=$(git push -u origin "$TARGET_BRANCH" 2>&1)
    PUSH_STATUS=$?
    
    # Check if push failed
    if [ $PUSH_STATUS -ne 0 ]; then
        echo -e "${YELLOW}Push failed. Output:${NC}"
        echo "$PUSH_OUTPUT" | sed "s/$GITHUB_TOKEN/[HIDDEN_TOKEN]/g"
        
        # Ask user if they want to force push
        read -p "Do you want to force push (this will overwrite remote changes)? [y/N] " FORCE_PUSH
        if [[ "$FORCE_PUSH" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Force pushing to branch: ${GREEN}$TARGET_BRANCH${NC}"
            git push -f -u origin "$TARGET_BRANCH" 2>&1 | sed "s/$GITHUB_TOKEN/[HIDDEN_TOKEN]/g"
            PUSH_STATUS=$?
            
            if [ $PUSH_STATUS -ne 0 ]; then
                echo -e "${RED}Force push failed.${NC}"
                cd - > /dev/null
                return 1
            else
                echo -e "${GREEN}Force push successful.${NC}"
            fi
        else
            echo -e "${BLUE}Operation canceled.${NC}"
            cd - > /dev/null
            return 1
        fi
    else
        echo -e "${GREEN}Push successful.${NC}"
    fi
    
    # Determine the correct path for the .env file
    local env_path="$REPO_DIR/../.env"
    if [ ! -f "$env_path" ]; then
        env_path="$REPO_DIR/.env"
        if [ ! -f "$env_path" ]; then
            env_path=".env"
        fi
    fi
    
    # Update .env with new branch information
    if [ -f "$env_path" ]; then
        echo -e "${BLUE}Updating repository information in $env_path...${NC}"
        sed -i '/^GIT_REPO_BRANCH=/d' "$env_path"
        echo "GIT_REPO_BRANCH=$TARGET_BRANCH" >> "$env_path"
    else
        echo -e "${YELLOW}Warning: Could not find .env file to update.${NC}"
    fi
    
    echo -e "${GREEN}Changes successfully pushed to GitHub.${NC}"
    echo -e "${BLUE}Repository: ${GREEN}https://github.com/$GIT_REPO_ORG/$GIT_REPO_NAME${NC}"
    echo -e "${BLUE}Branch: ${GREEN}$TARGET_BRANCH${NC}"
    
    cd - > /dev/null
    return 0
}

# Main execution flow
main() {
    show_banner
    check_requirements
    read_github_token
    
    # Check if there's a previously cloned repository
    if check_previous_repo; then
        if show_repo_options; then
            # User wants to push changes back to existing repo
            ORGANIZATION=$GIT_REPO_ORG
            SELECTED_REPO=$GIT_REPO_NAME
            REPO_DIR=$GIT_REPO_PATH
            push_changes_to_github
            exit 0
        fi
        # Otherwise continue with normal flow to clone a new repo
    fi
    
    get_organization
    fetch_repositories
    select_repository
    get_target_directory
    clone_repository
    check_dependencies
    check_docker_compose
    save_repo_info  # Save repository information after successful clone
    
    echo -e "${GREEN}Repository installation complete!${NC}"
    echo -e "${BLUE}You can find your repository at: $REPO_DIR${NC}"
    echo -e "${BLUE}Repository information saved in .env file.${NC}"
    echo -e "${BLUE}Run this script again to push changes back to GitHub.${NC}"
}

# Run the main function
main
