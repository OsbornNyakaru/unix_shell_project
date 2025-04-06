#!/bin/bash
#############################################################################
#                                                                           #
#                     ADVANCED WEB PROJECT SETUP TOOL                       #
#                                                                           #
#############################################################################

#############################################################################
# SHELL VARIABLES
# Declaring variables to store configuration and settings
#############################################################################
VERSION="1.0.0"
SCRIPT_NAME=$(basename "$0")
CURRENT_DIR=$(pwd)
TEMPLATES_DIR="$HOME/.project_templates"
CONFIG_FILE="$HOME/.project_config"
LOG_FILE="/tmp/project_setup_$$.log"
DEFAULT_PORT=3000
DEFAULT_DESCRIPTION="Web project created with Advanced Project Setup Tool"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
DEFAULT_AUTHOR=$(whoami)

#############################################################################
# SHELL ARRAYS
# Using arrays to store multiple related items
#############################################################################
# Array of required directories
DIRECTORIES=("Html" "CSS" "JavaScript" "Assets" "Data" "Docs" "Tests" "Server" "Config" "Build")

# Array of dependencies
DEPENDENCIES=("git" "curl" "node" "npm")

# Array of file templates
TEMPLATES=("html:index.html" "css:styles.css" "js:script.js" "readme:README.md" "gitignore:.gitignore")

# Array of spinner characters for progress bar
SPINNER_CHARS=('|' '/' '-' '\')

#############################################################################
# SHELL FUNCTIONS
# Organizing code into reusable functions
#############################################################################

# Function to display a spinner/progress bar
progress_bar() {
    # SHELL LOOP TYPES - Using for loop to iterate
    local duration=${1:-2}
    local interval=0.1
    local i=0
    local width=40
    
    # Calculate iterations based on duration and interval
    local iterations=$(bc <<< "$duration / $interval")
    
    echo -ne "Progress: ["
    
    # SHELL LOOP TYPES - Using while loop with counter
    while [ $i -lt $iterations ]; do
        # SHELL BASIC OPERATORS - Using arithmetic operators
        local pos=$((i * width / iterations))
        
        # SHELL SUBSTITUTION - Using string substitution to create progress bar
        printf -v bar "%${pos}s" ""
        printf -v empty "%$((width - pos))s" ""
        
        # SHELL BASIC OPERATORS - Using string concatenation
        echo -ne "\rProgress: [${bar// /#}${empty// /-}] ${SPINNER_CHARS[i % 4]} "
        
        sleep $interval
        ((i++))
    done
    
    echo -e "\rProgress: [${bar//?/#}] Complete!"
}

# Function to log messages
log_message() {
    # SHELL VARIABLES - Using local variables in function
    local message="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # SHELL SUBSTITUTION - String interpolation
    echo "[$timestamp] $message" >> "$LOG_FILE"
    echo "[$timestamp] $message"
}

# Function to check network connectivity
check_network() {
    # NETWORK COMMUNICATION UTILITIES - Using ping to check connectivity
    log_message "Checking network connectivity..."
    
    if ping -c 1 google.com &> /dev/null; then
        log_message "Network connectivity: OK"
        return 0
    else
        log_message "Network connectivity: FAILED"
        return 1
    fi
}

# Function to check dependencies
check_dependencies() {
    # SHELL DECISION MAKING - Using if statement for conditional execution
    log_message "Checking dependencies..."
    local missing_deps=()
    
    # SHELL LOOP TYPES - Using for loop with array
    for dep in "${DEPENDENCIES[@]}"; do
        if ! command -v $dep &> /dev/null; then
            # SHELL ARRAYS - Adding element to array
            missing_deps+=("$dep")
        fi
    done
    
    # SHELL DECISION MAKING - Using if with test on array size
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_message "Missing dependencies: ${missing_deps[*]}"
        
        # SHELL DECISION MAKING - Using if with logical operator
        if [ "$AUTO_INSTALL" = "true" ]; then
            install_dependencies "${missing_deps[@]}"
        else
            read -p "Do you want to install missing dependencies? (y/n): " choice
            if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
                install_dependencies "${missing_deps[@]}"
            else
                log_message "Warning: Some dependencies are missing. Functionality may be limited."
            fi
        fi
    else
        log_message "All dependencies are installed."
    fi
}

# Function to install dependencies
install_dependencies() {
    # SHELL ARRAYS - Accepting array as parameter
    local deps=("$@")
    log_message "Installing dependencies: ${deps[*]}"
    
    # NETWORK COMMUNICATION UTILITIES - Using package managers that require network
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y "${deps[@]}"
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y "${deps[@]}"
    elif command -v yum &> /dev/null; then
        sudo yum install -y "${deps[@]}"
    elif command -v brew &> /dev/null; then
        brew install "${deps[@]}"
    else
        log_message "Error: Package manager not found. Please install dependencies manually."
        return 1
    fi
    
    log_message "Dependencies installed successfully."
}

# Function to create a basic configuration file
create_config() {
    # SHELL VARIABLES - Using variables for configuration
    local project_name="$1"
    local author="${2:-$DEFAULT_AUTHOR}"
    local description="${3:-$DEFAULT_DESCRIPTION}"
    local port="${4:-$DEFAULT_PORT}"
    
    log_message "Creating configuration files..."
    
    # FILE MANAGEMENT - Creating config files
    cat > "$project_name/Config/project.config" << EOF
# Project Configuration
PROJECT_NAME="$project_name"
AUTHOR="$author"
DESCRIPTION="$description"
PORT=$port
CREATED_AT="$TIMESTAMP"
EOF
    
    # FILE PERMISSION/ACCESS MODES - Setting read-only permissions for config
    chmod 644 "$project_name/Config/project.config"
    
    # Creating package.json for npm projects
    cat > "$project_name/package.json" << EOF
{
  "name": "$project_name",
  "version": "1.0.0",
  "description": "$description",
  "main": "Server/index.js",
  "scripts": {
    "start": "node Server/index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "$author",
  "license": "MIT"
}
EOF
}

# Function to create a readme file
create_readme() {
    # SHELL VARIABLES - Using variables for substitution
    local project_name="$1"
    local description="$2"
    local author="$3"
    
    log_message "Creating README.md file..."
    
    # FILE MANAGEMENT - Creating readme file
    cat > "$project_name/README.md" << EOF
# $project_name

$description

## Project Structure

\`\`\`
$(find "$project_name" -type d | sort | sed -e "s/[^-][^\/]*\// |/g" -e "s/|$$[^ ]$$/|-\1/")
\`\`\`

## Getting Started

1. Navigate to the project directory: \`cd $project_name\`
2. Install dependencies: \`npm install\`
3. Start the server: \`npm start\`

## Author

$author

## Created

$TIMESTAMP
EOF
}

# Function to initialize git repository
init_git_repo() {
    # SHELL VARIABLES - Using parameter substitution
    local project_dir="${1:-.}"
    
    log_message "Initializing Git repository..."
    
    # DIRECTORY MANAGEMENT - Changing directory
    cd "$project_dir"
    
    # Create .gitignore file
    cat > .gitignore << EOF
# Dependencies
/node_modules
/.pnp
.pnp.js

# Testing
/coverage

# Production
/build

# Misc
.DS_Store
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

npm-debug.log*
yarn-debug.log*
yarn-error.log*
EOF
    
    # Initialize git repository
    git init &> /dev/null
    git add . &> /dev/null
    git commit -m "Initial commit" &> /dev/null
    
    # DIRECTORY MANAGEMENT - Returning to original directory
    cd - > /dev/null
    
    log_message "Git repository initialized successfully."
}

# Function to fetch templates from online sources
fetch_templates() {
    # SHELL DECISION MAKING - Using if statement with command execution check
    log_message "Fetching templates from online sources..."
    
    # NETWORK COMMUNICATION UTILITIES - Using curl to fetch content
    if ! check_network; then
        log_message "Warning: Network unavailable. Using local templates only."
        return 1
    fi
    
    # Create templates directory if it doesn't exist
    mkdir -p "$TEMPLATES_DIR"
    
    # Fetch HTML template
    curl -s "https://raw.githubusercontent.com/h5bp/html5-boilerplate/main/dist/index.html" > "$project_name/Html/index.html" 2>/dev/null || \
        log_message "Warning: Failed to fetch HTML template."
    
    # Fetch CSS template
    curl -s "https://raw.githubusercontent.com/h5bp/html5-boilerplate/main/dist/css/style.css" > "$project_name/CSS/styles.css" 2>/dev/null || \
        log_message "Warning: Failed to fetch CSS template."
    
    # Fetch JavaScript template
    curl -s "https://raw.githubusercontent.com/h5bp/html5-boilerplate/main/dist/js/main.js" > "$project_name/JavaScript/script.js" 2>/dev/null || \
        log_message "Warning: Failed to fetch JavaScript template."
    
    log_message "Templates fetched successfully."
}

# Function to create a simple server file
create_server_file() {
    # SHELL VARIABLES - Using variable substitution
    local project_dir="$1"
    local port="${2:-$DEFAULT_PORT}"
    
    log_message "Creating server file..."
    
    # Create a simple Express server file
    cat > "$project_dir/Server/index.js" << EOF
const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || $port;

// Serve static files
app.use(express.static(path.join(__dirname, '../Html')));
app.use('/css', express.static(path.join(__dirname, '../CSS')));
app.use('/js', express.static(path.join(__dirname, '../JavaScript')));

// Routes
app.get('/api/status', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

// Start server
app.listen(PORT, () => {
  console.log(\`Server running on http://localhost:\${PORT}\`);
});
EOF
}

# Function to set file permissions
set_permissions() {
    # FILE PERMISSION/ACCESS MODES - Setting appropriate permissions
    local project_dir="$1"
    
    log_message "Setting file permissions..."
    
    # Make scripts executable
    find "$project_dir" -name "*.sh" -exec chmod +x {} \;
    
    # Set directory permissions
    find "$project_dir" -type d -exec chmod 755 {} \;
    
    # Set file permissions
    find "$project_dir" -type f -not -path "*/\.*" -exec chmod 644 {} \;
    
    # Set config file permissions
    find "$project_dir/Config" -type f -exec chmod 640 {} \;
    
    log_message "File permissions set successfully."
}

# Function to create vi editor instructions file
create_vi_instructions() {
    # THE VI EDITOR - Creating a file with vi instructions
    log_message "Creating Vi editor instructions file..."
    
    # FILE MANAGEMENT - Creating a new file with content
    cat > "$project_name/Docs/vi_instructions.md" << EOF
# Vi Editor Quick Reference

## Starting Vi
- \`vi filename\` - Open or create a file in Vi
- \`view filename\` - Open a file in read-only mode

## Vi Modes
- **Command Mode** - Default mode for navigation and commands
- **Insert Mode** - For inserting text (press 'i' to enter)
- **Visual Mode** - For selecting text (press 'v' to enter)

## Basic Commands
- \`i\` - Enter insert mode at cursor
- \`a\` - Enter insert mode after cursor
- \`Esc\` - Return to command mode
- \`:w\` - Save file
- \`:q\` - Quit Vi
- \`:wq\` or \`ZZ\` - Save and quit
- \`:q!\` - Quit without saving

## Navigation
- \`h\` - Move cursor left
- \`j\` - Move cursor down
- \`k\` - Move cursor up
- \`l\` - Move cursor right
- \`0\` - Move to beginning of line
- \`$\` - Move to end of line
- \`gg\` - Move to beginning of file
- \`G\` - Move to end of file

## Editing
- \`dd\` - Delete line
- \`yy\` - Copy line
- \`p\` - Paste after cursor
- \`u\` - Undo
- \`Ctrl+r\` - Redo

## Search and Replace
- \`/pattern\` - Search forward for pattern
- \`?pattern\` - Search backward for pattern
- \`n\` - Repeat search in same direction
- \`N\` - Repeat search in opposite direction
- \`:%s/old/new/g\` - Replace all old with new throughout file

## Vi Tutorial
To start the built-in Vi tutorial, type:
\`\`\`
vimtutor
\`\`\`
EOF
}

# Function to open a file in Vi editor
edit_with_vi() {
    # THE VI EDITOR - Using vi to edit files
    local file="$1"
    
    # SHELL DECISION MAKING - Check if file exists
    if [ ! -f "$file" ]; then
        log_message "Error: File '$file' not found."
        return 1
    fi
    
    log_message "Opening file '$file' in Vi editor..."
    log_message "Press 'i' to enter insert mode, 'Esc' to exit insert mode, and ':wq' to save and quit."
    
    # Prompt user to continue
    read -p "Press Enter to continue..."
    
    # THE VI EDITOR - Opening file in vi
    vi "$file"
}

# Function to display environment information
display_environment() {
    # ENVIRONMENT - Displaying environment variables and system info
    log_message "Environment Information:"
    
    echo -e "\n-------- System Information --------"
    echo "Hostname: $(hostname)"
    echo "OS: $(uname -s)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    
    echo -e "\n-------- User Information --------"
    echo "User: $(whoami)"
    echo "Home: $HOME"
    echo "Shell: $SHELL"
    
    echo -e "\n-------- Path Information --------"
    echo "Current Directory: $(pwd)"
    echo "PATH: $PATH" | tr ':' '\n' | sed 's/^/  - /'
    
    echo -e "\n-------- Project Variables --------"
    # SHELL LOOP TYPES - Using for loop with command substitution
    for var in $(env | grep "^PROJECT_"); do
        echo "$var"
    done
}

# Function to create HTML template
create_html_template() {
    # SHELL VARIABLES - Using variables for project name substitution
    local project_name="$1"
    
    log_message "Creating HTML template..."
    
    # FILE MANAGEMENT - Creating HTML file
    cat > "$project_name/Html/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$project_name</title>
    <link rel="stylesheet" href="/css/styles.css">
</head>
<body>
    <header>
        <h1>Welcome to $project_name</h1>
        <nav>
            <ul>
                <li><a href="/">Home</a></li>
                <li><a href="/about">About</a></li>
                <li><a href="/contact">Contact</a></li>
            </ul>
        </nav>
    </header>
    
    <main>
        <section class="hero">
            <h2>Your Web Project</h2>
            <p>This is the main content area of your web project.</p>
        </section>
        
        <section class="features">
            <div class="feature">
                <h3>Feature 1</h3>
                <p>Description of feature 1</p>
            </div>
            <div class="feature">
                <h3>Feature 2</h3>
                <p>Description of feature 2</p>
            </div>
            <div class="feature">
                <h3>Feature 3</h3>
                <p>Description of feature 3</p>
            </div>
        </section>
    </main>
    
    <footer>
        <p>&copy; $(date +%Y) $project_name. All rights reserved.</p>
    </footer>
    
    <script src="/js/script.js"></script>
</body>
</html>
EOF
}

# Function to create CSS template
create_css_template() {
    # SHELL VARIABLES - Using variable for project name
    local project_name="$1"
    
    log_message "Creating CSS template..."
    
    # FILE MANAGEMENT - Creating CSS file
    cat > "$project_name/CSS/styles.css" << EOF
/* Reset and base styles */
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Arial', sans-serif;
    line-height: 1.6;
    color: #333;
    background-color: #f4f4f4;
}

/* Header styles */
header {
    background-color: #35424a;
    color: #ffffff;
    padding: 20px;
    border-bottom: 3px solid #e8491d;
}

header h1 {
    margin-bottom: 10px;
}

nav ul {
    display: flex;
    list-style: none;
}

nav li {
    margin-right: 20px;
}

nav a {
    color: white;
    text-decoration: none;
}

nav a:hover {
    color: #e8491d;
}

/* Main content styles */
main {
    max-width: 1200px;
    margin: 20px auto;
    padding: 0 20px;
}

.hero {
    background-color: white;
    padding: 40px;
    margin-bottom: 30px;
    border-radius: 5px;
    box-shadow: 0 2px 5px rgba(0,0,0,0.1);
    text-align: center;
}

.hero h2 {
    font-size: 32px;
    margin-bottom: 20px;
    color: #35424a;
}

.features {
    display: flex;
    justify-content: space-between;
    flex-wrap: wrap;
}

.feature {
    flex: 1;
    background-color: white;
    padding: 20px;
    margin: 10px;
    border-radius: 5px;
    box-shadow: 0 2px 5px rgba(0,0,0,0.1);
    min-width: 300px;
}

.feature h3 {
    color: #e8491d;
    margin-bottom: 10px;
}

/* Footer styles */
footer {
    background-color: #35424a;
    color: white;
    text-align: center;
    padding: 20px;
    margin-top: 40px;
}

/* Responsive styles */
@media (max-width: 768px) {
    .features {
        flex-direction: column;
    }
    
    .feature {
        margin: 10px 0;
    }
}
EOF
}

# Function to create JavaScript template
create_js_template() {
    # SHELL VARIABLES - Using variable for project
    local project_name="$1"
    
    log_message "Creating JavaScript template..."
    
    # FILE MANAGEMENT - Creating JavaScript file
    cat > "$project_name/JavaScript/script.js" << EOF
// Main JavaScript file for $project_name

// Wait for DOM to load
document.addEventListener('DOMContentLoaded', function() {
    console.log('$project_name JavaScript initialized');
    
    // Initialize features
    initializeFeatures();
    
    // Check if API is available
    checkApiStatus();
});

// Initialize page features
function initializeFeatures() {
    // Add current year to footer
    const footerYear = document.querySelector('footer p');
    if (footerYear) {
        const year = new Date().getFullYear();
        footerYear.textContent = footerYear.textContent.replace(/\\d{4}/, year);
    }
    
    // Add event listeners to navigation
    const navLinks = document.querySelectorAll('nav a');
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            // If it's a hash link, prevent default
            if (this.getAttribute('href').startsWith('#')) {
                e.preventDefault();
                console.log('Navigation to:', this.textContent);
            }
        });
    });
}

// Check API status
function checkApiStatus() {
    fetch('/api/status')
        .then(response => response.json())
        .then(data => {
            console.log('API Status:', data.status);
            console.log('Timestamp:', new Date(data.timestamp));
        })
        .catch(error => {
            console.error('API Error:', error);
        });
}

// Example utility function for DOM manipulation
function createElement(tag, text, parent) {
    const element = document.createElement(tag);
    if (text) element.textContent = text;
    if (parent) parent.appendChild(element);
    return element;
}
EOF
}

# Function to create a test file
create_test_file() {
    # SHELL VARIABLES - Using variable substitution
    local project_name="$1"
    
    log_message "Creating test file..."
    
    # FILE MANAGEMENT - Creating test file
    cat > "$project_name/Tests/test.js" << EOF
// Example test file for $project_name
console.log('Running tests for $project_name');

// Simple test framework
function describe(description, callback) {
    console.log('\\n' + description);
    callback();
}

function it(description, callback) {
    try {
        callback();
        console.log('✓ ' + description);
    } catch (error) {
        console.error('✗ ' + description);
        console.error('  ' + error.message);
    }
}

function expect(actual) {
    return {
        toBe: (expected) => {
            if (actual !== expected) {
                throw new Error(\`Expected \${expected} but got \${actual}\`);
            }
        },
        toBeGreaterThan: (expected) => {
            if (actual <= expected) {
                throw new Error(\`Expected \${actual} to be greater than \${expected}\`);
            }
        }
    };
}

// Run example tests
describe('Project setup', () => {
    it('should have correct project name', () => {
        expect('$project_name'.length).toBeGreaterThan(0);
    });
    
    it('should pass this test', () => {
        expect(true).toBe(true);
    });
});

console.log('\\nAll tests completed.');
EOF
}

# Function to display project menu
display_menu() {
    # SHELL DECISION MAKING - Using case statement for menu
    local project_dir="$1"
    local choice
    
    while true; do
        echo -e "\n========================================"
        echo "    $project_name Project Management    "
        echo "========================================"
        echo "1. Edit HTML file"
        echo "2. Edit CSS file"
        echo "3. Edit JavaScript file"
        echo "4. View project structure"
        echo "5. View environment information"
        echo "6. Set file permissions"
        echo "7. Check network connectivity"
        echo "8. View Vi editor instructions"
        echo "9. Exit"
        echo "========================================"
        read -p "Enter your choice [1-9]: " choice
        
        # SHELL DECISION MAKING - Using case statement
        case $choice in
            1)
                edit_with_vi "$project_dir/Html/index.html"
                ;;
            2)
                edit_with_vi "$project_dir/CSS/styles.css"
                ;;
            3)
                edit_with_vi "$project_dir/JavaScript/script.js"
                ;;
            4)
                echo -e "\nProject Structure:"
                # DIRECTORY MANAGEMENT - Using find to list directories
                find "$project_dir" -type d | sort | sed -e "s/[^-][^\/]*\// |/g" -e "s/|$$[^ ]$$/|-\1/"
                ;;
            5)
                display_environment
                ;;
            6)
                set_permissions "$project_dir"
                ;;
            7)
                check_network
                ;;
            8)
                more "$project_dir/Docs/vi_instructions.md"
                ;;
            9)
                log_message "Exiting project management."
                return 0
                ;;
            *)
                echo "Invalid choice. Please select a number between 1 and 9."
                ;;
        esac
        
        read -p "Press Enter to continue..."
    done
}

#############################################################################
# MAIN SCRIPT EXECUTION
#############################################################################

# Display header
echo -e "\n============================================"
echo "      ADVANCED WEB PROJECT SETUP TOOL     "
echo "============================================"

# Get project details
# SHELL VARIABLES - Reading user input into variables
echo -e "\nPlease enter project details:"
read -p "Enter Project Name: " project_name

# SHELL DECISION MAKING - Using logical OR for default values
if [ -z "$project_name" ]; then
    project_name="WebProject_$(date +%Y%m%d)"
    echo "Using default project name: $project_name"
fi

# Get additional project information
read -p "Enter Project Description (or press Enter for default): " project_description
project_description=${project_description:-$DEFAULT_DESCRIPTION}

read -p "Enter Author Name (or press Enter for current user): " author_name
author_name=${author_name:-$DEFAULT_AUTHOR}

read -p "Enter Server Port (or press Enter for default port 3000): " port_number
port_number=${port_number:-$DEFAULT_PORT}

# SHELL BASIC OPERATORS - Using numerical comparison
# Validate port number
if ! [[ "$port_number" =~ ^[0-9]+$ ]] || [ "$port_number" -lt 1024 ] || [ "$port_number" -gt 65535 ]; then
    echo "Invalid port number. Using default port 3000."
    port_number=3000
fi

# Confirm project creation
echo -e "\nProject Details:"
echo "- Name: $project_name"
echo "- Description: $project_description"
echo "- Author: $author_name"
echo "- Port: $port_number"
read -p "Continue with these settings? (y/n): " confirm

# SHELL DECISION MAKING - Using if-else statement
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Project setup cancelled."
    exit 0
fi

# Start logging
log_message "Starting project setup for $project_name"

# Check dependencies
check_dependencies

# Show progress bar for initialization
echo -e "\nInitializing project..."
progress_bar 3

# DIRECTORY MANAGEMENT - Creating the project root directory
log_message "Creating project directory structure..."
mkdir -p "$project_name"

# SHELL LOOP TYPES - Using for loop to iterate through array
for dir in "${DIRECTORIES[@]}"; do
    # DIRECTORY MANAGEMENT - Creating subdirectories
    mkdir -p "$project_name/$dir"
    log_message "Created directory: $dir"
done

# Create project files
log_message "Creating project files..."

# Create HTML template
create_html_template "$project_name"

# Create CSS template
create_css_template "$project_name"

# Create JavaScript template
create_js_template "$project_name"

# Create test file
create_test_file "$project_name"

# Create server file
create_server_file "$project_name" "$port_number"

# Create configuration
create_config "$project_name" "$author_name" "$project_description" "$port_number"

# Create README file
create_readme "$project_name" "$project_description" "$author_name"

# Create Vi editor instructions
create_vi_instructions

# Check network and fetch templates if available
fetch_templates

# Initialize git repository
init_git_repo "$project_name"

# Set file permissions
set_permissions "$project_name"

# Display project structure
echo -e "\nProject Structure:"
# DIRECTORY MANAGEMENT - Using find to list directories and files
find "$project_name" -type d | sort | sed -e "s/[^-][^\/]*\// |/g" -e "s/|$$[^ ]$$/|-\1/"

# Set environment variables for the project
# ENVIRONMENT - Setting environment variables
export PROJECT_NAME="$project_name"
export PROJECT_DIR="$CURRENT_DIR/$project_name"
export PROJECT_PORT="$port_number"

log_message "Project '$project_name' created successfully!"
echo -e "\nYour project has been created at: $CURRENT_DIR/$project_name"
echo "A management menu is available for common tasks."

# Display menu for project management
read -p "Would you like to open the project management menu? (y/n): " open_menu
if [ "$open_menu" = "y" ] || [ "$open_menu" = "Y" ]; then
    display_menu "$project_name"
fi

echo -e "\nThank you for using the Advanced Web Project Setup Tool!"
exit 0