First of all, make sure you're all set with the requirements and the steps mentioned in the [README.md](https://github.com/74k1/jamfGitSync#usage).

If you've got additional usecases that arent listed here but would like to contribute, feel free to create an [ISSUE](https://github.com/74k1/jamfGitSync/issues). I'm looking forward to it!

Afterwards, your Pipelines _could_ look something like this (ofcourse this depends on your own setup, and these are just examples):

## Jenkins

[Setup your variables](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/) so that:

- `$CLIENT_SECRET` should be the generated Client Secret from your Jamf Instance.

Make sure to replace `YOUR_INSTANCE` with something like `https://yourcompany.jamfcloud.com` and `YOUR_CLIENT_ID` with your Client ID from Jamf.

```Groovy
pipeline {
  agent any
  
  options {
    buildDiscarder(logRotator(numToKeepStr: "10", artifactNumToKeepStr: "10"))
    timeout(time: 30, unit: "MINUTES")
    timestamps()
  }

  stages {
    stage('Push Changes to Jamf Pro Server') {
      steps {
        // Execute the script with parameters
        sh './jamfScriptSync.sh --url YOUR_INSTANCE --clientid YOUR_CLIENT_ID --clientsecret ${JAMF_API_SECRET} --push-changes-to-jamf-pro --backup-updated'
        
        // Archive backups
        archiveArtifacts artifacts: 'backups/**', fingerprint: true
      }
    }
  }
}
```

## Bitbucket

[Setup your variables](https://support.atlassian.com/bitbucket-cloud/docs/variables-and-secrets/) so that:

- `$JAMF_PRO_URL` should be `https://yourcompany.jamfcloud.com`
- `$CLIENT_ID` should be the generated Client ID from your Jamf Instance.
- `$CLIENT_SECRET` should be the generated Client Secret from your Jamf Instance.

```yml
image: atlassian/default-image:3

pipelines:
  default:
     - step:
         name: 'Update changes in Jamf Pro server'
         clone:
           depth: 2
         script:
           - apt-get update && apt-get install libxml2-utils xmlstarlet -y
           - ./jamfGitSync.sh --url "$JAMF_PRO_URL" --clientid "$CLIENT_ID" --clientsecret "$CLIENT_SECRET" --push-changes-to-jamf-pro --backup-updated
         artifacts:
           - backups/**
```

## Github Workflows

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

## CircleCI

[Setup your variables](https://circleci.com/docs/env-vars/) so that:

- `$JAMF_PRO_URL` should be `https://yourcompany.jamfcloud.com`
- `$CLIENT_ID` should be the generated Client ID from your Jamf Instance.
- `$CLIENT_SECRET` should be the generated Client Secret from your Jamf Instance.

```yml
version: 2.1

jobs:
  push-changes-to-jamf-pro:
    docker:
      - image: cimg/base:stable
    steps:
      - checkout
      - run:
          name: "Install Requirements"
          command: sudo apt-get update && sudo apt-get install jq -y
      - run:
          name: "Update changes in Jamf Pro Server 1"
          command: ./jamfGitSync.sh --url "$JAMF_PRO_URL" --clientid "$CLIENT_ID" --clientsecret "$CLIENT_SECRET" --push-changes-to-jamf-pro --backup-updated
      - store_artifacts:
          path: ./backups

workflows:
  jamfGitSync-workflow:
    jobs:
      - push-changes-to-jamf-pro
```
