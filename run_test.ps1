# OnlyVolunteer - Run app for testing
# Usage: .\run_test.ps1
#        .\run_test.ps1 -GeminiKey "your_gemini_api_key"

param(
    [string]$GeminiKey = ""
)

$flutterBin = "C:\flutter\bin"
if (-not (Test-Path "$flutterBin\flutter.bat")) {
    Write-Host "Flutter not found. Run .\run_setup.ps1 first or add Flutter to PATH." -ForegroundColor Red
    exit 1
}
$env:Path = "$flutterBin;$env:Path"

Set-Location $PSScriptRoot

& flutter pub get

if ($GeminiKey) {
    Write-Host "Starting with Gemini key..." -ForegroundColor Cyan
    & flutter run -d chrome --dart-define=GEMINI_API_KEY=$GeminiKey
} else {
    Write-Host "Starting without Gemini key (AI features will be limited)." -ForegroundColor Yellow
    Write-Host "To pass key: .\run_test.ps1 -GeminiKey `"your_key`"" -ForegroundColor Gray
    & flutter run -d chrome
}
