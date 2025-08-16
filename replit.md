# Accounting Notebook

## Overview

Accounting Notebook is an interactive Android application designed for accounting students to create structured notes with embedded accounting tools. The app provides a WYSIWYG-like editor that allows students to organize their content in a hierarchical structure (Subject → Lesson → Subheading → Content) while seamlessly integrating specialized accounting tools like Journal entries, Amortization tables, and Custom tables directly within their notes.

The application is built using Flutter for cross-platform compatibility and features a responsive design with a collapsible sidebar for navigation and a main content pane for editing. The app operates offline-first with local data persistence and includes export/import functionality for sharing notebooks.

## Recent Changes

**January 16, 2025**
- ✓ Migrated from SQLite/Drift to shared_preferences with JSON serialization for web compatibility
- ✓ Fixed all Flutter compilation errors and web loading issues
- ✓ Added complete Android project structure with proper package naming (com.accountingnotebook.app)
- ✓ Successfully running on Flutter web at port 5000
- ✓ Prepared for APK generation with updated Android configuration

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Frontend Architecture
- **Framework**: Flutter (Dart) for cross-platform development
- **UI Pattern**: Responsive design with sidebar navigation and main content area
- **Editor**: WYSIWYG-style rich text editor with custom embedded widgets
- **Navigation**: Hierarchical tree structure (Subject → Lesson → Content blocks)
- **Interaction Model**: Modal-based tool insertion with `/command` shortcuts and toolbar buttons

### Content Management
- **Data Structure**: Hierarchical content organization with subjects containing lessons containing content blocks
- **Content Block Types**: Headings, paragraphs, lists, images, links, and embedded accounting tools
- **Tool Integration**: Three main accounting tools (Journal, Amortization, Custom Table) with dual UI pattern:
  - Input interface: Modal forms for data entry
  - Display interface: Embedded tables within content flow

### State Management
- **Local State**: Flutter's built-in state management for UI interactions
- **Data Persistence**: Local storage using sqflite/Drift for offline-first operation
- **Content Serialization**: JSON-based format for export/import functionality

### Input Handling
- **Rich Text Editing**: WYSIWYG editor with formatting capabilities
- **Keyboard Shortcuts**: Command palette triggered by `Ctrl+K` or `/`
- **Tool Insertion**: Modal-based workflow for accounting tool configuration
- **Image Handling**: Support for both URL references and local uploads

### Data Layer
- **Storage Strategy**: Local SQLite database for offline operation
- **Schema Design**: Normalized structure for subjects, lessons, and content blocks
- **Export Format**: JSON serialization for data portability
- **Search Capabilities**: Tag-based filtering and content search

## External Dependencies

### Core Framework
- **Flutter SDK**: Cross-platform mobile development framework
- **Dart Runtime**: Programming language and runtime environment

### Database and Storage
- **sqflite**: SQLite database plugin for Flutter
- **Drift** (optional): Type-safe database layer for complex queries
- **path_provider**: File system access for local storage

### UI and Rich Text
- **flutter_quill** or **flutter_html_editor**: Rich text editing capabilities
- **flutter_widget_from_html**: HTML content rendering
- **image_picker**: Camera and gallery access for image uploads

### Utilities
- **json_serializable**: JSON serialization/deserialization
- **shared_preferences**: Simple key-value storage
- **file_picker**: File system interaction for import/export

### Platform Integration
- **Android SDK**: Target platform for APK generation
- **platform_detect**: Platform-specific functionality detection

### Optional Enhancements
- **flutter_localizations**: Internationalization support
- **provider** or **riverpod**: Advanced state management (if needed)
- **flutter_launcher_icons**: Custom app icon generation