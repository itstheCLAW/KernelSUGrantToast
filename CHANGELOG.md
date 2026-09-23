# Changelog

## v3.4
- Fix sucompat detection after KSUN log format change (uid now always 0)
- Both KSUN and ReSukiSU now use comm/ppid based detection

## v3.3
- Fix midnight log rollover - wait for new date log file
- Fix log file rotation on ReSukiSU - properly kills old tail process
- Add auto-update support

## v3.2
- Fix log file rotation detection for ReSukiSU 10MB log splits
- Kill old tail process when switching to new log file

## v3.1
- Add ppid-based lookup for ReSukiSU
- Fix addon process resolution
- Fix /data/data/ path resolution for Termux

## v3.0
- Complete rewrite - file tail instead of kernel ioctl
- KSUN/SukiSU/ReSukiSU compatibility
- SuLog no longer broken after install
- Package exclusion via WebUI
