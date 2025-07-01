# Jenkins Pipeline Templates

## Overview
This collection provides production-ready Jenkins pipeline templates using both Declarative and Scripted syntax, including advanced patterns for CI/CD, multi-branch pipelines, and shared libraries.

## Basic Declarative Pipeline

### Node.js Application Pipeline
```groovy
// Jenkinsfile
pipeline {
    agent {
        label 'docker'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 60, unit: 'MINUTES')
        timestamps()
        ansiColor('xterm')
        disableConcurrentBuilds()
    }
    
    environment {
        DOCKER_REGISTRY = 'registry.example.com'
        DOCKER_IMAGE = "${DOCKER_REGISTRY}/myapp"
        DOCKER_CREDENTIALS = credentials('docker-registry-creds')
        SONAR_CREDENTIALS = credentials('sonarqube-token')
        NODE_VERSION = '18'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                    env.GIT_BRANCH_NAME = sh(
                        script: "git rev-parse --abbrev-ref HEAD",
                        returnStdout: true
                    ).trim()
                }
            }
        }
        
        stage('Setup') {
            steps {
                nodejs(nodeJSInstallationName: "NodeJS-${NODE_VERSION}") {
                    sh '''
                        node --version
                        npm --version
                        npm ci
                    '''
                }
            }
        }
        
        stage('Quality Gates') {
            parallel {
                stage('Lint') {
                    steps {
                        nodejs(nodeJSInstallationName: "NodeJS-${NODE_VERSION}") {
                            sh 'npm run lint'
                        }
                    }
                }
                
                stage('Unit Tests') {
                    steps {
                        nodejs(nodeJSInstallationName: "NodeJS-${NODE_VERSION}") {
                            sh 'npm run test:unit -- --coverage'
                        }
                    }
                    post {
                        always {
                            junit 'coverage/junit.xml'
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'coverage',
                                reportFiles: 'index.html',
                                reportName: 'Coverage Report'
                            ])
                        }
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        nodejs(nodeJSInstallationName: "NodeJS-${NODE_VERSION}") {
                            sh 'npm audit --production'
                            sh 'npx snyk test --severity-threshold=high'
                        }
                    }
                }
            }
        }
        
        stage('SonarQube Analysis') {
            when {
                branch 'main'
            }
            steps {
                withSonarQubeEnv('SonarQube') {
                    nodejs(nodeJSInstallationName: "NodeJS-${NODE_VERSION}") {
                        sh """
                            npx sonar-scanner \
                                -Dsonar.projectKey=myapp \
                                -Dsonar.sources=src \
                                -Dsonar.tests=tests \
                                -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
                                -Dsonar.login=${SONAR_CREDENTIALS}
                        """
                    }
                }
            }
        }
        
        stage('Quality Gate') {
            when {
                branch 'main'
            }
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Build') {
            steps {
                nodejs(nodeJSInstallationName: "NodeJS-${NODE_VERSION}") {
                    sh 'npm run build'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}:${GIT_COMMIT_SHORT}")
                }
            }
        }
        
        stage('Scan Docker Image') {
            steps {
                sh """
                    trivy image \
                        --severity HIGH,CRITICAL \
                        --no-progress \
                        --exit-code 1 \
                        ${DOCKER_IMAGE}:${GIT_COMMIT_SHORT}
                """
            }
        }
        
        stage('Push Docker Image') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-registry-creds') {
                        def image = docker.image("${DOCKER_IMAGE}:${GIT_COMMIT_SHORT}")
                        image.push()
                        if (env.BRANCH_NAME == 'main') {
                            image.push('latest')
                        }
                    }
                }
            }
        }
        
        stage('Deploy to Dev') {
            when {
                branch 'develop'
            }
            steps {
                build job: 'deploy-to-environment', 
                    wait: true,
                    parameters: [
                        string(name: 'ENVIRONMENT', value: 'dev'),
                        string(name: 'IMAGE_TAG', value: "${GIT_COMMIT_SHORT}"),
                        string(name: 'SERVICE', value: 'myapp')
                    ]
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
                build job: 'deploy-to-environment', 
                    wait: true,
                    parameters: [
                        string(name: 'ENVIRONMENT', value: 'prod'),
                        string(name: 'IMAGE_TAG', value: "${GIT_COMMIT_SHORT}"),
                        string(name: 'SERVICE', value: 'myapp')
                    ]
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            slackSend(
                color: 'good',
                message: "Build Successful: ${env.JOB_NAME} - ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
            )
        }
        failure {
            slackSend(
                color: 'danger',
                message: "Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
            )
        }
    }
}
```

## Multi-Branch Pipeline

### Advanced Multi-Branch Configuration
```groovy
// Jenkinsfile
@Library('jenkins-shared-library') _

pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: node
    image: node:18-alpine
    command:
    - cat
    tty: true
  - name: docker
    image: docker:20-dind
    securityContext:
      privileged: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
"""
        }
    }
    
    environment {
        APP_NAME = 'myapp'
        BRANCH_NAME = "${env.BRANCH_NAME}"
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        
        // Dynamic environment based on branch
        DEPLOY_ENV = "${env.BRANCH_NAME == 'main' ? 'production' : 
                      env.BRANCH_NAME == 'develop' ? 'staging' : 
                      env.BRANCH_NAME.startsWith('feature/') ? 'dev' : 'none'}"
    }
    
    stages {
        stage('Prepare') {
            steps {
                script {
                    // Dynamic versioning
                    if (env.BRANCH_NAME == 'main') {
                        env.VERSION = sh(
                            script: "git describe --tags --abbrev=0 || echo '0.0.0'",
                            returnStdout: true
                        ).trim()
                    } else {
                        env.VERSION = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
                    }
                    
                    // Set build description
                    currentBuild.description = "Version: ${env.VERSION}"
                }
            }
        }
        
        stage('Build & Test') {
            parallel {
                stage('Frontend') {
                    when {
                        changeset "frontend/**"
                    }
                    steps {
                        container('node') {
                            dir('frontend') {
                                sh '''
                                    npm ci
                                    npm run lint
                                    npm run test
                                    npm run build
                                '''
                            }
                        }
                    }
                }
                
                stage('Backend') {
                    when {
                        changeset "backend/**"
                    }
                    steps {
                        container('node') {
                            dir('backend') {
                                sh '''
                                    npm ci
                                    npm run lint
                                    npm run test
                                    npm run build
                                '''
                            }
                        }
                    }
                }
            }
        }
        
        stage('Build Images') {
            when {
                not {
                    equals expected: 'none', actual: DEPLOY_ENV
                }
            }
            steps {
                container('docker') {
                    script {
                        def services = ['frontend', 'backend']
                        services.each { service ->
                            if (fileExists("${service}/Dockerfile")) {
                                def image = docker.build(
                                    "${APP_NAME}-${service}:${VERSION}",
                                    "./${service}"
                                )
                                
                                docker.withRegistry('https://registry.example.com', 'docker-creds') {
                                    image.push()
                                    if (env.BRANCH_NAME == 'main') {
                                        image.push('latest')
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        stage('Deploy') {
            when {
                not {
                    equals expected: 'none', actual: DEPLOY_ENV
                }
            }
            steps {
                container('kubectl') {
                    withCredentials([
                        file(credentialsId: "kubeconfig-${DEPLOY_ENV}", variable: 'KUBECONFIG')
                    ]) {
                        sh """
                            kubectl set image deployment/${APP_NAME}-frontend \
                                frontend=registry.example.com/${APP_NAME}-frontend:${VERSION} \
                                -n ${DEPLOY_ENV}
                            
                            kubectl set image deployment/${APP_NAME}-backend \
                                backend=registry.example.com/${APP_NAME}-backend:${VERSION} \
                                -n ${DEPLOY_ENV}
                            
                            kubectl rollout status deployment/${APP_NAME}-frontend -n ${DEPLOY_ENV}
                            kubectl rollout status deployment/${APP_NAME}-backend -n ${DEPLOY_ENV}
                        """
                    }
                }
            }
        }
        
        stage('Integration Tests') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    def testJob = build job: 'integration-tests',
                        propagate: false,
                        wait: true,
                        parameters: [
                            string(name: 'ENVIRONMENT', value: DEPLOY_ENV),
                            string(name: 'VERSION', value: VERSION)
                        ]
                    
                    if (testJob.result != 'SUCCESS') {
                        error "Integration tests failed"
                    }
                }
            }
        }
    }
    
    post {
        always {
            container('kubectl') {
                sh 'kubectl version || true'
            }
        }
    }
}
```

## Scripted Pipeline

### Advanced Scripted Pipeline
```groovy
// Jenkinsfile
@Library('jenkins-shared-library') _

node('docker') {
    def dockerImage
    def appVersion
    
    try {
        stage('Checkout') {
            checkout scm
            
            // Get version from package.json
            appVersion = sh(
                script: "node -p \"require('./package.json').version\"",
                returnStdout: true
            ).trim()
            
            // Add build metadata
            appVersion = "${appVersion}-${env.BUILD_NUMBER}"
            
            echo "Building version: ${appVersion}"
        }
        
        stage('Parallel Build') {
            parallel(
                'Build Application': {
                    nodejs(nodeJSInstallationName: 'NodeJS-18') {
                        sh 'npm ci'
                        sh 'npm run build'
                    }
                },
                'Security Scan': {
                    sh 'trivy fs --severity HIGH,CRITICAL .'
                },
                'Dependency Check': {
                    dependencyCheck additionalArguments: '''
                        --format HTML
                        --format JSON
                        --prettyPrint
                    ''', odcInstallation: 'dependency-check'
                    
                    dependencyCheckPublisher pattern: 'dependency-check-report.json'
                }
            )
        }
        
        stage('Test') {
            try {
                nodejs(nodeJSInstallationName: 'NodeJS-18') {
                    sh 'npm test'
                }
            } finally {
                junit 'test-results/**/*.xml'
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'coverage',
                    reportFiles: 'index.html',
                    reportName: 'Test Coverage'
                ])
            }
        }
        
        stage('Build Docker Image') {
            dockerImage = docker.build("myapp:${appVersion}")
            
            // Scan the image
            sh "trivy image --exit-code 1 --severity HIGH,CRITICAL myapp:${appVersion}"
        }
        
        stage('Publish') {
            if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'develop') {
                docker.withRegistry('https://registry.example.com', 'docker-creds') {
                    dockerImage.push()
                    
                    if (env.BRANCH_NAME == 'main') {
                        dockerImage.push('latest')
                    }
                }
            }
        }
        
        stage('Deploy') {
            if (env.BRANCH_NAME == 'main') {
                milestone label: 'Production Deploy'
                
                timeout(time: 30, unit: 'MINUTES') {
                    input message: 'Deploy to production?',
                          ok: 'Deploy',
                          submitter: 'admin,lead-dev'
                }
                
                withCredentials([
                    string(credentialsId: 'prod-deploy-token', variable: 'DEPLOY_TOKEN')
                ]) {
                    sh """
                        curl -X POST \
                            -H "Authorization: Bearer ${DEPLOY_TOKEN}" \
                            -H "Content-Type: application/json" \
                            -d '{"version": "${appVersion}"}' \
                            https://deploy.example.com/api/deploy/production
                    """
                }
            }
        }
        
        currentBuild.result = 'SUCCESS'
        
    } catch (Exception e) {
        currentBuild.result = 'FAILURE'
        throw e
        
    } finally {
        // Notifications
        def buildStatus = currentBuild.result ?: 'SUCCESS'
        def colorCode = buildStatus == 'SUCCESS' ? '#36a64f' : '#ff0000'
        
        slackSend(
            color: colorCode,
            message: """
                *${buildStatus}:* Job `${env.JOB_NAME}` build `${env.BUILD_NUMBER}`
                *Version:* ${appVersion}
                *Branch:* ${env.BRANCH_NAME}
                *Duration:* ${currentBuild.durationString}
                <${env.BUILD_URL}|View Build>
            """.stripIndent()
        )
        
        // Cleanup
        cleanWs()
    }
}
```

## Shared Library

### Library Structure
```groovy
// vars/standardPipeline.groovy
def call(Map config) {
    pipeline {
        agent {
            label config.agent ?: 'docker'
        }
        
        environment {
            APP_NAME = config.appName
            DOCKER_REGISTRY = config.dockerRegistry ?: 'registry.example.com'
        }
        
        stages {
            stage('Checkout') {
                steps {
                    checkout scm
                }
            }
            
            stage('Build') {
                steps {
                    script {
                        buildApp(config)
                    }
                }
            }
            
            stage('Test') {
                steps {
                    script {
                        testApp(config)
                    }
                }
            }
            
            stage('Package') {
                steps {
                    script {
                        packageApp(config)
                    }
                }
            }
            
            stage('Deploy') {
                when {
                    expression { shouldDeploy(config) }
                }
                steps {
                    script {
                        deployApp(config)
                    }
                }
            }
        }
        
        post {
            always {
                notifications(config)
                cleanup(config)
            }
        }
    }
}

// vars/buildApp.groovy
def call(Map config) {
    def buildType = config.buildType ?: detectBuildType()
    
    switch(buildType) {
        case 'node':
            nodejs(nodeJSInstallationName: "NodeJS-${config.nodeVersion ?: '18'}") {
                sh 'npm ci'
                sh 'npm run build'
            }
            break
        case 'maven':
            withMaven(maven: 'Maven-3.8') {
                sh 'mvn clean package'
            }
            break
        case 'gradle':
            sh './gradlew build'
            break
        default:
            error "Unknown build type: ${buildType}"
    }
}

// vars/notifications.groovy
def call(Map config) {
    def status = currentBuild.currentResult
    def color = status == 'SUCCESS' ? 'good' : 'danger'
    def emoji = status == 'SUCCESS' ? ':white_check_mark:' : ':x:'
    
    if (config.notifications?.slack?.enabled) {
        slackSend(
            channel: config.notifications.slack.channel ?: '#builds',
            color: color,
            message: "${emoji} *${env.JOB_NAME}* - Build #${env.BUILD_NUMBER} - *${status}*\n" +
                    "Branch: ${env.BRANCH_NAME}\n" +
                    "<${env.BUILD_URL}|View Build>"
        )
    }
    
    if (config.notifications?.email?.enabled) {
        emailext(
            subject: "${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - ${status}",
            body: """
                <h2>Build ${status}</h2>
                <p>Job: ${env.JOB_NAME}</p>
                <p>Build: ${env.BUILD_NUMBER}</p>
                <p>Branch: ${env.BRANCH_NAME}</p>
                <p><a href="${env.BUILD_URL}">View Build</a></p>
            """,
            to: config.notifications.email.recipients,
            mimeType: 'text/html'
        )
    }
}
```

### Using Shared Library
```groovy
// Jenkinsfile
@Library('jenkins-shared-library') _

standardPipeline([
    appName: 'my-application',
    buildType: 'node',
    nodeVersion: '18',
    dockerRegistry: 'registry.example.com',
    deploy: [
        dev: [
            branch: 'develop',
            autoDeloy: true
        ],
        prod: [
            branch: 'main',
            requireApproval: true,
            approvers: ['admin', 'tech-lead']
        ]
    ],
    notifications: [
        slack: [
            enabled: true,
            channel: '#my-app-builds'
        ],
        email: [
            enabled: true,
            recipients: 'team@example.com'
        ]
    ]
])
```

## Kubernetes Pipeline

### Kubernetes Agent Pipeline
```groovy
pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
spec:
  serviceAccountName: jenkins
  containers:
  - name: maven
    image: maven:3.8-openjdk-11
    command:
    - sleep
    args:
    - 99d
    volumeMounts:
    - name: maven-cache
      mountPath: /root/.m2
  - name: docker
    image: docker:20-dind
    securityContext:
      privileged: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - sleep
    args:
    - 99d
  - name: helm
    image: alpine/helm:latest
    command:
    - sleep
    args:
    - 99d
  volumes:
  - name: maven-cache
    persistentVolumeClaim:
      claimName: maven-cache
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
'''
        }
    }
    
    environment {
        DOCKER_REGISTRY = 'registry.example.com'
        APP_NAME = 'my-k8s-app'
        NAMESPACE = "${env.BRANCH_NAME == 'main' ? 'production' : 'staging'}"
    }
    
    stages {
        stage('Build') {
            steps {
                container('maven') {
                    sh 'mvn clean package'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                container('docker') {
                    script {
                        def image = docker.build("${DOCKER_REGISTRY}/${APP_NAME}:${env.BUILD_ID}")
                        docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-creds') {
                            image.push()
                            image.push('latest')
                        }
                    }
                }
            }
        }
        
        stage('Deploy with Helm') {
            steps {
                container('helm') {
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                        sh """
                            helm upgrade --install ${APP_NAME} ./helm-chart \
                                --namespace ${NAMESPACE} \
                                --set image.repository=${DOCKER_REGISTRY}/${APP_NAME} \
                                --set image.tag=${env.BUILD_ID} \
                                --set ingress.host=${APP_NAME}-${NAMESPACE}.example.com \
                                --wait \
                                --timeout 10m
                        """
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                container('kubectl') {
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                        sh """
                            kubectl rollout status deployment/${APP_NAME} -n ${NAMESPACE}
                            kubectl get pods -n ${NAMESPACE} -l app=${APP_NAME}
                        """
                    }
                }
            }
        }
    }
}
```

## GitOps Pipeline

### ArgoCD Integration
```groovy
pipeline {
    agent any
    
    environment {
        GIT_REPO = 'https://github.com/company/k8s-configs.git'
        GIT_CREDS = credentials('github-token')
        APP_NAME = 'myapp'
    }
    
    stages {
        stage('Update Manifests') {
            steps {
                script {
                    def gitConfigRepo = checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/main']],
                        userRemoteConfigs: [[
                            url: env.GIT_REPO,
                            credentialsId: 'github-token'
                        ]]
                    ])
                    
                    def environment = env.BRANCH_NAME == 'main' ? 'production' : 'staging'
                    def manifestPath = "applications/${APP_NAME}/${environment}/kustomization.yaml"
                    
                    // Update image tag
                    sh """
                        sed -i 's|newTag:.*|newTag: ${env.BUILD_ID}|' ${manifestPath}
                        
                        git config user.name "Jenkins CI"
                        git config user.email "jenkins@example.com"
                        git add ${manifestPath}
                        git commit -m "Update ${APP_NAME} to ${env.BUILD_ID} in ${environment}"
                        git push https://${GIT_CREDS_USR}:${GIT_CREDS_PSW}@github.com/company/k8s-configs.git
                    """
                }
            }
        }
        
        stage('Sync ArgoCD') {
            steps {
                withCredentials([string(credentialsId: 'argocd-token', variable: 'ARGOCD_TOKEN')]) {
                    sh """
                        argocd app sync ${APP_NAME}-${environment} \
                            --auth-token ${ARGOCD_TOKEN} \
                            --server argocd.example.com \
                            --grpc-web
                        
                        argocd app wait ${APP_NAME}-${environment} \
                            --auth-token ${ARGOCD_TOKEN} \
                            --server argocd.example.com \
                            --grpc-web \
                            --timeout 300
                    """
                }
            }
        }
    }
}
```

## Pipeline as Code Configuration

### Organization Folder Configuration
```groovy
// jenkins-config/jobs/organization-folder.groovy
organizationFolder('GitHub Organization') {
    description('Scan GitHub organization for repos with Jenkinsfiles')
    displayName('My Organization')
    
    organizations {
        github {
            repoOwner('my-organization')
            credentialsId('github-credentials')
            traits {
                gitHubBranchDiscovery {
                    strategyId(1) // Exclude branches that are also PRs
                }
                gitHubPullRequestDiscovery {
                    strategyId(1) // Merge with target branch
                }
                gitHubForkDiscovery {
                    strategyId(1) // Merge with target branch
                    trust {
                        gitHubTrustPermissions()
                    }
                }
            }
        }
    }
    
    projectFactories {
        workflowMultiBranchProjectFactory {
            scriptPath('Jenkinsfile')
        }
    }
    
    orphanedItemStrategy {
        discardOldItems {
            numToKeep(20)
            daysToKeep(30)
        }
    }
    
    triggers {
        periodicFolderTrigger {
            interval('1d')
        }
    }
}
```

## Best Practices

1. **Pipeline Structure**
   - Use Declarative syntax for simple pipelines
   - Use Scripted for complex logic
   - Leverage shared libraries for reusability
   - Keep Jenkinsfiles in source control

2. **Performance**
   - Use parallel stages when possible
   - Cache dependencies
   - Clean workspace selectively
   - Use lightweight executors

3. **Security**
   - Store credentials in Jenkins
   - Use credentials binding
   - Implement RBAC
   - Regular security updates

4. **Monitoring**
   - Set up build notifications
   - Monitor build trends
   - Track pipeline metrics
   - Regular cleanup of old builds