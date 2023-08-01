# Function to convert bytes to GB
function ConvertTo-GB {
    param (
        [Parameter(ValueFromPipeline = $true)]
        [double]$Size
    )
    process {
        $SizeGB = $Size / 1GB
        [math]::Round($SizeGB, 2)
    }
}

# Function to get SMART status
function Get-SmartStatus {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DriveLetter
    )
    process {
        $smartStatus = Get-CimInstance -Namespace "root\wmi" -ClassName "MSStorageDriver_FailurePredictStatus" | Where-Object { $_.InstanceName -like "*$DriveLetter*" }
        if ($smartStatus.PredictFailure -eq $false) {
            return "Healthy"
        } else {
            return "Failing"
        }
    }
}

# Output file path for the report
$reportPath = "C:\StorageReport\DailyStorageReport_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').txt"

# Get volume information using Get-Volume cmdlet
$volumes = Get-Volume

# Get physical disk information using Get-PhysicalDisk cmdlet
$physicalDisks = Get-PhysicalDisk

# Create the report content
$reportContent = @"
Daily Storage Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm')

Volume and Physical Disk Information:
-------------------------------------

"@

foreach ($volume in $volumes) {
    $volumeInfo = @{
        'Drive Letter' = $volume.DriveLetter
        'File System' = $volume.FileSystem
        'Capacity (GB)' = "{0:N2}" -f (ConvertTo-GB $volume.Size)
        'Free Space (GB)' = "{0:N2}" -f (ConvertTo-GB $volume.SizeRemaining)
        'Used Space (GB)' = "{0:N2}" -f (ConvertTo-GB ($volume.Size - $volume.SizeRemaining))

    }

    $reportContent += $volumeInfo.GetEnumerator() | ForEach-Object {
        $label = $_.Key
        $value = $_.Value
        "{0,-15}: {1,12}" -f $label, $value
    }

    $reportContent += "`n"
}

$reportContent += @"
Physical Disk Information:
-------------------------

"@

foreach ($disk in $physicalDisks) {
    $diskInfo = @{
        'Device ID' = $disk.DeviceID
        'Manufacturer' = $disk.Manufacturer
        'Model' = $disk.Model
        'Capacity (GB)' = "{0:N2}" -f (ConvertTo-GB $disk.Size)
        'Health Status' = $disk.HealthStatus

    }

    $reportContent += $diskInfo.GetEnumerator() | ForEach-Object {
        $label = $_.Key
        $value = $_.Value
        "{0,-15}: {1,12}" -f $label, $value
    }

    $reportContent += "`n"
}

# Save the report to the specified path
$reportContent | Out-File -FilePath $reportPath

# Output the report on the console
Write-Output $reportContent
