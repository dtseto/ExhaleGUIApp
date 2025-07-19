ExhaleGUI
A modern macOS application that provides an intuitive graphical interface for the Exhale high-quality XE AAC audio encoder.

XE AAC is a format that can create fm / cd quality at extremely low bitrates 36-48kb stereo with esbr.

I created this after finding the fre ac mac gui did not support newer exhale versions.

Overview
ExhaleGUI simplifies the process of converting audio files to high-quality AAC format using the Exhale encoder. With support for batch processing, parallel conversions, and multiple input formats, it's designed to make professional audio encoding accessible through a clean, native macOS interface.
Features
🎵 Multi-Format Support

Input formats: WAV, MP3, FLAC, M4A, AAC
Output format: M4A (AAC) using Exhale encoder
Smart conversion: Automatically handles format conversion via bundled FFmpeg

⚡ Batch Processing

Drag-and-drop multiple files at once
Parallel conversion (1-8 concurrent processes)
Real-time progress tracking for each file
Queue management with add/remove capabilities

🎛️ Quality Presets
Choose from Exhale's comprehensive quality options:

Standard HE-AAC (0-9): 48 kbps to 192+ kbps
eSBR Low-Bitrate (a-g): 36-108 kbps for efficient encoding
Preset 5 (128 kbps) set as default for optimal quality/size balance

🔧 Advanced Options

Metadata preservation: Maintain ID tags from source files (note most players do not support tags for xe aac)
Source file management: Optional deletion after successful conversion
Custom temp directories: Configure temporary file locations
Exhale binary configuration: Point to your Exhale installation (suggest using exhale and gui in downloads folder)

💻 Native macOS Experience

Clean, modern SwiftUI interface
Drag-and-drop file handling
Settings tabs for easy configuration
Real-time conversion status updates

Requirements

macOS 11.0+ (Big Sur or later)
Exhale encoder binary - Download from GitLab
Intel or Apple Silicon Mac (Universal support)

Installation

Download ExhaleGUI from the releases page and exhale from releases page

To build download ffmpeg from releases page

Configure Exhale path in ExhaleGUI Settings → General → Executable Path

Usage
Basic Conversion

Launch ExhaleGUI
Drag audio files onto the drop zone or click "Add Files"
Select desired quality preset (default: 5 - ~128 kbps)
Click "Start Conversion"

Quality Settings

Preset 0: ~48 kbps (lowest, ≤32kHz sample rate only)
Preset 5: ~128 kbps (recommended default)
Preset 9: ~192+ kbps (highest quality)
Presets a-g: eSBR encoding for lower bitrates (36-108 kbps)

Advanced Features

Parallel conversions: Adjust in Settings → Advanced (default: 2)
Metadata preservation: Enable in Settings → General
Source file deletion: Enable with caution in Settings → General

Technical Details
Conversion Process

WAV files: Direct conversion using Exhale
Other formats: Two-step process:

Step 1: Convert to WAV using bundled FFmpeg
Step 2: Encode to M4A using Exhale



Performance

Utilizes multiple CPU cores for parallel processing
Efficient memory usage during batch conversions
Progress tracking with estimated completion times

Troubleshooting
Common Issues
"Exhale executable not found"

Ensure Exhale is installed and path is correctly set in Settings
Verify the binary has execute permissions: chmod +x /path/to/exhale

"Sample rate too high for Preset 0"

Use presets 1-9 or a-g for files with >32kHz sample rate
Preset 0 only supports ≤32kHz audio

Conversion fails

Check input file integrity
Verify sufficient disk space
Try a different quality preset
Check console output for detailed error messages

Debug Tools

Test Exhale Binary: Settings → Advanced → Debug section
Test Bundled FFmpeg: Verify internal FFmpeg functionality
Console output: Detailed logging for troubleshooting

About Exhale
Exhale is a state-of-the-art AAC encoder that provides:

High-quality audio encoding
Efficient compression ratios
Support for various AAC profiles
Optimized for both quality and file size

Development
Built with Xcode

SwiftUI for modern macOS interface
AVFoundation for audio metadata handling
Combine for reactive programming
Process for external tool integration
Third-Party Components
FFmpeg
This application includes FFmpeg, which is licensed under the LGPL v2.1 or later.

FFmpeg website: https://ffmpeg.org/
Source code: https://github.com/FFmpeg/FFmpeg
License: LGPL v2.1+ (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html)

FFmpeg is used for audio format conversion (MP3, FLAC → WAV) and is included as a bundled binary. The FFmpeg source code and build instructions are available at the links above.
Exhale Encoder
ExhaleGUI serves as a graphical interface for the Exhale AAC encoder:

Exhale project: https://gitlab.com/ecodis/exhale
License: Please refer to the Exhale project for current licensing terms
Note: Exhale is a separate download and not included with ExhaleGUI

License & Disclaimer
ExhaleGUI is released under [your chosen license].
FFmpeg Disclaimer: This software uses libraries from the FFmpeg project under the LGPL v2.1. FFmpeg source code is available at https://ffmpeg.org/download.html. ExhaleGUI does not claim any rights to FFmpeg and complies with LGPL redistribution requirements.
Exhale Disclaimer: ExhaleGUI is an independent third-party interface and is not affiliated with or endorsed by the Exhale encoder development team. Users must obtain Exhale separately and comply with its licensing terms.
Contributing
Issues and feature requests are welcome! Please check the existing issues before creating new ones.

Note: ExhaleGUI is a third-party interface for the Exhale encoder and is not affiliated with the Exhale development team.
