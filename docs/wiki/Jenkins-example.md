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
