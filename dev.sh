#!/bin/bash
# dev.sh - Helper script for Docker-based Flutter development
#
# Usage:
#   ./dev.sh setup     - First time setup (generate icons, get deps)
#   ./dev.sh shell     - Start interactive shell
#   ./dev.sh build     - Build release APK
#   ./dev.sh analyze   - Run Flutter analyze
#   ./dev.sh clean     - Clean build artifacts
#   ./dev.sh purge     - Remove all cached data

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Change to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    echo "Start Docker with: sudo systemctl start docker"
    exit 1
fi

case "${1:-help}" in
    setup)
        echo -e "${GREEN}Running first-time setup...${NC}"
        echo ""
        
        # Generate icons if missing
        if [ ! -f "android/app/src/main/res/mipmap-hdpi/ic_launcher.png" ]; then
            echo -e "${CYAN}Generating launcher icons...${NC}"
            docker compose run --rm flutter python3 scripts/generate_icons.py
        else
            echo -e "${CYAN}Launcher icons already exist, skipping...${NC}"
        fi
        
        echo ""
        echo -e "${CYAN}Getting Flutter dependencies...${NC}"
        docker compose run --rm flutter flutter pub get
        
        echo ""
        echo -e "${GREEN}✓ Setup complete!${NC}"
        echo -e "Run ${CYAN}./dev.sh build${NC} to build the APK"
        ;;

    shell|sh|s)
        echo -e "${GREEN}Starting Flutter development shell...${NC}"
        echo -e "${CYAN}Tip: Run 'flutter pub get' first if dependencies are missing${NC}"
        echo ""
        docker compose run --rm flutter bash
        ;;
    
    build|b)
        echo -e "${GREEN}Building release APK...${NC}"
        docker compose run --rm flutter bash -c "\
            flutter pub get && \
            flutter build apk --release"
        echo ""
        echo -e "${GREEN}✓ Build complete!${NC}"
        echo -e "APK: ${CYAN}build/app/outputs/flutter-apk/app-release.apk${NC}"
        ;;
    
    analyze|a)
        echo -e "${GREEN}Running Flutter analyze...${NC}"
        docker compose run --rm flutter bash -c "\
            flutter pub get && \
            flutter analyze"
        ;;
    
    test|t)
        echo -e "${GREEN}Running tests...${NC}"
        docker compose run --rm flutter bash -c "\
            flutter pub get && \
            flutter test"
        ;;
    
    clean|c)
        echo -e "${YELLOW}Cleaning build artifacts...${NC}"
        docker compose run --rm flutter flutter clean
        echo -e "${GREEN}✓ Clean complete${NC}"
        ;;
    
    purge|p)
        echo -e "${RED}This will remove all cached dependencies.${NC}"
        echo -e "${RED}Next build will take longer as everything re-downloads.${NC}"
        read -p "Continue? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose down -v
            echo -e "${GREEN}✓ Purge complete${NC}"
        else
            echo "Cancelled."
        fi
        ;;
    
    update|u)
        echo -e "${GREEN}Pulling latest Flutter image...${NC}"
        docker compose pull
        echo -e "${GREEN}✓ Update complete${NC}"
        ;;
    
    doctor|d)
        echo -e "${GREEN}Running Flutter doctor...${NC}"
        docker compose run --rm flutter flutter doctor -v
        ;;
    
    help|h|*)
        echo -e "${CYAN}Flutter Docker Development Helper${NC}"
        echo ""
        echo "Usage: ./dev.sh <command>"
        echo ""
        echo "Commands:"
        echo "  setup         First-time setup (icons, dependencies)"
        echo "  shell, sh, s  Start interactive shell in container"
        echo "  build, b      Build release APK"
        echo "  analyze, a    Run Flutter analyze"
        echo "  test, t       Run Flutter tests"
        echo "  clean, c      Clean build artifacts"
        echo "  purge, p      Remove containers and all cached data"
        echo "  update, u     Pull latest Flutter Docker image"
        echo "  doctor, d     Run Flutter doctor"
        echo "  help, h       Show this help"
        echo ""
        echo "First time? Run:"
        echo "  docker compose pull   # Download Flutter image (~3GB)"
        echo "  ./dev.sh setup        # Generate icons & get dependencies"
        echo "  ./dev.sh build        # Build the APK"
        echo ""
        echo "APK output location:"
        echo "  build/app/outputs/flutter-apk/app-release.apk"
        ;;
esac
