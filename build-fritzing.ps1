$qtVersion = '6.5.3'

$boostVersion = '1.81.0'
$libgit2Version = '1.7.1'
$svgppVersion = '1.3.0'
$ngspiceVersion = '42'
$quazipVersion = '1.4'
$zlibVersion = '1.3.1'

$ProgressPreference = 'SilentlyContinue'

& "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Launch-VsDevShell.ps1" -Arch amd64

Write-Output "Downloading Boost..."
$boostVersionUnderscore = $boostVersion -replace '\.', '_'
Invoke-WebRequest -Uri https://archives.boost.io/release/$boostVersion/source/boost_$boostVersionUnderscore.7z -OutFile boost.7z
& "C:\Program Files\7-Zip\7z.exe" x boost.7z
Remove-Item -Path boost.7z

Write-Output "Downloading libgit2..."
Invoke-WebRequest -Uri https://github.com/libgit2/libgit2/archive/refs/tags/v$libgit2Version.zip -OutFile libgit2.zip
& "C:\Program Files\7-Zip\7z.exe" x libgit2.zip
Remove-Item -Path libgit2.zip
Move-Item -Path libgit2-$libgit2Version -Destination libgit2

Write-Output "Downloading PolyClipper..."
New-Item -ItemType Directory -Path clipper_ver6.4.2
Push-Location -Path clipper_ver6.4.2
try {
    Invoke-WebRequest -Uri https://onboardcloud.dl.sourceforge.net/project/polyclipping/clipper_ver6.4.2.zip?viasf=1 -OutFile clipper_ver6.4.2.zip
    & "C:\Program Files\7-Zip\7z.exe" x clipper_ver6.4.2.zip
    Remove-Item -Path clipper_ver6.4.2.zip
} finally {
    Pop-Location
}

Write-Output "Downloading svgpp..."
Invoke-WebRequest -Uri https://github.com/svgpp/svgpp/archive/refs/tags/v$svgppVersion.zip -OutFile svgpp.zip
& "C:\Program Files\7-Zip\7z.exe" x svgpp.zip
Remove-Item -Path svgpp.zip

Write-Output "Downloading ngspice..."
Invoke-WebRequest -Uri https://jaist.dl.sourceforge.net/project/ngspice/ng-spice-rework/$ngspiceVersion/ngspice-$ngspiceVersion.tar.gz?viasf=1 -OutFile ngspice.tar.gz
& "C:\Program Files\7-Zip\7z.exe" x ngspice.tar.gz
& "C:\Program Files\7-Zip\7z.exe" x ngspice.tar
Remove-Item -Path ngspice.tar
Remove-Item -Path ngspice.tar.gz

Write-Output "Downloading winflexbison..."
New-Item -ItemType Directory -Path flex-bison
Push-Location -Path flex-bison
try {
    Invoke-WebRequest -Uri https://github.com/lexxmark/winflexbison/releases/download/v2.5.25/win_flex_bison-2.5.25.zip -OutFile win_flex_bison.zip
    & "C:\Program Files\7-Zip\7z.exe" x win_flex_bison.zip
    Remove-Item -Path win_flex_bison.zip
} finally {
    Pop-Location
}

Write-Output "Downloading Quazip..."
Invoke-WebRequest -Uri https://github.com/stachenov/quazip/archive/refs/tags/v$quazipVersion.zip -OutFile quazip.zip
& "C:\Program Files\7-Zip\7z.exe" x quazip.zip
Remove-Item -Path quazip.zip

Write-Output "Downloading zlib..."
Invoke-WebRequest -Uri https://www.zlib.net/zlib-$zlibVersion.tar.gz -OutFile zlib.tar.gz
& "C:\Program Files\7-Zip\7z.exe" x zlib.tar.gz
& "C:\Program Files\7-Zip\7z.exe" x zlib-$zlibVersion.tar
Remove-Item -Path zlib-$zlibVersion.tar
Remove-Item -Path zlib.tar.gz

Write-Output "Cloning Fritzing source code..."
& "git.exe" clone https://github.com/fritzing/fritzing-app.git
& "git.exe" clone https://github.com/fritzing/fritzing-parts.git

Write-Output "Building libgit2..."
Push-Location -Path libgit2
try {
    & "cmake.exe" -B build64 -DBUILD_TESTS=OFF
    & "cmake.exe" --build build64 --config Release
} finally {
    Pop-Location
}

Write-Output "Building PolyClipper..."
Push-Location -Path clipper_ver6.4.2/cpp
try {
    $polyClipperInstallPrefix = ((Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Get-Location))) -ChildPath clipper1/6.4.2) -replace '\\', '/')

    Write-Output "Building PolyClipper (shared)..."
    & "cmake.exe" -B build "-DCMAKE_INSTALL_PREFIX=$polyClipperInstallPrefix"
    & "cmake.exe" --build build --config Release
    & "cmake.exe" --install build

    Write-Output "Building PolyClipper (static)..."
    & "cmake.exe" -B build "-DCMAKE_INSTALL_PREFIX=$polyClipperInstallPrefix" -DBUILD_SHARED_LIBS=OFF
    & "cmake.exe" --build build --config Release
    & "cmake.exe" --install build
} finally {
    Pop-Location
}

Write-Output "Building ngspice..."
Push-Location -Path ngspice-$ngspiceVersion
try {
    & "msbuild.exe" visualc\sharedspice.sln /p:Configuration=Release
    Copy-Item -Recurse -Path src/include/ -Destination include/
} finally {
    Pop-Location
}

Write-Output "Building zlib..."
Push-Location -Path zlib-$zlibVersion
try {
    $zlibInstallPrefix = ((Join-Path -Path (Split-Path -Parent (Get-Location)) -ChildPath zlib) -replace '\\', '/')
    & "cmake.exe" -B build "-DCMAKE_INSTALL_PREFIX=$zlibInstallPrefix"
    & "cmake.exe" --build build --config Release
    & "cmake.exe" --install build
} finally {
    Pop-Location
}

Write-Output "Building Quazip..."
Push-Location -Path quazip-$quazipVersion
try {
    $quazipInstallPrefix = ((Join-Path -Path (Split-Path -Parent (Get-Location)) -ChildPath quazip-$qtVersion-$quazipVersion) -replace '\\', '/')
    $zlibLibrary = ((Join-Path -Path (Split-Path -Parent (Get-Location)) -ChildPath zlib/lib/zlib.lib) -replace '\\', '/')
    $zlibIncludeDir = ((Join-Path -Path (Split-Path -Parent (Get-Location)) -ChildPath zlib/include) -replace '\\', '/')

    & "cmake.exe" -B build -DQUAZIP_QT_MAJOR_VERSION=6 "-DCMAKE_INSTALL_PREFIX=$quazipInstallPrefix" -DCMAKE_PREFIX_PATH=C:/Qt/$qtVersion/msvc2019_64 "-DZLIB_LIBRARY=$zlibLibrary" "-DZLIB_INCLUDE_DIR=$zlibIncludeDir"
    & "cmake.exe" --build build --config Release
    & "cmake.exe" --install build
} finally {
    Pop-Location
}

Write-Output "Building Fritzing..."
$qtVersionUnderscore = $qtVersion -replace '\.', '_'
New-Item -ItemType Directory -Path fritzing-app/build/Qt_${qtVersionUnderscore}_msvc2019_64-Release
Push-Location -Path fritzing-app/build/Qt_${qtVersionUnderscore}_msvc2019_64-Release
try {
    & "C:\Qt\$qtVersion\msvc2019_64\bin\qmake.exe" ../../phoenix.pro -spec win32-msvc "CONFIG += qtquickcompiler"
    & "C:\Qt\Tools\QtCreator\bin\jom\jom.exe" qmake_all
    & "C:\Qt\Tools\QtCreator\bin\jom\jom.exe" -f Makefile.release compiler_uic_make_all
    & "C:\Qt\Tools\QtCreator\bin\jom\jom.exe"

    Push-Location -Path ../release64
    try {
        & "C:\Qt\6.5.3\msvc2019_64\bin\windeployqt.exe" Fritzing.exe
        Copy-Item -Path C:\Qt\$qtVersion\msvc2019_64\bin\Qt6Core5Compat.dll -Destination .
        Copy-Item -Path ..\..\..\quazip-$qtVersion-$quazipVersion\bin\quazip1-qt6.dll -Destination .
        Copy-Item -Path ..\..\..\libgit2\build64\Release\git2.dll -Destination .
        Copy-Item -Path ..\..\..\zlib\bin\zlib.dll -Destination .
    } finally {
        Pop-Location
    }
} finally {
    Pop-Location
}
