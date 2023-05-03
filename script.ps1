function Compare-JsonObjects {
    param(
        $Object1,
        $Object2
    )

    $differences = @()

    $allKeys = ($Object1.PSObject.Properties.Name + $Object2.PSObject.Properties.Name | Sort-Object | Get-Unique)

    foreach ($key in $allKeys) {
        $value1 = $Object1.$key
        $value2 = $Object2.$key

        if ($null -eq $value1 -or $null -eq $value2) {
            $differences += @{
                Property = $key
                Value1 = $value1
                Value2 = $value2
            }
        }
        elseif ($value1 -is [array] -and $value2 -is [array]) {
            if ($value1[0] -is [pscustomobject] -or $value2[0] -is [pscustomobject]) {
                $length1 = $value1.Length
                $length2 = $value2.Length

                for ($i = 0; $i -lt [Math]::Max($length1, $length2); $i++) {
                    $nestedDifferences = Compare-JsonObjects $value1[$i] $value2[$i]

                    if ($null -ne $nestedDifferences) {
                        $differences += @{
                            Property = "$key[$i]"
                            Value1 = $value1[$i]
                            Value2 = $value2[$i]
                            Differences = $nestedDifferences
                        }
                    }
                }
            }
            else {
                $sortedValue1 = ($value1 | Sort-Object) -join ","
                $sortedValue2 = ($value2 | Sort-Object) -join ","

                if ($sortedValue1 -ne $sortedValue2) {
                    $differences += @{
                        Property = $key
                        Value1 = $value1
                        Value2 = $value2
                    }
                }
            }
        }
        elseif ($value1 -is [pscustomobject] -and $value2 -is [pscustomobject]) {
            $nestedDifferences = Compare-JsonObjects $value1 $value2

            if ($null -ne $nestedDifferences) {
                $differences += @{
                    Property = $key
                    Value1 = $value1
                    Value2 = $value2
                    Differences = $nestedDifferences
                }
            }
        }
        elseif ($value1 -ne $value2) {
            $differences += @{
                Property = $key
                Value1 = $value1
                Value2 = $value2
            }
        }
    }

    if ($differences.Count -gt 0) {
        return $differences
    }
    else {
        return $null
    }
}

# Sample JSON objects
$json1 = @"
{
    "name": "John",
    "age": 30,
    "city": "New York",
    "hobbies": [
        "swimming",
        "reading"
    ],
    "job": [{
        "title": "Designer",
        "company": {"name":"ABC Corp","year":"2003"}

    }]
}
"@

$json2 = @"
{
    "age": 30,
    "name": "John",
    "city": "Los Angeles",
    "hobbies": [
        "reading",
        "swimming"
    ],
    "job": [{
        "title": "Designer",
        "company": {"name":"ABC Corp","year":"2003"}
    },{
        "company": {"name":"XYZ","year":"2003"},
        "title": "Engineer"
    },
    {
        "company": {"name":"ORS Corp","year":"2003"},
        "title": "Engineer"
    }],
    "newKey": "newValue"
}
"@

# Convert JSON to PowerShell objects
$object1 = $json1 | ConvertFrom-Json
$object2 = $json2 | ConvertFrom-Json

# Compare the JSON objects
$differences = Compare-JsonObjects $object1 $object2

# Display the differences using custom formatting
$differences | ForEach-Object {
    Write-Host "Property: $($_.Property)"
    Write-Host "Value1  : $($_.Value1)"
    Write-Host "Value2  : $($_.Value2)"
    Write-Host ""
}
