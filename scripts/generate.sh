#!/bin/bash

# Keklist Flutter - Generation Scripts
# Interactive script for generating localization and Hive models

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BOLD}${CYAN}$1${NC}"
}

print_menu_item() {
    echo -e "${BOLD}$1${NC}. $2"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to generate localization files
generate_localization() {
    print_status "Generating localization files..."
    
    if ! command_exists flutter; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    flutter gen-l10n
    
    if [ $? -eq 0 ]; then
        print_success "Localization files generated successfully"
    else
        print_error "Failed to generate localization files"
        exit 1
    fi
}

# Function to generate Hive models
generate_hive_models() {
    print_status "Generating Hive models..."
    
    if ! command_exists dart; then
        print_error "Dart is not installed or not in PATH"
        exit 1
    fi
    
    # Generate Hive adapters
    dart run build_runner build --delete-conflicting-outputs
    
    if [ $? -eq 0 ]; then
        print_success "Hive models generated successfully"
    else
        print_error "Failed to generate Hive models"
        exit 1
    fi
}

# Function to clean generated files
clean_generated() {
    print_status "Cleaning generated files..."
    
    # Clean build runner files
    dart run build_runner clean
    
    # Clean Flutter build
    flutter clean
    
    print_success "Generated files cleaned"
}

# Function to generate everything
generate_all() {
    print_status "Generating all files..."
    
    generate_localization
    generate_hive_models
    
    print_success "All files generated successfully"
}

# Function to show interactive menu
show_menu() {
    clear
    print_header "🚀 Keklist Flutter - Generation Scripts"
    echo ""
    print_header "Available Scripts:"
    echo ""
    print_menu_item "1" "Generate Localization Files (flutter gen-l10n)"
    print_menu_item "2" "Generate Hive Models (dart run build_runner build)"
    print_menu_item "3" "Generate Everything (localization + Hive models)"
    print_menu_item "4" "Clean Generated Files (clean all generated files)"
    print_menu_item "5" "Show Help (display usage information)"
    print_menu_item "0" "Exit"
    echo ""
}

# Function to get user input
get_user_choice() {
    echo -n "Enter your choice (0-5): "
    read -r choice
    echo ""
}

# Function to handle menu selection
handle_choice() {
    case $choice in
        1)
            print_header "📝 Generating Localization Files..."
            generate_localization
            ;;
        2)
            print_header "🗃️  Generating Hive Models..."
            generate_hive_models
            ;;
        3)
            print_header "🔄 Generating Everything..."
            generate_all
            ;;
        4)
            print_header "🧹 Cleaning Generated Files..."
            clean_generated
            ;;
        5)
            show_help
            ;;
        0)
            print_success "Goodbye! 👋"
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please enter a number between 0-5."
            ;;
    esac
}

# Function to show help
show_help() {
    print_header "📖 Help - Keklist Flutter Generation Scripts"
    echo ""
    echo "This interactive script helps you generate localization files and Hive models."
    echo ""
    print_header "What each option does:"
    echo ""
    echo "1. Generate Localization Files:"
    echo "   - Runs 'flutter gen-l10n'"
    echo "   - Generates Dart files from ARB files in lib/l10n/"
    echo "   - Use after adding new translations"
    echo ""
    echo "2. Generate Hive Models:"
    echo "   - Runs 'dart run build_runner build --delete-conflicting-outputs'"
    echo "   - Generates .g.dart files for Hive objects"
    echo "   - Use after modifying Hive model classes"
    echo ""
    echo "3. Generate Everything:"
    echo "   - Runs both localization and Hive generation"
    echo "   - Perfect for setting up the project after cloning"
    echo ""
    echo "4. Clean Generated Files:"
    echo "   - Runs 'dart run build_runner clean' and 'flutter clean'"
    echo "   - Removes all generated files"
    echo "   - Use when things go wrong or to start fresh"
    echo ""
    echo "5. Show Help:"
    echo "   - Displays this help information"
    echo ""
    echo "0. Exit:"
    echo "   - Exits the script"
    echo ""
    print_status "Press Enter to return to the main menu..."
    read -r
}

# Main script logic
main() {
    # Check if command line arguments were provided (for backward compatibility)
    if [ $# -gt 0 ]; then
        case "$1" in
            "l10n"|"localization")
                generate_localization
                ;;
            "hive"|"models")
                generate_hive_models
                ;;
            "all")
                generate_all
                ;;
            "clean")
                clean_generated
                ;;
            "help"|"-h"|"--help")
                show_help
                ;;
            *)
                print_error "Unknown command: $1"
                echo "Use '$0' without arguments for interactive mode, or '$0 help' for help."
                exit 1
                ;;
        esac
        exit 0
    fi

    # Interactive mode
    while true; do
        show_menu
        get_user_choice
        handle_choice
        
        if [ "$choice" != "0" ] && [ "$choice" != "5" ]; then
            echo ""
            print_status "Press Enter to continue..."
            read -r
        fi
    done
}

# Run main function
main "$@"
