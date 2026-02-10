<# 
 Example local runner for OnlyVolunteer.
 
 Copy this file to `run_local.ps1` (which is ignored by git),
 then replace the placeholder with your real Gemini API key.
 
 Usage:
   .\run_local.ps1
#>

$geminiKey = "YOUR_GEMINI_API_KEY_HERE"

.\run_test.ps1 -GeminiKey $geminiKey

