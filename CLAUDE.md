# CLAUDE.md

## Project Overview
iOS app that records videos with synchronized device sensor data and OSC (Open Sound Control) messages. The app captures video using the device camera while simultaneously collecting motion sensor data (gyroscope, accelerometer, quaternion rotation, rotation rate) and audio amplitude. This sensor data gets embedded into the video recording and can later be played back to output OSC messages for real-time control of other applications or devices.

## Key Features
- Records video with embedded OSC sensor data
- Receives and transmits OSC messages over network
- Plays back recorded videos while outputting synchronized OSC data
- Supports multiple device configurations
- Intended for performance/theatre contexts and motion-controlled applications

## Dependencies
- OSCKit
- SwiftyJSON

## Architecture
- **DeviceDataProtocol.swift**: Core protocol and implementations for handling device sensor data and OSC message conversion
- **CameraViewController.swift**: Handles video recording and OSC data embedding
- **DeviceViewController.swift**: OSC client functionality for sending/receiving data
- **OSCViewController.swift**: OSC-specific UI and controls
- **PlayerViewController.swift**: Video playback with synchronized OSC output

## Current Status
- Main development in `source/` directory
- Git status shows modifications to DeviceDataProtocol.swift
- Recent commits focus on camera functionality and cross-platform builds

## Development Notes
- Uses Xcode workspace with CocoaPods
- Supports both iOS and Catalyst (Mac) targets
- Network configuration for local development available in README