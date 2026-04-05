#!/usr/bin/env python3
"""
Auto-version bump script for Flutter pubspec.yaml
Increments version based on change magnitude:
- Major (breaking changes): 1.0.0 → 2.0.0
- Minor (new features):     1.0.0 → 1.1.0
- Patch (bug fixes):         1.0.0 → 1.0.1
Also increments build number: 1.0.0+1 → 1.0.0+2
"""
import re
import sys
import subprocess

def get_commit_messages():
    """Get commit messages since last tag or initial commit"""
    try:
        # Get commits after last tag
        result = subprocess.run(
            ['git', 'log', '--format=%s', '-20'],
            capture_output=True, text=True
        )
        return result.stdout.strip().split('\n')
    except:
        return []

def analyze_changes():
    """Analyze commits to determine change magnitude"""
    commits = get_commit_messages()
    messages = ' '.join(commits).lower()
    
    major_keywords = ['breaking', 'migration', 'refactor', 'restructure']
    minor_keywords = ['add', 'new', 'feature', 'implement', 'create', 'support']
    patch_keywords = ['fix', 'bug', 'repair', 'improve', 'update', 'ui', 'ux', 'tweak', 'enhance']
    
    has_major = any(k in messages for k in major_keywords)
    has_minor = any(k in messages for k in minor_keywords)
    has_patch = any(k in messages for k in patch_keywords)
    
    if has_major:
        return 'major'
    elif has_minor:
        return 'minor'
    elif has_patch:
        return 'patch'
    return 'patch'  # Default to patch

def bump_version(version_str, bump_type):
    """Bump version based on type"""
    # Parse version: "1.0.0+1" or "1.0.0"
    match = re.match(r'^(\d+)\.(\d+)\.(\d+)\+?(\d*)$', version_str)
    if not match:
        return version_str
    
    major, minor, patch, build = int(match.group(1)), int(match.group(2)), int(match.group(3)), int(match.group(4)) if match.group(4) else 0
    
    if bump_type == 'major':
        major += 1
        minor = 0
        patch = 0
    elif bump_type == 'minor':
        minor += 1
        patch = 0
    elif bump_type == 'patch':
        patch += 1
    
    build += 1
    return f"{major}.{minor}.{patch}+{build}"

def update_pubspec(new_version):
    """Update version in pubspec.yaml"""
    with open('pubspec.yaml', 'r') as f:
        content = f.read()
    
    new_content = re.sub(
        r'^version:\s*\S+$',
        f'version: {new_version}',
        content,
        flags=re.MULTILINE
    )
    
    with open('pubspec.yaml', 'w') as f:
        f.write(new_content)
    
    print(f"Version bumped to: {new_version}")

if __name__ == '__main__':
    bump_type = sys.argv[1] if len(sys.argv) > 1 else analyze_changes()
    
    with open('pubspec.yaml', 'r') as f:
        current_version = re.search(r'^version:\s*(\S+)$', f.read(), re.MULTILINE).group(1)
    
    new_version = bump_version(current_version, bump_type)
    update_pubspec(new_version)
