# GEMINI.md

## Directory Overview

This directory contains a comprehensive and modular configuration for the WezTerm terminal emulator. The configuration is written in Lua and is structured to allow for easy customization of various aspects of the terminal, from appearance and keybindings to more advanced features like GPU adapter selection and event-driven behavior.

## Key Files

*   `wezterm.lua`: The main entry point for the WezTerm configuration. It loads and combines settings from other files.
*   `config/init.lua`: A helper module that provides a structured way to build the configuration by combining multiple option tables.
*   `config/appearance.lua`: Defines the visual style of the terminal, including colors, fonts, background images, and window appearance.
*   `config/bindings.lua`: Contains all the key and mouse bindings, with platform-specific modifiers for macOS, Windows, and Linux.
*   `config/domains.lua`: For custom SSH/WSL domains.
*   `config/launch.lua`: For preferred shells and its paths.
*   `events/*.lua`: A directory with files that handle various events within WezTerm, allowing for dynamic customization of things like the status bar and tab titles.
*   `utils/*.lua`: A collection of utility modules that provide helper functions for features like managing background images and selecting GPU adapters.
*   `backdrops/`: A collection of images for the terminal background.
*   `colors/`: Custom color schemes.

## Usage

These configuration files are used by the WezTerm terminal emulator. To use this configuration, you would typically clone this repository into your `~/.config/wezterm` directory. WezTerm will automatically load the `wezterm.lua` file on startup.

The configuration is highly modular. To customize it, you can modify the files in the `config/` directory. For example, to change keybindings, you would edit `config/bindings.lua`. To add or change shell configurations for different systems, you would edit `config/launch.lua` and `config/domains.lua`.
