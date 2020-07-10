# Example of generating a large amount of Files and setting metadata term values for the generated items.
# Term values can be weighted based by repeating items in the term set to give a higher prefereance for a term
# Files are stored in the Documents library with a pathing convention of: Shared%20Documents/{country}/{department}/{subFolder}

# Weighted choices for list column Country of type managed metadata
$countryValues = @("Global","Global","US","US","US","UK","UK","UK","CA","CA","HI","MX")

# Weighted choices for list column Department of type managed metadata
$departmentValues = @("Engineering","Human Resources","Human Resources","Information Technology")

# Weighted choices for sub folder names
$subFolderNames = @("Employees","Employees","Employees","Contractors","Managers","Managers")

# path to template file that will be used for each file
$wordTemplatePath = "<file path>"

# Word bank that will be used to generate file names
$fileWordsList = @("Lorem","Ipsum","Dolor","Sit","Amet","Consectetur","Adipiscing","Elit","Curabitur","Gravida","Suscipit","Felis","Nec","Aliquam","Etiam","Porttitor","Nunc","Lorem","Eu","Tincidunt","Neque","Venenatis","At","Curabitur","Faucibus","Tempor","Elit","Sed","Condimentum","Nullam","Libero","Justo","Malesuada","A","Ipsum","Vitae","Aliquet","Luctus","Eros","Aenean","Posuere","Rutrum","Velit","In","Pulvinar","Bibendum","Magna","Vitae","Dapibus","Etiam")

# MMS terms with their term id used as choices for list column PolicyCategory of type managed metadata
$policyCategoryList = @{
"Health and Wellness"="0c5e89f8-c467-45f3-8aac-a83ac95e1f78"
"Other Benefit Plans"="5de917d8-b450-47a2-95da-57df2f5a63c8"
"Retirement and Savings"="65501997-6908-435a-8524-3552ef293d14"
"Career Development"="0b5b83b7-8cad-4617-aa8a-bdab8ff2d06a"
"Forms Library"="c06129d0-65dc-4512-a0d7-df749fa36e7b"
"HR for HR"="db8beeb8-f717-4381-a817-816c4b4ef254"
"Joiners"="e4b9c419-0c26-43b2-aa86-70946026c351"
"Leavers"="9b3e4b8b-3758-4997-8cd0-63cc06b73325"
"Compensation"="3e7044f2-8794-44e4-8a38-aec547d71e6d"                                                                                                                                                     
"Pay"="ac229aea-719c-47bf-b44c-d4861ea40e7b"
"Life Events"="85d19061-02c0-4b5e-b612-01ed5c95103a"
"Manager's Guide"="db5a8ccd-cc18-4dac-87f7-af8913591cc3"
"Recruiting and Hiring"="6450ea07-05b2-4920-8d69-c15a2b7c9c30"
"Talent and Performance"="c0714f71-4f18-47ed-b1e8-3049449bd08b"
"Leaves"="45dffd52-9344-4da2-838e-32c9e580f9ed"
"Time Off"="f34b583e-0a39-4625-959c-0e0bb3854b70"
"Workplace Policies"="34ed9863-ba52-4273-93bc-aea2bca6fddf"
}

$maxFilenameWords = 5
$minFilenameWords = 1

function GenerateFileName() {
    $numWords = Get-Random -Minimum $minFilenameWords -Maximum $maxFilenameWords -SetSeed (Get-Date).Millisecond
    $ary = @()
    for ([int]$i = 1; $i -le $numWords; $i++) {
        $ary += Get-Random -InputObject $fileWordsList -SetSeed (Get-Date).Millisecond
    }

    return $ary -join ' '
}

[int]$numFiles = 50

for ([int]$fileNum = 0; $fileNum -lt $numFiles; $fileNum++) {
    Write-Progress -Activity "adding files" -PercentComplete ((($fileNum+1)/$numFiles)*100)
    $countryPath = Get-Random -InputObject $countryValues -SetSeed (Get-Date).Millisecond
    $countryPath
    if ($countryPath -ne "Global") { $countryTerm = "Global|$($countryPath)" } else { $countryTerm = $countryPath }
    $countryTerm
    $department = Get-Random -InputObject $departmentValues -SetSeed (Get-Date).Millisecond
    $departmentco
    $subFolder = Get-Random -InputObject $subFolderNames -SetSeed (Get-Date).Millisecond
    $subFolder
    $policyCategory = $policyCategoryList.GetEnumerator() | Get-Random -SetSeed (Get-Date).Millisecond
    $fileName = "{0} {1}" -f $countryPath, (GenerateFileName)
    $fileName
    $newItem = Add-PnPFile -Path $wordTemplatePath -Folder ("Shared%20Documents/{0}/{1}/{2}" -f $countryPath, $department, $subFolder) -NewFileName ("{0}.docx" -f $fileName)
    $newItem.Context.Load($newItem.ListItemAllFields)
    $newItem.Context.ExecuteQuery()
    Set-PnPListItem -List "Documents" -Identity $newItem.ListItemAllFields.Id -ContentType "Policy Document" -Values @{"Country"=("Corporate Terms|Country|$($countryTerm)");"PolicyCategory"=$policyCategory.Value}
}