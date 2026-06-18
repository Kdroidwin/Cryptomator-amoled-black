param(
	[string] $RepoUrl = "https://github.com/cryptomator/cryptomator.git",
	[string] $Branch = "develop",
	[string] $WorkRoot = "",
	[string] $OutputDir = "",
	[switch] $KeepWorktree,
	[switch] $CleanBuild
)

$ErrorActionPreference = "Stop"

function Write-Step($message) {
	Write-Host "[BUILD] $message"
}

function Invoke-Checked {
	param(
		[string] $FilePath,
		[string[]] $Arguments,
		[string] $WorkingDirectory = (Get-Location).Path
	)
	Write-Step "$FilePath $($Arguments -join ' ')"
	Push-Location $WorkingDirectory
	try {
		& $FilePath @Arguments
		if ($LASTEXITCODE -ne 0) {
			throw "Command failed with exit code ${LASTEXITCODE}: $FilePath"
		}
	} finally {
		Pop-Location
	}
}

function Find-WixExe {
	$paths = @(
		(Get-Command "wix.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
		"C:\Program Files\WiX Toolset v7.0\bin\wix.exe",
		"C:\Program Files\WiX Toolset v6.0\bin\wix.exe",
		"C:\Program Files\WiX Toolset v5.0\bin\wix.exe",
		"C:\Program Files\WiX Toolset v4.0\bin\wix.exe"
	)
	return @($paths | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique)
}

function Ensure-WixExe {
	$wix = @(Find-WixExe)
	if ($wix.Count -gt 0) {
		return $wix[0]
	}

	$winget = Get-Command "winget.exe" -ErrorAction SilentlyContinue
	if ($null -eq $winget) {
		throw "WiX was not found and winget.exe is unavailable. Install WiX Toolset CLI and rerun this script."
	}

	Write-Step "WiX was not found. Installing WiX Toolset CLI via winget..."
	Invoke-Checked $winget.Source @("install", "--id", "WiXToolset.WiXCLI", "--silent", "--accept-package-agreements", "--accept-source-agreements") $workspaceRoot

	$wix = @(Find-WixExe)
	if ($wix.Count -eq 0) {
		throw "WiX installation finished, but wix.exe still was not found. Open a new shell or add WiX to PATH, then rerun."
	}
	return $wix[0]
}

$scriptDir = $PSScriptRoot
$workspaceRoot = Split-Path -Parent $scriptDir
if (-not $WorkRoot) {
	$WorkRoot = Join-Path $workspaceRoot "work\cryptomator-amoled-git-build"
}
if (-not $OutputDir) {
	$OutputDir = Join-Path $workspaceRoot "outputs"
}
$patcher = Join-Path $scriptDir "CryptomatorAmoledBlackPatcher.ps1"
if (-not (Test-Path -LiteralPath $patcher)) {
	throw "Missing patcher next to this script: $patcher"
}

$jdkCandidates = @((
	$env:JAVA_HOME,
	"C:\Program Files\Eclipse Adoptium\jdk-26.0.1.8-hotspot",
	"C:\Program Files\Java\jdk-26"
) | Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $_ "bin\jpackage.exe")) })
if ($jdkCandidates.Count -eq 0) {
	throw "JDK 26 with jpackage.exe was not found. Set JAVA_HOME to a JDK 26 install."
}
$env:JAVA_HOME = $jdkCandidates[0]
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
Write-Step "JAVA_HOME=$env:JAVA_HOME"

New-Item -ItemType Directory -Force -Path $WorkRoot, $OutputDir | Out-Null
$repoDir = Join-Path $WorkRoot "cryptomator"

if (Test-Path -LiteralPath $repoDir) {
	if ($KeepWorktree) {
		Write-Step "Using existing worktree: $repoDir"
	} else {
		$resolvedWork = (Resolve-Path -LiteralPath $WorkRoot).Path
		$resolvedRepo = (Resolve-Path -LiteralPath $repoDir).Path
		if (-not $resolvedRepo.StartsWith($resolvedWork)) {
			throw "Refusing to remove unexpected path: $resolvedRepo"
		}
		Remove-Item -LiteralPath $repoDir -Recurse -Force
	}
}

if (-not (Test-Path -LiteralPath $repoDir)) {
	Invoke-Checked "git" @("clone", "--depth", "1", "--branch", $Branch, $RepoUrl, $repoDir) $WorkRoot
}

Invoke-Checked "git" @("rev-parse", "--short", "HEAD") $repoDir

Write-Step "Applying AMOLED patch"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $patcher -Target $repoDir -NoPause
if ($LASTEXITCODE -ne 0) {
	throw "AMOLED patch failed."
}

Write-Step "Building jars with Maven Wrapper"
$env:MAVEN_OPTS = "-Xmx768m -XX:+UseSerialGC -XX:CICompilerCount=2 -Dfile.encoding=UTF-8"
$mavenGoals = if ($CleanBuild) { @("clean", "package") } else { @("package") }
Invoke-Checked (Join-Path $repoDir "mvnw.cmd") (@("-B") + $mavenGoals + @("-DskipTests", "-Pwin")) $repoDir

$targetDir = Join-Path $repoDir "target"
$modsDir = Join-Path $targetDir "mods"
New-Item -ItemType Directory -Force -Path $modsDir | Out-Null
$mainJar = Get-ChildItem -LiteralPath $targetDir -Filter "cryptomator-*.jar" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($null -eq $mainJar) {
	throw "Main Cryptomator jar not found in $targetDir"
}
Copy-Item -LiteralPath $mainJar.FullName -Destination $modsDir -Force

$distWin = Join-Path $repoDir "dist\win"
$runtimeDir = Join-Path $distWin "runtime"
$appDir = Join-Path $distWin "Cryptomator"
Remove-Item -LiteralPath $runtimeDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $appDir -Recurse -Force -ErrorAction SilentlyContinue

$jmodsZip = Join-Path $distWin "resources\jfxJmods.zip"
$jmodsDir = Join-Path $distWin "resources\javafx-jmods"
if (-not (Test-Path -LiteralPath $jmodsZip)) {
	$jfxUrl = "https://download2.gluonhq.com/openjfx/25.0.2/openjfx-25.0.2_windows-x64_bin-jmods.zip"
	Write-Step "Downloading JavaFX jmods: $jfxUrl"
	Invoke-WebRequest $jfxUrl -OutFile $jmodsZip
}
$expectedHash = "33d878dfac85590c4d77c518ed413e512d34a8479d90132b230a7ddd173576b3"
$actualHash = (Get-FileHash -Path $jmodsZip -Algorithm SHA256).Hash.ToLower()
if ($actualHash -ne $expectedHash) {
	throw "JavaFX jmods checksum mismatch. Expected $expectedHash, got $actualHash"
}
Expand-Archive -Path $jmodsZip -Force -DestinationPath (Join-Path $distWin "resources")
Remove-Item -LiteralPath $jmodsDir -Recurse -Force -ErrorAction SilentlyContinue
Move-Item -Path (Join-Path $distWin "resources\javafx-jmods-*") -Destination $jmodsDir -Force

$jmodPaths = "$env:JAVA_HOME\jmods;$jmodsDir"
Write-Step "Creating runtime image"
Invoke-Checked (Join-Path $env:JAVA_HOME "bin\jlink.exe") @(
	"--output", "runtime",
	"--module-path", $jmodPaths,
	"--add-modules", "java.base,java.desktop,java.instrument,java.logging,java.naming,java.net.http,java.scripting,java.sql,java.xml,jdk.unsupported,jdk.accessibility,jdk.management.jfr,jdk.crypto.cryptoki,jdk.crypto.ec,jdk.crypto.mscapi,java.compiler,javafx.base,javafx.graphics,javafx.controls,javafx.fxml",
	"--strip-native-commands",
	"--no-header-files",
	"--no-man-pages",
	"--strip-debug",
	"--compress", "zip-0"
) $distWin

$version = & (Join-Path $repoDir "mvnw.cmd") "-f" (Join-Path $repoDir "pom.xml") "help:evaluate" "-Dexpression=project.version" "-q" "-DforceStdout"
$semVerNo = "$version" -replace '(\d+\.\d+\.\d+).*','$1'
$revisionNo = (& git -C $repoDir rev-list --count HEAD).Trim()
$copyright = "(C) 2016 - $((Get-Date).Year) Skymatic GmbH"

$javaOptions = @(
	"--java-options", "--enable-native-access=javafx.graphics,org.cryptomator.jfuse.win,org.cryptomator.integrations.win",
	"--java-options", "-Xss5m",
	"--java-options", "-Xmx256m",
	"--java-options", "-Dcryptomator.appVersion=`"$semVerNo`"",
	"--java-options", "-Dfile.encoding=`"utf-8`"",
	"--java-options", "-Djava.net.useSystemProxies=true",
	"--java-options", "-Dcryptomator.logDir=`"@{localappdata}/Cryptomator`"",
	"--java-options", "-Dcryptomator.adminConfigPath=`"C:/ProgramData/Cryptomator/config.properties`"",
	"--java-options", "-Dcryptomator.settingsPath=`"@{appdata}/Cryptomator/settings.json;@{userhome}/AppData/Roaming/Cryptomator/settings.json`"",
	"--java-options", "-Dcryptomator.ipcSocketPath=`"@{localappdata}/Cryptomator/ipc.socket`"",
	"--java-options", "-Dcryptomator.p12Path=`"@{appdata}/Cryptomator/key.p12;@{userhome}/AppData/Roaming/Cryptomator/key.p12`"",
	"--java-options", "-Dcryptomator.mountPointsDir=`"@{userhome}/Cryptomator`"",
	"--java-options", "-Dcryptomator.loopbackAlias=`"cryptomator-vault`"",
	"--java-options", "-Dcryptomator.integrationsWin.autoStartShellLinkName=`"Cryptomator`"",
	"--java-options", "-Dcryptomator.integrationsWin.keychainPaths=`"@{appdata}/Cryptomator/keychain.json;@{userhome}/AppData/Roaming/Cryptomator/keychain.json`"",
	"--java-options", "-Dcryptomator.integrationsWin.windowsHelloKeychainPaths=`"@{appdata}/Cryptomator/windowsHelloKeychain.json`"",
	"--java-options", "-Dcryptomator.showTrayIcon=true",
	"--java-options", "-Dcryptomator.buildNumber=`"appimage-$revisionNo`"",
	"--java-options", "-Dcryptomator.disableUpdateCheck=true",
	"--java-options", "-Dcryptomator.hub.enableTrustOnFirstUse=true"
)

Write-Step "Creating Windows app-image"
$jpackageArgs = @(
	"--type", "app-image",
	"--runtime-image", "runtime",
	"--input", "..\..\target\libs",
	"--module-path", "..\..\target\mods",
	"--module", "org.cryptomator.desktop/org.cryptomator.launcher.Cryptomator",
	"--dest", ".",
	"--name", "Cryptomator",
	"--vendor", "Skymatic GmbH",
	"--copyright", $copyright,
	"--app-version", "$semVerNo.$revisionNo",
	"--resource-dir", "resources",
	"--icon", "resources\Cryptomator.ico"
) + $javaOptions
Invoke-Checked (Join-Path $env:JAVA_HOME "bin\jpackage.exe") $jpackageArgs $distWin

Copy-Item -Path (Join-Path $distWin "contrib\*") -Destination $appDir -Force

$zipOut = Join-Path $OutputDir "Cryptomator-AMOLED-Black-Windows-AppImage.zip"
Remove-Item -LiteralPath $zipOut -Force -ErrorAction SilentlyContinue
Compress-Archive -Path $appDir -DestinationPath $zipOut -Force

$realWix = Ensure-WixExe
if ($realWix) {
	$wrapperDir = Join-Path $WorkRoot "wix-wrapper"
	New-Item -ItemType Directory -Force -Path $wrapperDir | Out-Null
	$wrapperCs = Join-Path $wrapperDir "WixAcceptEulaWrapper.cs"
	$wrapperExe = Join-Path $wrapperDir "wix.exe"
	@"
using System;
using System.Collections.Generic;
using System.Diagnostics;
internal static class WixAcceptEulaWrapper {
	private const string RealWix = @"$realWix";
	private static int Main(string[] args) {
		var forwarded = new List<string>(args);
		if (forwarded.Count > 0 && string.Equals(forwarded[0], "build", StringComparison.OrdinalIgnoreCase)) {
			forwarded.Insert(1, "wix7");
			forwarded.Insert(1, "--acceptEula");
		}
		var psi = new ProcessStartInfo { FileName = RealWix, UseShellExecute = false, Arguments = string.Join(" ", forwarded.ConvertAll(Quote)) };
		using (var process = Process.Start(psi)) { process.WaitForExit(); return process.ExitCode; }
	}
	private static string Quote(string value) {
		if (value.IndexOfAny(new[] { ' ', '\t', '"' }) < 0) { return value; }
		return "\"" + value.Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"";
	}
}
"@ | Set-Content -LiteralPath $wrapperCs -Encoding ASCII
	$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
	if (-not (Test-Path -LiteralPath $csc)) {
		throw "csc.exe not found, cannot build WiX wrapper for jpackage."
	}
	Invoke-Checked $csc @("/nologo", "/target:exe", "/platform:anycpu", "/out:$wrapperExe", $wrapperCs) $wrapperDir
	$env:Path = "$wrapperDir;$(Split-Path -Parent $realWix);$env:Path"

	Write-Step "Creating MSI installer"
	Invoke-Checked (Join-Path $env:JAVA_HOME "bin\jpackage.exe") @(
		"--type", "msi",
		"--app-image", "Cryptomator",
		"--dest", ".",
		"--name", "Cryptomator-AMOLED",
		"--app-version", "$semVerNo.$revisionNo",
		"--vendor", "Skymatic GmbH",
		"--win-dir-chooser",
		"--win-menu",
		"--win-shortcut"
	) $distWin
	$msi = Get-ChildItem -LiteralPath $distWin -Filter "Cryptomator-AMOLED-*.msi" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
	if ($msi) {
		Copy-Item -LiteralPath $msi.FullName -Destination (Join-Path $OutputDir $msi.Name) -Force
		Write-Step "Packaged MSI: $(Join-Path $OutputDir $msi.Name)"
	}
} else {
	throw "WiX was not found, so MSI creation cannot continue."
}

Write-Step "Built app-image: $appDir"
Write-Step "Packaged zip: $zipOut"
