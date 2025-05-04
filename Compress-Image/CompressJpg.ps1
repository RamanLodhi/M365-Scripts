Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser

Add-Type -AssemblyName System.Drawing


function Compress-Image {
    param (
        [string]$InputPath,
        [string]$OutputFolder,
        [int]$Quality
    )

    try {
        $fileName = [System.IO.Path]::GetFileName($InputPath)
        $outputPath = Join-Path $OutputFolder $fileName

        # Don't overwrite original file
        if ($InputPath -eq $outputPath) {
            $outputPath = Join-Path $OutputFolder ("compressed_" + $fileName)
        }

        $extension = [System.IO.Path]::GetExtension($InputPath).ToLower()

        if ($extension -eq ".jpg" -or $extension -eq ".jpeg") {
            $image = [System.Drawing.Image]::FromFile($InputPath)

            $jpegCodec = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
            $encoderParams = New-Object Drawing.Imaging.EncoderParameters(1)
            $encoderParams.Param[0] = New-Object Drawing.Imaging.EncoderParameter([Drawing.Imaging.Encoder]::Quality, $Quality)

            $image.Save($outputPath, $jpegCodec, $encoderParams)
            $image.Dispose()

            Write-Host " Compressed: $fileName"
        } else {
            $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Skipped '$InputPath' (Unsupported format)"
            Add-Content -Path $logFile -Value $logEntry
            Write-Host " Skipped unsupported format: $fileName"
        }
    } catch {
        $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Failed to compress '$InputPath' - $_"
        Add-Content -Path $logFile -Value $logEntry
        Write-Host " Failed: $fileName"
    }
}


# Ask user for mode
$choice = Read-Host "Do you want to compress a single image or all images in a folder? (Enter 'single' or 'folder')"

# Get path(s)
if ($choice -eq "single") {
    $inputPath = Read-Host "Enter full path of the image file"
    $inputFiles = @($inputPath)
} elseif ($choice -eq "folder") {
    $folderPath = Read-Host "Enter full path of the folder"
    $inputFiles = Get-ChildItem -Path $folderPath -Include *.jpg,*.jpeg,*.png -Recurse | Select-Object -ExpandProperty FullName
} else {
    Write-Host "Invalid choice. Exiting."
    exit
}

# Output folder
$outputFolder = Read-Host "Enter full path to save compressed images"
if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# Quality
$quality = Read-Host "Enter compression quality (0-100)"
$quality = [int]$quality

# Log file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $outputFolder "compression_log_$timestamp.txt"

# Start compression
foreach ($file in $inputFiles) {
    Compress-Image -InputPath $file -OutputFolder $outputFolder -Quality $quality
}

Write-Host "`n Compression completed. Check log file if any errors occurred: $logFile"
