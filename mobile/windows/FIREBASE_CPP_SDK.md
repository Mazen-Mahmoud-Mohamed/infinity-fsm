# Local Windows Firebase C++ SDK (optional)
#
# firebase_core downloads firebase_cpp_sdk_windows_*.zip into the Flutter
# Windows build directory and extracts it with CMake. That step can fail when
# C: is low on disk space or the project lives under OneDrive.
#
# Recommended setup on this machine (already applied):
#   D:\infinity-fsm-deps\firebase_cpp_sdk_windows
#
# Or place the extracted SDK at:
#   mobile/windows/third_party/firebase_cpp_sdk_windows
#
# windows/CMakeLists.txt will auto-detect either path and set
# FIREBASE_CPP_SDK_DIR before plugins are configured.
#
# Android Firebase/FCM does NOT use this path.
