# Configure SFML project automatically.
#
# Requirements:
# 1. Visual Studio 2026
# 2. Have downloaded SFML from  http://www.sfml-dev.org/download.php, I am using 3.0.2.
# 3. Have C++ console project created and NOT OPEN. Make sure it is CLOSED.
#
# Inputs: 
# 1. File path to .vcxproj file
# 2. File path to SFML root directory
#
# This script will:
# 1. Prompt you for the inputs
# 2. Set Additional Include/Library Directories, as well as Linker Dependencies
# 3. Copy DLLs from the SFML root dir into your new project
#
# NOTE: After this script is ran you will need to reload your solution

# Prompt user for inputs
param(
    [string]$VcxprojPath = $(Read-Host 'Enter the full path to your .vcxproj file'),
    [string]$SFMLRoot = $(Read-Host 'Enter the path to your SFML root directory (e.g., C:\SFML\SFML-2.6.0)'),
    [string]$Config = 'Debug'
)

# Test if project file exists:
if (!(Test-Path $VcxprojPath)) {
    Write-Error "Project file not found: $VcxprojPath"
    exit 1
}

# Set SFML paths
$sfmlInclude = Join-Path $SFMLRoot 'include'
$sfmlLib = Join-Path $SFMLRoot 'lib'
$sfmlBin = Join-Path $SFMLRoot 'bin'

# Update .vcxproj for SFML include/lib paths and dependencies
[xml]$proj = Get-Content $VcxprojPath

function Set-Property($proj, $groupName, $propertyName, $value, $condition) {
    $group = $proj.Project.ItemDefinitionGroup | Where-Object { $_.Condition -eq $condition }
    if (-not $group) {
        $group = $proj.CreateElement('ItemDefinitionGroup', $proj.Project.NamespaceURI)
        $group.SetAttribute('Condition', $condition)
        $proj.Project.AppendChild($group) | Out-Null
    }
    $section = $group.SelectSingleNode($groupName)
    if (-not $section) {
        $section = $proj.CreateElement($groupName, $proj.Project.NamespaceURI)
        $group.AppendChild($section) | Out-Null
    }
    $property = $section.SelectSingleNode($propertyName)
    if (-not $property) {
        $property = $proj.CreateElement($propertyName, $proj.Project.NamespaceURI)
        $section.AppendChild($property) | Out-Null
    }
    $property.InnerText = $value
}

$condition = "'`$(Configuration)|`$(Platform)'=='$Config|x64'"

# Set AdditionalIncludeDirectories
Set-Property $proj 'ClCompile' 'AdditionalIncludeDirectories' "$sfmlInclude;%(AdditionalIncludeDirectories)" $condition
# Set AdditionalLibraryDirectories
Set-Property $proj 'Link' 'AdditionalLibraryDirectories' "$sfmlLib;%(AdditionalLibraryDirectories)" $condition
# Set AdditionalDependencies
$sfmlLibs = 'sfml-graphics-d.lib;sfml-window-d.lib;sfml-system-d.lib;sfml-network-d.lib;sfml-audio-d.lib;%(AdditionalDependencies)'
Set-Property $proj 'Link' 'AdditionalDependencies' $sfmlLibs $condition

$proj.Save($VcxprojPath)
Write-Host "Updated $VcxprojPath with SFML settings."

# Copy DLLs to new project
$projectDir = Split-Path $VcxprojPath
$outputDir = Join-Path $projectDir $Config
if (!(Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir | Out-Null }

Write-Host "Copying SFML DLLs..."
Copy-Item "$sfmlBin\*.dll" $outputDir -Force

Write-Host "SFML Visual Studio project configuration complete!"
Write-Host "You can now build and run your project."

