# OnlyVolunteer - Setup script (Steps 1-4)
# Run in PowerShell: .\run_setup.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot

# Step 1: Ensure Flutter is on PATH
$flutterBin = "C:\flutter\bin"
if (Test-Path "$flutterBin\flutter.bat") {
    $env:Path = "$flutterBin;$env:Path"
    Write-Host "Flutter found at C:\flutter" -ForegroundColor Green
} else {
    Write-Host "Flutter not found at C:\flutter. Install it first (see SETUP.md Step 1)." -ForegroundColor Red
    exit 1
}

Set-Location $ProjectRoot

# First run may download Dart SDK - can take a few minutes
Write-Host "`nChecking Flutter (first time may download Dart SDK)..." -ForegroundColor Cyan
& flutter --version

Write-Host "`n--- Step 2: Dependencies ---" -ForegroundColor Cyan
& flutter pub get

Write-Host "`n--- FlutterFire CLI ---" -ForegroundColor Cyan
& dart pub global activate flutterfire_cli
$env:Path = "$env:USERPROFILE\AppData\Local\Pub\Cache\bin;$env:Path"

Write-Host "`n--- Firebase configuration (Step 2) ---" -ForegroundColor Cyan
Write-Host "You will be asked to sign in and select your Firebase project." -ForegroundColor Yellow
& flutterfire configure

Write-Host "`n--- Steps 3 & 4 ---" -ForegroundColor Cyan
Write-Host "3. Get a Gemini key from https://aistudio.google.com/apikey" -ForegroundColor White
Write-Host "4. (Optional) Replace YOUR_MAPS_KEY in web\index.html with your Google Maps key" -ForegroundColor White
Write-Host "`nTo run the app:" -ForegroundColor Green
Write-Host '  .\run_test.ps1 -GeminiKey "YOUR_GEMINI_KEY"' -ForegroundColor White
Write-Host "  or: flutter run -d chrome --dart-define=GEMINI_API_KEY=YOUR_KEY" -ForegroundColor White
Write-Host "`nDone. Open SETUP.md for full details." -ForegroundColor Green
