# 🔧 Add your personal tools folder to PATH if not already present
$toolsPath = "$HOME\OneDrive\Documents\WindowsPowerShell\tools"
if (-not ($env:PATH -split ';' | Where-Object { $_ -eq $toolsPath })) {
    $env:PATH += ";$toolsPath"
}
Set-Alias grep rg
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -Colors @{
    "Command"   = [ConsoleColor]::Cyan
    "Parameter" = [ConsoleColor]::Yellow
    "String"    = [ConsoleColor]::Green
    "Number"    = [ConsoleColor]::Magenta
    "Operator"  = [ConsoleColor]::DarkCyan
    "Variable"  = [ConsoleColor]::Gray
    "Type"      = [ConsoleColor]::Blue
    "Comment"   = [ConsoleColor]::DarkGreen
    "Keyword"   = [ConsoleColor]::Blue
}


# ⌨️ Ctrl+F — Fuzzy File Finder
Set-PSReadLineKeyHandler -Key Ctrl+f -ScriptBlock {
    $file = Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty FullName |
    fzf
    if ($file) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($file)
    }
}

# 🔁 Ctrl+R — Full Session History Search (newest last, pre-selected)
Set-PSReadLineKeyHandler -Key Ctrl+r -ScriptBlock {
    $historyFile = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"

    if (Test-Path $historyFile) {
        $lines = Get-Content $historyFile -ErrorAction SilentlyContinue

        # Deduplicate while keeping last occurrence
        $seen = @{}
        $ordered = [System.Collections.Generic.List[string]]::new()
        foreach ($line in $lines) {
            if ($seen.ContainsKey($line)) {
                $ordered.Remove($line)
            }
            $seen[$line] = $true
            $ordered.Add($line)
        }

        $selection = $ordered | fzf --tac
        if ($selection) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selection)
        }
    }
}
