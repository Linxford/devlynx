# DevLynx Distribution

Welcome to DevLynx - An AI-powered developer assistant with voice commands and project management capabilities.

## 🚀 Available Builds

### Linux AppImage (`DevLynx-x86_64.AppImage`)
- **Platform**: Linux x86_64
- **Size**: ~20MB
- **Requirements**: Linux with glibc 2.17+ (most modern distributions)
- **Usage**: 
  ```bash
  chmod +x DevLynx-x86_64.AppImage
  ./DevLynx-x86_64.AppImage
  ```

### Web Build (`web/`)
- **Platform**: Any modern web browser
- **Size**: ~31MB
- **Requirements**: Modern browser with WebAssembly support
- **Usage**: 
  - Serve the `web/` directory using any web server
  - Or open `web/index.html` directly in browser (with limitations)

## ✨ Features

- 🎯 **Project Management**: Scan and organize development projects
- 🤖 **AI Assistant**: Integration with multiple AI providers (OpenAI, Anthropic, Groq, etc.)
- 🗣️ **Voice Commands**: Text-to-speech and voice recognition (Linux/Web)
- 📊 **Analytics Dashboard**: Project insights and metrics
- 🎨 **Modern UI**: Material 3 design with customizable themes
- ⚙️ **Settings**: Comprehensive configuration options

## 🔧 Configuration

On first run, configure:
1. **AI Settings**: Add API keys for your preferred AI providers
2. **Voice Settings**: Enable/disable voice features
3. **Project Directories**: Add your development workspace paths
4. **Theme**: Choose your preferred appearance

## 🏗️ Build Information

- **Flutter Version**: 3.24.5
- **Dart Version**: 3.5.4
- **Build Date**: $(date)
- **Platform**: Cross-platform (Linux, Web, Windows*, macOS*)

*Windows and macOS builds require native build environments

## 📝 Changelog

### Latest Release
- ✅ Fixed voice service integration with espeak-ng
- ✅ Improved AI service configuration and persistence
- ✅ Enhanced navigation and settings accessibility
- ✅ Resolved UI overflow issues in analytics dashboard
- ✅ Added comprehensive theming and customization options
- ✅ Implemented cross-platform project directory scanning
- ✅ Created portable AppImage distribution for Linux

## 🐛 Known Issues

- Voice recognition on Linux requires additional plugins (fallback to TTS only)
- Some print() statements in console (development artifacts)
- Minor deprecated API usage (Flutter updates needed)

## 🤝 Support

For issues, feature requests, or contributions, please refer to the project documentation.

---

*Built with ❤️ using Flutter*
