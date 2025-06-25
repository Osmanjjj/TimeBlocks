#!/usr/bin/env python3
"""
iOS Build Configuration Fixer
Automatically configures Xcode project settings for successful builds
"""

import os
import subprocess
import plistlib

def fix_ios_project():
    """Fix common iOS build issues"""
    print("🔧 Fixing iOS project configuration...")
    
    # 1. Update project.pbxproj for proper code signing
    pbxproj_path = "ios/Runner.xcodeproj/project.pbxproj"
    
    if os.path.exists(pbxproj_path):
        print("📝 Updating project.pbxproj...")
        
        with open(pbxproj_path, 'r') as f:
            content = f.read()
        
        # Fix code signing settings
        replacements = [
            ('CODE_SIGN_IDENTITY = "iPhone Developer";', 'CODE_SIGN_IDENTITY = "";'),
            ('CODE_SIGN_IDENTITY[sdk=iphoneos*] = "iPhone Developer";', 'CODE_SIGN_IDENTITY[sdk=iphoneos*] = "";'),
            ('DEVELOPMENT_TEAM = "";', 'DEVELOPMENT_TEAM = "";'),
            ('PROVISIONING_PROFILE_SPECIFIER = "";', 'PROVISIONING_PROFILE_SPECIFIER = "";'),
        ]
        
        for old, new in replacements:
            content = content.replace(old, new)
        
        # Ensure proper deployment target
        if 'IPHONEOS_DEPLOYMENT_TARGET = 13.0;' not in content:
            content = content.replace('IPHONEOS_DEPLOYMENT_TARGET = 12.0;', 'IPHONEOS_DEPLOYMENT_TARGET = 13.0;')
            content = content.replace('IPHONEOS_DEPLOYMENT_TARGET = 11.0;', 'IPHONEOS_DEPLOYMENT_TARGET = 13.0;')
        
        with open(pbxproj_path, 'w') as f:
            f.write(content)
        
        print("✅ Updated project.pbxproj")
    
    # 2. Clean and rebuild pods
    print("🧹 Cleaning and rebuilding CocoaPods...")
    
    os.chdir("ios")
    
    # Remove existing pods
    if os.path.exists("Podfile.lock"):
        os.remove("Podfile.lock")
    if os.path.exists("Pods"):
        subprocess.run(["rm", "-rf", "Pods"], check=False)
    
    # Reinstall pods
    result = subprocess.run(["pod", "install", "--repo-update"], 
                          capture_output=True, text=True)
    
    if result.returncode == 0:
        print("✅ CocoaPods installed successfully")
    else:
        print(f"⚠️  CocoaPods warning: {result.stderr}")
    
    os.chdir("..")
    
    # 3. Update Info.plist for better compatibility
    info_plist_path = "ios/Runner/Info.plist"
    if os.path.exists(info_plist_path):
        print("📱 Updating Info.plist...")
        
        with open(info_plist_path, 'rb') as f:
            plist_data = plistlib.load(f)
        
        # Ensure minimum iOS version
        plist_data['MinimumOSVersion'] = '13.0'
        
        # Add required keys for modern iOS
        if 'ITSAppUsesNonExemptEncryption' not in plist_data:
            plist_data['ITSAppUsesNonExemptEncryption'] = False
        
        with open(info_plist_path, 'wb') as f:
            plistlib.dump(plist_data, f)
        
        print("✅ Updated Info.plist")
    
    print("🎉 iOS project configuration completed!")

def test_build():
    """Test the build after fixes"""
    print("\n🧪 Testing build...")
    
    # Try simulator build first
    result = subprocess.run([
        "./flutter/bin/flutter", "build", "ios", "--simulator", "--debug"
    ], capture_output=True, text=True)
    
    if result.returncode == 0:
        print("✅ Simulator build successful!")
        return True
    else:
        print(f"❌ Simulator build failed: {result.stderr}")
        return False

if __name__ == "__main__":
    print("🚀 Starting iOS build configuration fix...")
    
    try:
        fix_ios_project()
        
        # Test the build
        if test_build():
            print("\n🎉 All fixes applied successfully!")
            print("📱 Your iOS app is ready for development and testing.")
        else:
            print("\n⚠️  Build still has issues. Manual Xcode configuration may be needed.")
            print("💡 Try opening ios/Runner.xcworkspace in Xcode and check:")
            print("   - Signing & Capabilities tab")
            print("   - Deployment Target (should be 13.0+)")
            print("   - Bundle Identifier")
            
    except Exception as e:
        print(f"❌ Error during configuration: {e}")
        print("💡 Please check Xcode project settings manually.")
