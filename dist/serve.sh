#!/bin/bash

# Simple web server for testing DevLynx web build
# Usage: ./serve.sh [port]

PORT=${1:-8080}

echo "🚀 Starting DevLynx web server on port $PORT..."
echo "📱 Open http://localhost:$PORT in your browser"
echo "⏹️  Press Ctrl+C to stop"
echo ""

# Try different web servers in order of preference
if command -v python3 &> /dev/null; then
    echo "Using Python 3 HTTP server"
    cd web && python3 -m http.server $PORT
elif command -v python &> /dev/null; then
    echo "Using Python 2 HTTP server"
    cd web && python -m SimpleHTTPServer $PORT
elif command -v php &> /dev/null; then
    echo "Using PHP built-in server"
    cd web && php -S localhost:$PORT
elif command -v node &> /dev/null && command -v npx &> /dev/null; then
    echo "Using Node.js http-server (installing if needed)"
    cd web && npx http-server -p $PORT
else
    echo "❌ No suitable web server found!"
    echo "Please install one of: python3, python, php, or node.js"
    echo "Or serve the 'web' directory with your preferred web server"
    exit 1
fi
