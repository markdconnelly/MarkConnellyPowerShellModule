Describe "Get-MDCUserBySecAttr" {
    Context "When filtering by valid custom security attributes" {
        It "Returns an array of users that match the selected custom security attributes" {
            # Mock the Connect-GraphAutomation function to avoid actual connection to Microsoft Graph API
            function Connect-GraphAutomation { return }

            # Create an array of user objects with custom security attributes
            $users = @()
            $users += [PSCustomObject]@{ Id = "1"; DisplayName = "John Smith"; CustomSecurityAttributes = @{ AttributeSet1 = @{ Attribute1 = "Value1" } } }
            $users += [PSCustomObject]@{ Id = "2"; DisplayName = "Jane Doe"; CustomSecurityAttributes = @{ AttributeSet1 = @{ Attribute1 = "Value2" } } }
            $users += [PSCustomObject]@{ Id = "3"; DisplayName = "Bob Johnson"; CustomSecurityAttributes = @{ AttributeSet2 = @{ Attribute2 = "Value1" } } }

            # Mock the Get-MgUser function to return the array of user objects
            function Get-MgUser {
                return $users
            }

            # Call the Get-MDCUserBySecAttr function with valid custom security attributes
            $result = Get-MDCUserBySecAttr -CustomSecurityAttributeSet "AttributeSet1" -CustomSecurityAttributeName "Attribute1" -CustomSecurityAttributeValue "Value1"

            # Assert that the result contains only the user with Id "1"
            $result.Id | Should Be "1"
            $result.DisplayName | Should Be "John Smith"
        }
    }

    Context "When filtering by invalid custom security attributes" {
        It "Returns an empty array" {
            # Mock the Connect-GraphAutomation function to avoid actual connection to Microsoft Graph API
            function Connect-GraphAutomation { return }

            # Create an array of user objects with custom security attributes
            $users = @()
            $users += [PSCustomObject]@{ Id = "1"; DisplayName = "John Smith"; CustomSecurityAttributes = @{ AttributeSet1 = @{ Attribute1 = "Value1" } } }
            $users += [PSCustomObject]@{ Id = "2"; DisplayName = "Jane Doe"; CustomSecurityAttributes = @{ AttributeSet1 = @{ Attribute1 = "Value2" } } }
            $users += [PSCustomObject]@{ Id = "3"; DisplayName = "Bob Johnson"; CustomSecurityAttributes = @{ AttributeSet2 = @{ Attribute2 = "Value1" } } }

            # Mock the Get-MgUser function to return the array of user objects
            function Get-MgUser {
                return $users
            }

            # Call the Get-MDCUserBySecAttr function with invalid custom security attributes
            $result = Get-MDCUserBySecAttr -CustomSecurityAttributeSet "AttributeSet2" -CustomSecurityAttributeName "Attribute2" -CustomSecurityAttributeValue "Value2"

            # Assert that the result is an empty array
            $result | Should Be @()
        }
    }
}
