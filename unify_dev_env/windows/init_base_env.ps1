
# Copyright (c) 2022 The VolcEngineRTC project authors. All Right Reserved.
#Requires -RunAsAdministrator
<#
    the script will install base cmdlet tools:
        -  choco >= 1.2.0
        -  python-3.10.8
        -  git-2.38.1
        -  git-lfs-3.2.0
        -  cmake 3.24.1
        -  nasm 2.15.05
        -  ninja 1.11.1
        -  StrawberryPerl 5.32.1.1
        -  rtcbuild release version
    the script will config:
        - gitconfig for bytedance gitlab

    the script will install base local dev IDE tools:
        -  vscode
        # for windows dev
        -  visual studio 2019
        -  windows platform sdk
        # for android dev
        -  android studio
        -  jdk
        -  ndk
        -  android sdk
        -  qt5.14.2

    after run this script, you can git clone repo from gitlab
#>

param([string]$help = "", [string]$userName = "", [string]$install_as = "true", [string]$install_qt = "true")

$checklist = @{
    "winget"  = "v1.0"
    "choco"   = "1.2.0"
    "python3" = "Python 3.10.8"
    "git"     = "git version 2.38.1.windows.1"
    "git-lfs" = "git-lfs/3.2.0 (GitHub; windows amd64; go 1.18.2)"
    "code"    = "1.73.1"
    "java"    = "11.0.17"
    "cmake"   = "cmake version 3.24.3"
    "ninja"   = "1.11.1"
    "nasm"    = ""
    "perl"    = ""
}

# define some functions
function Checkpoint-GlobalParam {
    param(
        $param
    )
    if (-not $param) {
        Write-Error "you need to config git, but userName not found, please run script with -userName"
        Exit
    }
}

function Test-Command {
    param (
        [string]$command, [bool]$printVersion
    )
    $commandStatus = $False
    $null = Get-Command $command
    if ($?) {
        if ($command -eq "python3" -and (-not $(."$command" --version))) {
            Out-ColorMessage -Message "$command not found"
            $commandStatus = $False
            return $commandStatus
        }
        Out-ColorMessage -Message "$command has been installed"
        if ($printVersion) {
            $commandVersion = $(Invoke-Expression "$command --version")
            Out-ColorMessage -Message "$command's version is: $commandVersion"
            # compare command's version
            switch ($command) {
                { $_ -eq "code" } { 
                    if ($command -in $checklist.Keys) {
                        if ($commandVersion.Split(" ")[0] -ge $checklist["$command"]) { $commandStatus = $True; break }
                    }
                }
                { $_ -eq "java" } {
                    if ($command -in $checklist.Keys) {
                        if ($commandVersion.Split(" ")[1] -ge $checklist["$command"]) { $commandStatus = $True; break }
                    }
                }
                Default {
                    if ($command -in $checklist.Keys) {
                        if (($checklist["$command"] -eq "") -or ($commandVersion -ge $checklist["$command"])) { $commandStatus = $True }
                    }
                }
            }
        }
    }
    else {
        # please check your network, open vpn and retry again!
        Out-ColorMessage -Message "$command not found"
        $commandStatus = $False
    }
    return $commandStatus
}

function Test-GitAuth {
    if ($Env:BITS_CLOUD_BUILD_ENV) {
        return
    }
    if (-not (Test-Path $home\.gitconfig)) {
        Checkpoint-GlobalParam -param $userName
        New-Item -Path $home -Name .gitconfig -ItemType file
        Out-ColorMessage -Message "userName: $userNasme, please make sure userName is same with your bytedance email prefix!"
        $gitconfigContent = '
        [init]
            templatedir = {0}/.gittemplates
        [user]
            name = {1}
            email = {1}@bytedance.com
        [url "ssh://{1}@git.byted.org:29418"]
            insteadOf = https://git.byted.org 
        [url "git@code.byted.org:"]
            insteadOf = https://code.byted.org/
        ' -f $home.Replace("\", "/"), $userName
        $gitconfigContent | Out-File "$home\.gitconfig" -Encoding utf8
    }

    if (-not (Test-Path $home\.ssh\config)) {
        Checkpoint-GlobalParam -param $userName
        if (Test-Path $home\.ssh) {
            Remove-Item $home\.ssh -Recurse
        }
        New-Item -Path $home -Name .ssh -ItemType directory
        New-Item -Path $home\.ssh -Name config -ItemType file
        $sshconfigContent = "
        Host *
            GSSAPIAuthentication yes
            GSSAPIDelegateCredentials no
        Host git.byted.org
            Hostname git.byted.org
            Port 29418
            User $userName
        Host review.byted.org
            Hostname git.byted.org
            Port 29418
            User $userName
        Host *.byted.org
            GSSAPIAuthentication yes
            User $userName"
        # powershell 5.x will generator utf8 file with bom, but git can't recognize it, so we write file with python3 to generator utf8 file without bom
        # $sshconfigContent | Out-File $home\.ssh\config -Encoding utf8
        'with open("{0}","w",encoding="utf-8") as f:' -f "$home\.ssh\config".Replace("\", "/") | Out-File $home\write.py -Encoding utf8
        Add-Content -Path $home\write.py -Value ('   f.write("""{0}""")' -f $sshconfigContent) -Encoding utf8
        python3 $home\write.py
        Remove-Item $home\write.py
    }
    if (-not (Test-Path $home\.ssh\id_ed25519.pub)) {
        Checkpoint-GlobalParam -param $userName
        $null = Test-Command -command ssh-keygen -printVersion $False
        Out-ColorMessage -Message "generate your ssh key, please press enter and continue!!!"
        ssh-keygen -t ed25519 -C "$userName@bytedance.com"
        
        # after generater ssh key, please go to GitLab configuration page: https://code.byted.org/profile/keys
        if (Test-Path $home\.ssh\id_ed25519.pub) {
            $sshkeyContent = Get-Content "$home\.ssh\id_ed25519.pub"
            Out-ColorMessage -Message "your ssh key is: $sshkeyContent"
            Out-ColorMessage -Message "now please visit https://code.byted.org/profile/keys to config your gitlab sshkey, after config, you need input Y, else input N"
            $userResult = Read-Host "are you finish gitlab sshkey configuration?"
            if ($userResult -eq "Y") {
                Out-ColorMessage -Message "use command: ssh -T code.byted.org to check your git access right"
                Out-ColorMessage -Message "please press yes to continue!!!"
                $gitSshStatus = ssh -T code.byted.org |  Select-String "Welcome to Gitlab, $userName"
                if ($gitSshStatus) {
                    Out-ColorMessage -Message "configurations! you has finished your git sshkey config, now you can git clone gitlab repo"
                }
                else {
                    Out-ColorMessage -Message "config gitlab sshkey failed, please check -userName and config gitlab sshkey on https://code.byted.org/profile/keys"
                    Exit
                }
            }
            else {
                Out-ColorMessage -Message "config gitlab sshkey failed, please config gitlab sshkey on https://code.byted.org/profile/keys"
                Exit
            }
        }
    }
}

function Install-Choco {
    param (
        [int]$retryCount
    )
    $status = $False
    for ($i = 0; $i -lt $retryCount; $i++) {
        Set-ExecutionPolicy Bypass -Scope Process -Force;
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        if (Get-Command choco.exe) {
            $status = $True
            break
        }
    }
    if (-not $status) {
        Out-ColorMessage -Message "install chocolatey failed after $retryCount retry, please check your network!"
        Exit
    }
}
function Out-ColorMessage {
    param (
        [string]$ForegroundColor = "yellow", [string]$BackgroundColor = "black", [string]$Message
    )
    Write-Host $Message -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
}

function Out-InstallMessage {
    param (
        [string]$command
    )
    Out-ColorMessage -Message "install $command, please wait for a moment"
}
function Invoke-FileDownload {
    param (
        [string]$Uri, [string]$OutFile, [int]$RetryCount = 3
    )
    $downloadStatus = $False
    for ($i = 0; $i -lt $RetryCount; $i++) {
        <# Action that will repeat until the condition is met #>
        if (-not $downloadStatus) {
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile
            if (Test-Path $OutFile) {
                $downloadStatus = $True
                break
            }
        }
    }
    return $downloadStatus
    
}

function Invoke-InstallAndroidTools {
    param (
        [string]$SdkmanagerPath, [string]$AndroidHome = [Environment]::GetEnvironmentVariable('ANDROID_SDK_ROOT', 'Machine'), [string]$ToolsType, [string]$ToolsVersion 
    )
    if ($ToolsType -eq "platform-tools") {
        if (-not $(Test-Path "$AndroidHome\$ToolsType")) {
            Out-ColorMessage -Message "start install android tools: $ToolsType"
            ."$androidSdkManager" --install "$ToolsType"
        }
    }
    elseif (-not $(Test-Path "$AndroidHome\$ToolsType\$ToolsVersion")) {
        Out-ColorMessage -Message "start install android tools: $ToolsType;$ToolsVersion"
        ."$androidSdkManager" --install "$ToolsType;$ToolsVersion"    
    }
    
}

if ($help -eq "help" -or $help -eq "h") {
    Out-ColorMessage -Message "Usage: .\init_base_env.ps1 [OPTIONS]`n`nOptions:`n  -useName [userName]: input your email prefix`n  -install_as [true or false]: install android studio or not`n  -install_qt [true or false]: install qt5.14.2 or not
    `nExamples:`n  .\init_base_env.ps1 -install_qt false"
    Exit
}

# step0: check current os's version and install winget, os'version need >= 1809 to use winget
$computerInfo = Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer
Out-ColorMessage -Message "$computerInfo"
$windowsOSVersion = $computerInfo.WindowsVersion
if ($windowsOSVersion -lt 1809) {
    Out-ColorMessage -Message "Error: windows' version is $windowsOSVersion, you need to upgrade windows version which is equal or greater than 1809 first!"
    Exit
}

if (-not $(Test-Command -command winget -printVersion $True)) {
    Out-InstallMessage -command winget
    # https://github.com/microsoft/winget-cli/releases/download/v1.3.2691/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
    $wingetUri = "https://github.com/microsoft/winget-cli/releases/download/v1.3.2691/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    Invoke-FileDownload -Uri $wingetUri -OutFile $home\winget.msixbundle
    if (Test-Path $home\winget.msixbundle) {
        Add-AppxPackage -Path $home\winget.msixbundle -DependencyPath $home\winget.msixbundle
    }
    Remove-Item $home\winget.msixbundle
}
# make sure user input username when first use git
if (-not (Test-Path $home\.ssh\id_ed25519.pub)) {
    Checkpoint-GlobalParam -param $userName
}

# step1: install chocolatey and update chocolatey
if (-not $(Test-Command -command choco -printVersion $True)) {
    Out-InstallMessage -command choco
    Install-Choco -retryCount 3
}

if ($(choco.exe --version) -lt "1.2.0") {
    Out-ColorMessage -Message "update chocolatey, please wait for a moment"
    choco upgrade chocolatey -y
}


# step2: install python3
# install pyenv-win and python3.10.8, use pyenv-win to manage python env, https://github.com/pyenv-win/pyenv-win, this will cause android'cmake can't find python3
# if (-not $(Test-Command -command pyenv  -printVersion $True)) {
#     Out-InstallMessage -command pyenv-win
#     Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "./install-pyenv-win.ps1"; &"./install-pyenv-win.ps1"
# }
# pyenv install 3.10.8
# pyenv rehash
# pyenv global 3.10.8

if (-not $(Test-Command -command python3 -printVersion $True)) {
    Out-InstallMessage -command python-3.10.8
    # remove WindowsApps's python3
    if (Test-Path $home\AppData\Local\Microsoft\WindowsApps\python.exe) {
        Remove-Item -Path $home\AppData\Local\Microsoft\WindowsApps\python.exe -Force
    }
    if (Test-Path $home\AppData\Local\Microsoft\WindowsApps\python3.exe) {
        Remove-Item -Path $home\AppData\Local\Microsoft\WindowsApps\python3.exe -Force
    }
    choco install python3 --version 3.10.8 --params "/InstallDir:C:\Python310 /NoLockdown" -y --force
    New-Item -Path C:\Python310\python3.exe -ItemType SymbolicLink -Value C:\Python310\python.exe -Force
}
# install base pip packages
python3 -m pip install requests, psutil, PyYAML

# step3: install git and git-lfs
if (-not $(Test-Command -command git -printVersion $True)) {
    Out-InstallMessage -command git-2.38.1
    choco install git.install --version 2.38.1 --params "'/GitAndUnixToolsOnPath /NoGitLfs /NoAutoCrlf'" -y
}

if (-not $(Test-Command -command git-lfs  -printVersion $True)) {
    Out-InstallMessage -command git-lfs-3.2.0
    choco install git-lfs -y --version 3.2.0
    git-lfs install
}
# step4: config git sshkey, make sure your PC has been installed OpenSSH Client
$gitSshStatus = "yes" | ssh -T code.byted.org |  Select-String "Welcome to Gitlab,"
if (-not $gitSshStatus) {
    Test-GitAuth 
}

# step5: install cmake nasm ninja StrawberryPerl
if (-not $(Test-Command -command cmake -printVersion $True)) {
    Out-InstallMessage -command cmake-3.24.3
    choco install cmake --version 3.24.3 --installargs 'ADD_CMAKE_TO_PATH=System' -y
}
if (-not $(Test-Command -command nasm -printVersion $True)) {
    Out-InstallMessage -command nasm-2.15.05
    choco install nasm --version 2.15.05 -y
    # set env
    [environment]::SetEnvironmentvariable("PATH", "$([environment]::GetEnvironmentvariable("Path", "Machine"));C:\Program Files\NASM", "Machine")
}
if (-not $(Test-Command -command ninja -printVersion $True)) {
    Out-InstallMessage -command ninja-1.11.1
    choco install ninja --version 1.11.1 -y
}
if (-not $(Test-Command -command perl -printVersion $True)) {
    Out-InstallMessage -command StrawberryPerl-5.32.1.1
    choco install StrawberryPerl --version 5.32.1.1 -y
    # set env
    [environment]::SetEnvironmentvariable("PATH", "$([environment]::GetEnvironmentvariable("Path", "Machine"));C:\Strawberry\perl\bin", "Machine")
}


# step6: install rtcbuild, because rtcbuild is refactoring, temporarily install rtcbuild cmd tool from local!
# install rtcbuild from local, not remote

# step7: install vscode >= 1.73.1
if (-not $(Test-Command -command code  -printVersion $True)) {
    Out-InstallMessage -command vscode
    choco install vscode -y
}

# step8: use 16.11.21 buildtools to install visual studio 2019
if (-not $(Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\")) {
    Out-ColorMessage -Message "start install visual studio 2019, please wait a long time!"
    if ($Env:BITS_CLOUD_BUILD_ENV) {
        $vsBuildToolsUrl = "http://tosv.byted.org/obj/rtcsdk/build_env_install/windows/vs_BuildTools_16.11.21.exe"
        if (-not $(Test-Path $home\vs_IntsallTools_16.11.21.exe)) {
            Invoke-FileDownload -Uri $vsBuildToolsUrl -OutFile $home\vs_BuildTools_16.11.21.exe
        }
        ."$home\vs_BuildTools_16.11.21.exe" --quiet --wait --norestart --nocache install `
            --installPath "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools" `
            --add Microsoft.VisualStudio.Workload.VCTools `
            --includeRecommended `
            --add Microsoft.VisualStudio.Component.VC.Modules.x86.x64 `
            --add Microsoft.VisualStudio.Component.VC.ATLMFC `
            --add Microsoft.VisualStudio.Component.VC.Tools.ARM64 `
            --add Microsoft.VisualStudio.Component.VC.ATL.ARM64 `
            --add Microsoft.VisualStudio.Component.VC.MFC.ARM64 `
            --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 `
            --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 `
            --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 `
            --remove Microsoft.VisualStudio.Component.Windows81SDK
        Out-ColorMessage -Message "visual studio 2019 is being installed..."
        if ($? -and $(Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\")) {
            Out-ColorMessage -Message "install visual studio 2019 success!!"
        } 
        Remove-Item -Path "$home\vs_BuildTools_16.11.21.exe" -Force
    }
    else {
        $vsBuildToolsUrl = "http://tosv.byted.org/obj/rtcsdk/build_env_install/windows/vs_Community_16.11.21.exe"
        if (-not $(Test-Path $home\vs_IntsallTools_16.11.21.exe)) {
            Invoke-FileDownload -Uri $vsBuildToolsUrl -OutFile $home\vs_Community_16.11.21.exe
        }
        # before install, we will delete the original
        ."$home\vs_Community_16.11.21.exe" uninstall -p --wait --installPath "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community"
        ."$home\vs_Community_16.11.21.exe" -p --norestart --wait --nocache `
            --installPath "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community" `
            --add Microsoft.VisualStudio.Workload.CoreEditor `
            --add Microsoft.VisualStudio.Workload.NativeDesktop `
            --includeRecommended `
            --add Microsoft.VisualStudio.Component.VC.Modules.x86.x64 `
            --add Microsoft.VisualStudio.Component.VC.ATLMFC `
            --add Microsoft.VisualStudio.Component.VC.Tools.ARM64 `
            --add Microsoft.VisualStudio.Component.VC.ATL.ARM64 `
            --add Microsoft.VisualStudio.Component.VC.MFC.ARM64 `
            --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 `
            --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 `
            --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 `
            --remove Microsoft.VisualStudio.Component.Windows81SDK
        Out-ColorMessage -Message "visual studio 2019 is being installed, please don't close visual studio's ui, now continue to install other tools!!"
        Remove-Item -Path "$home\vs_Community_16.11.21.exe" -Force
    } 
}

# step9: install jdk11
if (-not $(Test-Command -command java  -printVersion $True)) {
    Out-InstallMessage -command jdk11
    # install jdk11 with choco will print error
    # choco install jdk11 -y -params "source=false"
    # use winget to install jdk11
    winget install Microsoft.OpenJDK.11 --accept-source-agreements --accept-package-agreements --rainbow
}
# step10: install android studio 2021.3.1
if ($install_as) {
    if ($(-not $Env:BITS_CLOUD_BUILD_ENV) -and (-not $(Test-Path "C:\Program Files\Android\Android Studio"))) {
        Out-ColorMessage -Message "start install android studio 2021.3.1.17"
        winget install --id Google.AndroidStudio --version 2021.3.1.17 --accept-source-agreements --accept-package-agreements --rainbow
    }
}

# step11: install android sdk manager tools and set android system env
#C:\Program Files\Android
if (-not $(Test-Path "C:\Android\cmdline-tools\tools")) {
    Out-ColorMessage -Message "start install android sdkmanager tools, please wait for a long time!"
    New-Item -Path "C:\Android" -Name cmdline-tools -ItemType Directory -Force
    $winSDKManager = "http://tosv.byted.org/obj/rtcsdk/build_env_install/windows/commandlinetools-win_latest.zip"
    Invoke-FileDownload -Uri $winSDKManager -OutFile $home\commandlinetools-win_latest.zip
    Expand-Archive -Path $home\commandlinetools-win_latest.zip -DestinationPath $home\cmdline-tools
    Rename-Item -Path $home\cmdline-tools\cmdline-tools -NewName $home\cmdline-tools\tools -Force
    Move-Item -Path "$home\cmdline-tools\tools" -Destination "C:\Android\cmdline-tools" -Force
    Remove-Item -Path $home\commandlinetools-win_latest.zip -Force
    Remove-Item -Path $home\cmdline-tools -Recurse -Force
}
# set system env for android
[Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', 'C:\Android' , 'Machine')
[Environment]::SetEnvironmentVariable('ANDROID_HOME', 'C:\Android' , 'Machine')


# step12: use android sdk manager to install default's android sdk and ndk
$androidSdkManager = "C:\Android\cmdline-tools\tools\bin\sdkmanager.bat"
$null = ."$androidSdkManager" --licenses
if (-not ($?)) {
    New-Item -Path $home -Name y_file.txt -ItemType File -Force
    Add-Content -Path $home\y_file.txt -Value "y`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`n" -Encoding utf8
    $null = Get-Content -Path $home\y_file.txt | ."$androidSdkManager" --licenses
    Remove-Item -Path $home\y_file.txt -Force
}

# install android sdk
Invoke-InstallAndroidTools -SdkmanagerPath $androidSdkManager -ToolsType platforms -ToolsVersion android-27
Invoke-InstallAndroidTools -SdkmanagerPath $androidSdkManager -ToolsType platforms -ToolsVersion android-28
Invoke-InstallAndroidTools -SdkmanagerPath $androidSdkManager -ToolsType platforms -ToolsVersion android-31
Invoke-InstallAndroidTools -SdkmanagerPath $androidSdkManager -ToolsType platform-tools
# install android ndk
Invoke-InstallAndroidTools -SdkmanagerPath $androidSdkManager -ToolsType ndk -ToolsVersion 21.0.6113669
Invoke-InstallAndroidTools -SdkmanagerPath $androidSdkManager -ToolsType ndk -ToolsVersion 21.1.6352462
Invoke-InstallAndroidTools -SdkmanagerPath $androidSdkManager -ToolsType ndk -ToolsVersion 21.3.6528147
Invoke-InstallAndroidTools -SdkmanagerPath $androidSdkManager -ToolsType ndk -ToolsVersion 22.1.7171670
Invoke-InstallAndroidTools -SdkmanagerPath $androidSdkManager -ToolsType ndk -ToolsVersion 23.1.7779620
# install android cmake
Invoke-InstallAndroidTools -SdkmanagerPath $androidSdkManager -ToolsType cmake -ToolsVersion 3.10.2.4988404
Invoke-InstallAndroidTools -SdkmanagerPath $androidSdkManager -ToolsType cmake -ToolsVersion 3.22.1
# set default ndk home env
if (-not [Environment]::GetEnvironmentVariable('ANDROID_NDK_HOME', 'Machine')) {
    $ANDROID_HOME = [Environment]::GetEnvironmentVariable('ANDROID_HOME', 'Machine')
    [Environment]::SetEnvironmentVariable('ANDROID_NDK_HOME', "$ANDROID_HOME\ndk\22.1.7171670" , 'Machine')
}

# step13: install qt5.14.2
if ($install_qt) {
    if ((-not [Environment]::GetEnvironmentVariable('Qt32Path', 'Machine')) -or (-not [Environment]::GetEnvironmentVariable('Qt64Path', 'Machine')) -or (-not $(Test-Path "C:\Qt\5.14.2"))) {
        $qt5InstallerUri = "http://tosv.byted.org/obj/rtcsdk/build_env_install/windows/qt-unified-windows-x86-4.3.0-1-online.exe"
        $QT_EMAIL = "sunhang.io@bytedance.com"
        $QT_PASSWORD = "bytertc@2020"
        Out-ColorMessage -Message "start install qt5.14.2, please wait for a long time!!"
        Invoke-FileDownload -Uri $qt5InstallerUri -OutFile $home\qt-unified-windows-x86-4.3.0-1-online.exe
        .$home\qt-unified-windows-x86-4.3.0-1-online.exe install `
            qt.qt5.5142.qtcharts `
            qt.qt5.5142.win64_msvc2017_64 `
            qt.qt5.5142.win32_msvc2017 `
            qt.qt5.5142.qtquick3d `
            qt.qt5.5142.qtdatavis3d `
            qt.qt5.5142.qtlottie `
            qt.qt5.5142.qtpurchasing `
            qt.qt5.5142.qtvirtualkeyboard `
            qt.qt5.5142.qtwebengine `
            qt.qt5.5142.qtnetworkauth `
            qt.qt5.5142.qtwebglplugin `
            qt.qt5.5142.qtscript `
            qt.qt5.5142.debug_info `
            qt.qt5.5142.qtquicktimeline `
            --default-answer --accept-licenses --confirm-command `
            --auto-answer telemetry-question=Yes, AssociateCommonFiletypes=Yes --accept-obligations `
            --email $QT_EMAIL --pw $QT_PASSWORD
        # set system env for qt5
        [Environment]::SetEnvironmentVariable('Qt32Path', 'C:\Qt\5.14.2\msvc2017\lib\cmake' , 'Machine')
        [Environment]::SetEnvironmentVariable('Qt64Path', 'C:\Qt\5.14.2\msvc2017_64\lib\cmake' , 'Machine')
    }
}

# step14: check checklist
foreach ($command in $checklist.Keys) {
    <# $command is the$checklist.Keys item #>
    $null = Test-Command -command $command -printVersion $True
    # Test-Command -command $command -printVersion $True
}
