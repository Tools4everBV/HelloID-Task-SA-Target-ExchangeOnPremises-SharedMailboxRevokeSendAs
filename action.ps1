# HelloID-Task-SA-Target-ExchangeOnPremises-SharedMailboxRevokeSendAs
#####################################################################
# Form mapping
$formObject = @{
    DisplayName     = $form.MailboxDisplayName
    MailboxIdentity = $form.MailboxIdentity
    UsersToRemove   = [array]$form.UsersToRemove
}

[bool]$IsConnected = $false
try {
    $adminSecurePassword = ConvertTo-SecureString -String $ExchangeAdminPassword -AsPlainText -Force
    $adminCredential = [System.Management.Automation.PSCredential]::new($ExchangeAdminUsername, $adminSecurePassword)
    $sessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck
    $exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $ExchangeConnectionUri -Credential $adminCredential -SessionOption $sessionOption -Authentication Kerberos  -ErrorAction Stop
    $null = Import-PSSession $exchangeSession -DisableNameChecking -AllowClobber -CommandName 'Add-ADPermission'
    $IsConnected = $true

    foreach ($user in $formObject.UsersToRemove) {
        Write-Information "Executing ExchangeOnPremises action: [SharedMailboxRevokeSendAs][$($user.UserPrincipalName)] for: [$($formObject.DisplayName)]"

        $null = Remove-ADPermission -Identity  $formObject.MailboxIdentity -ExtendedRights "Send As" -Confirm:$false -User $user.UserPrincipalName -ErrorAction Stop

        $auditLog = @{
            Action            = 'UpdateResource'
            System            = 'ExchangeOnPremises'
            TargetIdentifier  = $formObject.MailboxIdentity
            TargetDisplayName = $formObject.MailboxIdentity
            Message           = "ExchangeOnPremises action: [SharedMailboxRevokeSendAs][$($user.UserPrincipalName)] for: [$($formObject.DisplayName)] executed successfully"
            IsError           = $false
        }
        Write-Information -Tags 'Audit' -MessageData $auditLog
        Write-Information "ExchangeOnPremises action: [SharedMailboxRevokeSendAs][$($user.UserPrincipalName)] for: [$($formObject.DisplayName)] executed successfully"
    }
} catch {
    $ex = $_
    $auditLog = @{
        Action            = 'UpdateResource'
        System            = 'ExchangeOnPremises'
        TargetIdentifier  = $formObject.MailboxIdentity
        TargetDisplayName = $formObject.MailboxIdentity
        Message           = "Could not execute ExchangeOnPremises action: [SharedMailboxRevokeSendAs] for: [$($formObject.DisplayName)], error: $($ex.Exception.Message)"
        IsError           = $true
    }
    Write-Information -Tags 'Audit' -MessageData $auditLog
    Write-Error "Could not execute ExchangeOnPremises action: [SharedMailboxRevokeSendAs] for: [$($formObject.DisplayName)], error: $($ex.Exception.Message)"
} finally {
    if ($IsConnected) {
        Remove-PSSession -Session $exchangeSession -Confirm:$false  -ErrorAction Stop
    }
}
#####################################################################
