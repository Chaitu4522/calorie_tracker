# Docker Setup Guide for Flutter Development

A beginner-friendly guide to using Docker for Flutter Android app development.

---

## Table of Contents

1. [Understanding the Basics](#understanding-the-basics)
2. [Install Docker](#install-docker)
3. [Project Structure](#project-structure)
4. [Setup Files](#setup-files)
5. [Daily Workflow](#daily-workflow)
6. [Common Commands](#common-commands)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## Understanding the Basics

### What is Docker?

Think of Docker as a "lightweight virtual machine" that packages an application with all its dependencies. Instead of installing Flutter, Android SDK, Java, etc. on your machine, everything runs inside an isolated container.

### Key Terminology

| Term | Meaning |
|------|---------|
| **Image** | A template/snapshot (like an ISO file). Read-only. |
| **Container** | A running instance of an image (like a VM running from an ISO). |
| **Volume** | Persistent storage that survives container restarts. |
| **Mount** | Connecting a host folder to a container folder. |

### How This Setup Works

```
┌─────────────────────────────────────────────────────────┐
│  YOUR WORKSTATION                                       │
│                                                         │
│  ┌─────────────────┐      ┌─────────────────────────┐  │
│  │ VS Code         │      │ Docker Container        │  │
│  │ + Codeium       │      │                         │  │
│  │                 │      │  Flutter SDK            │  │
│  │  Edit code ────────────▶  Android SDK            │  │
│  │  here           │      │  Java                   │  │
│  │                 │ ◀────────  Build APK here      │  │
│  └─────────────────┘      │                         │  │
│          │                └─────────────────────────┘  │
│          │                           │                 │
│          ▼                           ▼                 │
│  ~/projects/calorie_tracker ◀──────────────────────────│
│  (shared via volume mount)                             │
└─────────────────────────────────────────────────────────┘
```

---

## Install Docker

### Ubuntu/Debian

```bash
# Update package index
sudo apt update

# Install Docker
sudo apt install -y docker.io docker-compose-v2

# Add yourself to docker group (avoids needing sudo)
sudo usermod -aG docker $USER

# IMPORTANT: Log out and log back in for group change to take effect
# Or run: newgrp docker

# Verify installation
docker --version
docker compose version
```

### Fedora

```bash
sudo dnf install -y docker docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
# Log out and back in
```

### Arch Linux

```bash
sudo pacman -S docker docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
# Log out and back in
```

### Verify Docker Works

```bash
# Should run without sudo after logging back in
docker run hello-world
```

---

## Project Structure

### Recommended Directory Layout

```
~/projects/                     # All your projects live here
└── calorie_tracker/            # This specific project
    ├── android/                # Android-specific files
    ├── lib/                    # Dart source code
    ├── docker-compose.yml      # Docker configuration (we'll create this)
    ├── .dockerignore           # Files to exclude from Docker
    ├── pubspec.yaml            # Flutter dependencies
    └── README.md
```

### Why This Structure?

- `~/projects/` - Keeps all projects organized in one place
- `docker-compose.yml` in project root - Easy to run `docker compose` commands
- Everything versioned in git together

---

## Setup Files

### Step 1: Create Project Directory (if not exists)

```bash
# Create projects directory
mkdir -p ~/projects

# Move/clone your project there
cd ~/projects

# If you have the zip file:
unzip /path/to/calorie_tracker.zip
cd calorie_tracker

# Remove the buggy folder if present
rm -rf "{lib" 2>/dev/null || true
```

### Step 2: Create docker-compose.yml

Create this file in your project root (`~/projects/calorie_tracker/docker-compose.yml`):

```yaml
# docker-compose.yml
# Flutter development environment using pre-built image

services:
  # Service name - use this in commands: docker compose run flutter bash
  flutter:
    # Pre-built Flutter image with Android SDK
    image: ghcr.io/cirruslabs/flutter:stable
    
    # Container name when running (optional but helpful)
    container_name: calorie_tracker_flutter
    
    # Mount current directory to /app in container
    volumes:
      # Project files (synced between host and container)
      - .:/app
      
      # Cache Gradle dependencies (faster rebuilds)
      - gradle-cache:/root/.gradle
      
      # Cache Flutter pub packages
      - pub-cache:/root/.pub-cache
    
    # Set working directory inside container
    working_dir: /app
    
    # Keep container running for interactive use
    stdin_open: true  # Equivalent to -i flag
    tty: true         # Equivalent to -t flag

# Named volumes for caching (persist between container restarts)
volumes:
  gradle-cache:
    name: calorie_tracker_gradle
  pub-cache:
    name: calorie_tracker_pub
```

### Step 3: Create .dockerignore

Create this file to exclude unnecessary files (`~/projects/calorie_tracker/.dockerignore`):

```
# .dockerignore
# These files don't need to be copied into the container

# Build outputs
build/
.dart_tool/
.packages

# IDE
.idea/
*.iml
.vscode/

# Git
.git/
.gitignore

# OS files
.DS_Store
Thumbs.db

# Local configuration
local.properties
*.log
```

### Step 4: Create Helper Script (Optional but Recommended)

Create `~/projects/calorie_tracker/dev.sh`:

```bash
#!/bin/bash
# dev.sh - Helper script for common Docker operations

set -e

# Colors for pretty output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get script directory (works even if called from elsewhere)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

case "${1:-help}" in
    shell|sh)
        echo -e "${GREEN}Starting Flutter development shell...${NC}"
        docker compose run --rm flutter bash
        ;;
    
    build)
        echo -e "${GREEN}Building release APK...${NC}"
        docker compose run --rm flutter bash -c "flutter pub get && flutter build apk --release"
        echo -e "${GREEN}APK location: build/app/outputs/flutter-apk/app-release.apk${NC}"
        ;;
    
    analyze)
        echo -e "${GREEN}Analyzing code...${NC}"
        docker compose run --rm flutter bash -c "flutter pub get && flutter analyze"
        ;;
    
    clean)
        echo -e "${YELLOW}Cleaning build artifacts...${NC}"
        docker compose run --rm flutter flutter clean
        ;;
    
    purge)
        echo -e "${RED}Removing containers and cached volumes...${NC}"
        docker compose down -v
        echo -e "${GREEN}Done. Run './dev.sh shell' to start fresh.${NC}"
        ;;
    
    *)
        echo "Usage: ./dev.sh <command>"
        echo ""
        echo "Commands:"
        echo "  shell    - Start interactive shell in container"
        echo "  build    - Build release APK"
        echo "  analyze  - Run Flutter analyze"
        echo "  clean    - Clean build artifacts"
        echo "  purge    - Remove containers and all cached data"
        ;;
esac
```

Make it executable:

```bash
chmod +x dev.sh
```

---

## Daily Workflow

### First Time Setup

```bash
cd ~/projects/calorie_tracker

# Pull the Flutter image (only needed once, ~3GB download)
docker compose pull

# Start a shell in the container
docker compose run --rm flutter bash

# Inside container: Get dependencies
flutter pub get

# Verify everything works
flutter doctor
flutter analyze

# Exit container
exit
```

### Regular Development Workflow

```bash
# Terminal 1: Start container shell
cd ~/projects/calorie_tracker
./dev.sh shell
# or: docker compose run --rm flutter bash

# Inside container: Build, analyze, etc.
flutter pub get          # Get dependencies
flutter analyze          # Check for issues
flutter build apk        # Build debug APK
flutter build apk --release  # Build release APK

# Meanwhile, in VS Code on your host machine:
# - Edit files normally
# - Use Codeium for AI assistance
# - Changes are instantly reflected in the container
```

### Building APK

```bash
# Quick build using helper script
./dev.sh build

# Or manually in container shell
docker compose run --rm flutter bash
flutter pub get
flutter build apk --release
exit

# APK will be at:
# ~/projects/calorie_tracker/build/app/outputs/flutter-apk/app-release.apk
```

### Installing APK on Phone

```bash
# Copy to phone via USB, email, or cloud storage
# Then install on phone (enable "Install from unknown sources")

# Or if you have ADB on your host machine:
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Common Commands

### Docker Compose Commands

```bash
# Always run these from the project directory (~/projects/calorie_tracker)

# Start interactive shell
docker compose run --rm flutter bash

# Run a single command (no shell)
docker compose run --rm flutter flutter pub get
docker compose run --rm flutter flutter analyze
docker compose run --rm flutter flutter build apk --release

# See running containers
docker compose ps

# Stop all containers for this project
docker compose down

# Stop and remove cached volumes (fresh start)
docker compose down -v
```

### Understanding the Flags

| Flag | Meaning |
|------|---------|
| `run` | Create and start a container |
| `--rm` | Remove container when it exits (keeps things clean) |
| `flutter` | Service name from docker-compose.yml |
| `bash` | Command to run inside container |

### Inside Container Commands

```bash
# These run INSIDE the container after: docker compose run --rm flutter bash

# Flutter commands
flutter doctor            # Check environment
flutter pub get           # Install dependencies
flutter pub upgrade       # Upgrade dependencies
flutter analyze           # Static analysis
flutter test              # Run tests
flutter clean             # Clean build files
flutter build apk         # Build debug APK
flutter build apk --release  # Build release APK

# Dart commands
dart format .             # Format all code
dart fix --apply          # Apply automated fixes
```

---

## Best Practices

### 1. Always Use `--rm` Flag

```bash
# Good - container is removed after exit
docker compose run --rm flutter bash

# Avoid - leaves stopped containers around
docker compose run flutter bash
```

### 2. Use Named Volumes for Caches

The `docker-compose.yml` already does this. Benefits:
- Gradle and pub caches persist between container runs
- Much faster builds after the first time
- Easy to clear with `docker compose down -v`

### 3. Don't Store Secrets in Containers

- API keys should be entered at runtime (like the Gemini key in the app)
- Never bake secrets into images

### 4. Keep Docker Images Updated

```bash
# Pull latest stable Flutter image periodically
docker compose pull
```

### 5. Use .dockerignore

Already created above. Keeps unnecessary files out of the container context.

### 6. One Project, One docker-compose.yml

Each project should have its own `docker-compose.yml` in its root directory.

### 7. Name Your Volumes per Project

```yaml
volumes:
  gradle-cache:
    name: calorie_tracker_gradle  # Project-specific name
```

This prevents cache conflicts between different projects.

---

## Troubleshooting

### "Permission denied" Error

```bash
# If you see permission errors on mounted files
sudo chown -R $USER:$USER ~/projects/calorie_tracker
```

### "Cannot connect to Docker daemon"

```bash
# Make sure Docker is running
sudo systemctl start docker

# Make sure you're in docker group
groups  # Should show 'docker'

# If not, add yourself and re-login
sudo usermod -aG docker $USER
# Then log out and log back in
```

### Flutter Doctor Shows Issues

```bash
# Inside container
docker compose run --rm flutter bash

# Accept licenses
flutter doctor --android-licenses

# Check verbose output
flutter doctor -v
```

### Build Fails with "Out of Memory"

```bash
# Increase Docker memory limit
# Docker Desktop: Settings → Resources → Memory

# Or for Linux, edit /etc/docker/daemon.json
sudo nano /etc/docker/daemon.json
# Add: { "default-shm-size": "2g" }
sudo systemctl restart docker
```

### Slow First Build

This is normal. First build downloads many dependencies:
- Gradle dependencies (~500MB)
- Android SDK components
- Pub packages

Subsequent builds use cached volumes and are much faster.

### "Image not found" Error

```bash
# Pull the image manually
docker pull ghcr.io/cirruslabs/flutter:stable

# Verify it exists
docker images | grep flutter
```

### Want a Fresh Start?

```bash
# Remove everything for this project
cd ~/projects/calorie_tracker
docker compose down -v

# Remove the Flutter image entirely (will re-download)
docker rmi ghcr.io/cirruslabs/flutter:stable

# Start fresh
docker compose pull
docker compose run --rm flutter bash
flutter pub get
```

---

## Quick Reference Card

```bash
# === SETUP (one time) ===
cd ~/projects/calorie_tracker
docker compose pull

# === DAILY USE ===
./dev.sh shell           # Start shell (recommended)
# or
docker compose run --rm flutter bash

# === BUILD ===
./dev.sh build           # Build release APK
# or (inside container)
flutter build apk --release

# === CLEANUP ===
./dev.sh clean           # Clean build files
./dev.sh purge           # Remove all cached data

# === APK LOCATION ===
# build/app/outputs/flutter-apk/app-release.apk
```

---

## Summary

1. **Install Docker** and add yourself to the `docker` group
2. **Create `docker-compose.yml`** in your project root
3. **Run `docker compose run --rm flutter bash`** to enter the container
4. **Edit code in VS Code** on your host (with Codeium)
5. **Build/analyze in the container**
6. **APK appears** in `build/app/outputs/flutter-apk/`

That's it! Your workstation stays clean, and everything Flutter-related runs in Docker.
