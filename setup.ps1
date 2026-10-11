# Windotool Setup Script
# This script helps you set up windotool for easy command-line access

Write-Host "`nWindotool Setup`n" -ForegroundColor Cyan

# Check if the executable exists
$exePath = Join-Path $PSScriptRoot "zig-out\bin\windotool.exe"
if (-not (Test-Path $exePath)) {
    Write-Host "[ERROR] windotool.exe not found!" -ForegroundColor Red
    Write-Host "        Please run 'zig build' first.`n" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Found windotool.exe at: $exePath`n" -ForegroundColor Green

# Test the executable
Write-Host "Testing windotool..." -ForegroundColor Cyan
& $exePath --version
Write-Host ""

# Show options
Write-Host "Choose how you want to use windotool:`n" -ForegroundColor Yellow

Write-Host "1. Add to PATH for current session only (temporary)" -ForegroundColor White
Write-Host "2. Show instructions to add to PATH permanently" -ForegroundColor White
Write-Host "3. Copy to Windows directory (requires admin)" -ForegroundColor White
Write-Host "4. Just show me how to use it" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter your choice (1-4)"

switch ($choice) {
    "1" {
        $binPath = Join-Path $PSScriptRoot "zig-out\bin"
        $env:PATH += ";$binPath"
        Write-Host "`n[OK] Added to PATH for this session!" -ForegroundColor Green
        Write-Host "     You can now use: windotool --help`n" -ForegroundColor Cyan
        Write-Host "[NOTE] This only works in the current PowerShell window." -ForegroundColor Yellow
        Write-Host "       To make it permanent, choose option 2 next time.`n" -ForegroundColor Yellow
    }
    "2" {
        $binPath = Join-Path $PSScriptRoot "zig-out\bin"
        Write-Host "`nTo add windotool to PATH permanently:`n" -ForegroundColor Cyan
        Write-Host "1. Press Win + X and select 'System'" -ForegroundColor White
        Write-Host "2. Click 'Advanced system settings'" -ForegroundColor White
        Write-Host "3. Click 'Environment Variables'" -ForegroundColor White
        Write-Host "4. Under 'User variables', select 'Path' and click 'Edit'" -ForegroundColor White
        Write-Host "5. Click 'New' and add this path:" -ForegroundColor White
        Write-Host "   $binPath" -ForegroundColor Yellow
        Write-Host "6. Click OK on all dialogs" -ForegroundColor White
        Write-Host "7. Restart PowerShell or Command Prompt`n" -ForegroundColor White
        Write-Host "After that, you can use 'windotool' from anywhere!`n" -ForegroundColor Green
    }
    "3" {
        Write-Host "`n[WARNING] This requires administrator privileges.`n" -ForegroundColor Yellow
        $confirm = Read-Host "Copy windotool.exe to C:\Windows? (y/N)"
        if ($confirm -eq "y" -or $confirm -eq "Y") {
            try {
                Copy-Item $exePath "C:\Windows\windotool.exe" -Force
                Write-Host "`n[OK] Copied to C:\Windows!" -ForegroundColor Green
                Write-Host "     You can now use: windotool --help`n" -ForegroundColor Cyan
            }
            catch {
                Write-Host "`n[ERROR] Failed to copy. Please run PowerShell as Administrator.`n" -ForegroundColor Red
            }
        }
        else {
            Write-Host "`nCancelled.`n" -ForegroundColor Yellow
        }
    }
    "4" {
        Write-Host "`nHow to use windotool:`n" -ForegroundColor Cyan
        Write-Host "From the project directory:" -ForegroundColor White
        Write-Host "   .\zig-out\bin\windotool.exe --help" -ForegroundColor Yellow
        Write-Host "   .\zig-out\bin\windotool.exe mouse pos" -ForegroundColor Yellow
        Write-Host "   .\zig-out\bin\windotool.exe window list`n" -ForegroundColor Yellow
        Write-Host "From the zig-out\bin directory:" -ForegroundColor White
        Write-Host "   cd zig-out\bin" -ForegroundColor Yellow
        Write-Host "   .\windotool.exe --help`n" -ForegroundColor Yellow
    }
    default {
        Write-Host "`n[ERROR] Invalid choice. Please run the script again.`n" -ForegroundColor Red
    }
}

Write-Host "For more information, see README.md`n" -ForegroundColor Cyan
