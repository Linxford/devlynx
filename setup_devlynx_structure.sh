#!/bin/bash

PROJECT_ROOT="$HOME/devlynx"
LIB_DIR="$PROJECT_ROOT/lib"

echo "📁 Creating DevLynx folder structure..."

mkdir -p $LIB_DIR/ui
mkdir -p $LIB_DIR/data
mkdir -p $LIB_DIR/services
mkdir -p $PROJECT_ROOT/assets
mkdir -p $PROJECT_ROOT/config
mkdir -p $PROJECT_ROOT/backend/voice
mkdir -p $PROJECT_ROOT/backend/ai

touch $LIB_DIR/ui/startup_screen.dart
touch $LIB_DIR/data/project_scanner.dart
touch $LIB_DIR/data/tool_detector.dart
touch $LIB_DIR/data/session_storage.dart
touch $LIB_DIR/services/launcher_service.dart
touch $PROJECT_ROOT/config/devlynx.service
touch $PROJECT_ROOT/README.md

echo "✅ DevLynx structure created at $PROJECT_ROOT"
