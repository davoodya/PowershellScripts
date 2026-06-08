
# 📜 Compressor_7z.ps1 - Channel Logs

---

## Version 1: Initial Release & Bug Fixes

**Status:** ✅ Stable  
**Date:** 2026-04-06

### 📝 Description
First version of the script with basic batch compression functionality for directories using 7-Zip with maximum compression settings.

### 🔧 Features Implemented

| Feature | Description |
|---------|-------------|
| **Batch Compression** | Compress each directory/file individually in a source folder |
| **Sequential Processing** | Process items one by one to minimize system resource usage |
| **Maximum Compression** | LZMA2 method with Ultra (9) level, 256MB dictionary, 16GB solid block |
| **Folder Selection Dialog** | Opens dialog if no `-SourceDir` is provided |
| **Export Directory** | Custom output path with `-ExportDir` flag (default: same as source) |
| **English UI** | All comments and output text in English with color coding |
| **Help System** | `-h` / `-Help` flag with usage examples |
| **Bug Fix** | Fixed path handling with spaces using direct execution (`&` operator) |

### 💻 Example Usage (Version 1)

```powershell
# Interactive mode
.\Compressor_7z.ps1

# With source directory
.\Compressor_7z.ps1 -SourceDir "C:\Videos\MyFolder"

# With custom output
.\Compressor_7z.ps1 -SourceDir "C:\Data" -ExportDir "D:\Backups"

# Show help
.\Compressor_7z.ps1 -h
```

---

## Version 2: Primary Compression Options

**Status:** ✅ Stable  
**Date:** 2026-04-06

### 📝 Description
Added comprehensive compression options including format selection, compression level, method, RAM usage, and CPU threads.

### ✨ New Features Added

| Feature | Flag | Description |
|---------|------|-------------|
| **Format Selection** | `-Format` | Choose between 7z, zip, tar, wim |
| **Compression Level** | `-CompressionLevel` | 0-9 based on format |
| **Compression Method** | `-CompressionMethod` | LZMA2/LZMA/PPMd/BZip2 (7z), Deflate/Deflate64/BZip2/LZMA/PPMd (zip), GNU/Posix (tar) |
| **RAM Usage** | `-RAM` | 0-100% (7z/zip only) |
| **CPU Threads** | `-Threads` | 1-max (0=auto-detect) |
| **Validation** | - | Input validation for each format |

### 💻 Example Usage (Version 2)

```powershell
# ZIP with normal compression
.\Compressor_7z.ps1 -SourceDir "C:\Videos" -Format zip -CompressionLevel 5

# Maximum 7z with LZMA2 and 8 threads
.\Compressor_7z.ps1 -SourceDir "C:\Data" -Format 7z -CompressionLevel 9 -CompressionMethod LZMA2 -Threads 8

# TAR with Posix method
.\Compressor_7z.ps1 -SourceDir "C:\Files" -Format tar -CompressionMethod Posix

# ZIP with 30% RAM usage
.\Compressor_7z.ps1 -SourceDir "C:\Data" -Format zip -RAM 30
```

---

## Version 3: Advanced Options

**Status:** ✅ Latest  
**Date:** 2026-04-06

### 📝 Description
Added advanced compression options including dictionary size, word size, solid block size, encryption, and archive splitting.

### ✨ New Features Added

| Feature | Flag | Available Formats | Description |
|---------|------|-------------------|-------------|
| **Dictionary Size** | `-DictionarySize` | 7z, zip | Custom dictionary (e.g., 512MB, 1GB) |
| **Word Size** | `-WordSize` | 7z, zip | Fast bytes (3-273, default: 64/32) |
| **Solid Block Size** | `-SolidBlockSize` | 7z only | Custom solid block (e.g., 32GB) |
| **Encryption** | `-Encrypt` | 7z, zip | AES-256 (7z/zip), ZipCrypto (zip only) |
| **Password** | `-Password` | 7z, zip | Password for encrypted archives |
| **Split Archive** | `-Split` | All formats | Split into parts (e.g., 1500MB) |

### 💻 Example Usage (Version 3)

```powershell
# 7z with custom dictionary, word size, solid block
.\Compressor_7z.ps1 -SourceDir "C:\Data" -Format 7z -DictionarySize 512MB -WordSize 128 -SolidBlockSize 32GB

# ZIP with custom word size
.\Compressor_7z.ps1 -SourceDir "C:\Files" -Format zip -WordSize 64

# Encrypted 7z with AES-256
.\Compressor_7z.ps1 -SourceDir "C:\Data" -Format 7z -Encrypt AES-256 -Password "MyPass123"

# Encrypted ZIP with ZipCrypto
.\Compressor_7z.ps1 -SourceDir "C:\Data" -Format zip -Encrypt ZipCrypto -Password "MyPass123"

# Split archive into 1500MB parts
.\Compressor_7z.ps1 -SourceDir "C:\LargeFiles" -Split 1500MB

# Full example with all options
.\Compressor_7z.ps1 -SourceDir "C:\Data" -ExportDir "D:\Backups" -Format 7z -CompressionLevel 9 -DictionarySize 512MB -WordSize 128 -SolidBlockSize 32GB -Threads 8 -Split 1500MB
```

---

## 📊 Summary Table

| Version | Features Added | Total Features |
|---------|---------------|----------------|
| **v1** | Basic compression, Dialog, ExportDir, Sequential processing, Help, Bug fix | ~8 |
| **v2** | Format, CompressionLevel, CompressionMethod, RAM, Threads | +5 = 13 |
| **v3** | DictionarySize, WordSize, SolidBlockSize, Encrypt, Password, Split | +6 = 19 |

---

## 🚀 Current Script Capabilities

```
Supported Formats:     7z, zip, tar, wim
Compression Levels:    0-9 (Ultra = 9)
Compression Methods:  LZMA2, LZMA, PPMd, BZip2, Deflate, Deflate64, GNU, Posix
Dictionary Size:      Custom (KB/MB/GB)
Word Size:            3-273
Solid Block:          Custom (KB/MB/GB)
RAM Usage:            0-100%
CPU Threads:          1-max (0=auto)
Encryption:          AES-256, ZipCrypto
Split Size:           Custom (KB/MB/GB)
```

---

## 📋 All Available Parameters

```powershell
.\Compressor_7z.ps1 [-SourceDir <path>] [-ExportDir <path>] [-Format <type>] 
                    [-CompressionLevel <n>] [-CompressionMethod <method>]
                    [-DictionarySize <size>] [-WordSize <n>] [-SolidBlockSize <size>]
                    [-RAM <n>] [-Threads <n>] [-Encrypt <type>] [-Password <pass>]
                    [-Split <size>] [-Help]
```

---

*End of Channel Logs*