[Setup your variables](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/store-information-in-variables) so that:

- `JAMF_PRO_URL` should be `https://yourcompany.jamfcloud.com`
- `CLIENT_ID` should be the generated Client ID from your Jamf Instance.
- `CLIENT_SECRET` should be the generated Client Secret from your Jamf Instance.

```yml
name: jamfGitSync

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

  workflow_dispatch:

jobs:
  push-changes-to-jamf-pro-1:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 2

      - name: Install Requirements
        run: sudo apt-get update && sudo apt-get install jq -y

      - name: Push Changes to Jamf Pro Server 1
        run: ./jamfGitSync.sh --url ${{ vars.JAMF_PRO_URL }} --clientid ${{ vars.CLIENT_ID }} --clientsecret ${{ secrets.CLIENT_SECRET }} --push-changes-to-jamf-pro --backup-updated
        
      - name: Archive Backups
        uses: actions/upload-artifact@v3
        with:
          name: jamf-pro-backups
          path: backups
```
