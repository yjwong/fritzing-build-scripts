#Requires -RunAsAdministrator
$qtOnlineInstallerEmail = ""
$qtOnlineInstallerPw = ""
$qtOnlineInstallerVersion = "4.8.0"

$ProgressPreference = 'SilentlyContinue'

function Get-QtOnlineInstaller {
    $outFile = "qt-online-installer-windows-x64-$qtOnlineInstallerVersion.exe"
    $url = "https://d13lb3tujbc8s0.cloudfront.net/onlineinstallers/$outFile"
    Invoke-WebRequest -Uri $url -OutFile $outFile
    return $outFile
}

function Install-Qt {
    $local:qtOnlineInstaller = Get-QtOnlineInstaller
    $local:qtOnlineInstallerArgs = @(
        '--email'
        $qtOnlineInstallerEmail
        '--pw'
        $qtOnlineInstallerPw
        '--mirror'
        'https://mirrors.cloud.tencent.com/qt'
        '--accept-licenses'
        '--accept-obligations'
        '--confirm-command'
        '--auto-answer'
        'telemetry-question=No,AssociateCommonFiletypes=No'
        'install'
        'qt.qt6.653.win64_msvc2019_64'
        'qt.qt6.653.src'
        'qt.qt6.653.qt5compat'
        'qt.qt6.653.debug_info'
        'qt.qt6.653.addons.qtserialport'
        'qt.tools.qtcreator_gui'
    )

    Start-Process .\$local:qtOnlineInstaller -ArgumentList $local:qtOnlineInstallerArgs -NoNewWindow -Wait
}

function Install-DesktopAppInstaller {
    Invoke-WebRequest -Uri https://globalcdn.nuget.org/packages/microsoft.ui.xaml.2.8.6.nupkg -OutFile microsoft.ui.xaml.zip
    Expand-Archive -Path microsoft.ui.xaml.zip -DestinationPath microsoft.ui.xaml
    Add-AppxPackage .\microsoft.ui.xaml\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.8.appx
    Remove-Item -Path microsoft.ui.xaml.zip -Force
    Remove-Item -Path microsoft.ui.xaml -Recurse -Force

    Invoke-WebRequest -Uri https://github.com/microsoft/winget-cli/releases/download/v1.7.11261/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile Microsoft.DesktopAppInstaller.msixbundle
    Add-AppxPackage .\Microsoft.DesktopAppInstaller.msixbundle
}

function Get-VS2022CommunityBootstrapper {
    Invoke-WebRequest -Uri https://aka.ms/vs/17/release/vs_community.exe -OutFile vs_community.exe
}

function Install-VS2022Community {
    $local:vs2022CommunityBootstrapperArgs = @(
        '--quiet'
        '--add'
        'Microsoft.VisualStudio.Workload.NativeDesktop'
        '--includeRecommended'
    )
    Start-Process .\vs_community.exe -ArgumentList $local:vs2022CommunityBootstrapperArgs -NoNewWindow -Wait
}

Write-Output "Installing Qt..."
Install-Qt

Write-Output "Upgrading Microsoft.DesktopAppInstaller..."
Install-DesktopAppInstaller

Write-Output "Installing 7zip..."
& "winget.exe" install -e --id 7zip.7zip --accept-source-agreements --accept-package-agreements

Write-Output "Installing Visual Studio 2022 Community..."
Get-VS2022CommunityBootstrapper
Install-VS2022Community

Write-Output "Installing CMake..."
& "winget.exe" install -e --id Kitware.CMake --override 'ADD_CMAKE_TO_PATH=User /qn'

Write-Output "Installing Git..."
& "winget.exe" install -e --id Git.Git --override '/VERYSILENT /EditorOption=Notepad /CRLFOption=CRLFCommitAsIs'
