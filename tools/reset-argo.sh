#!/bin/bash
set -e

# Verify required dependencies
for cmd in kubectl jq argocd; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ Error: Required dependency '$cmd' is not installed." >&2
        exit 1
    fi
done

read -p "Reset Argo CD? (y/n): " proceed
if [ "$proceed" = "y" ] || [ "$proceed" = "Y" ]; then
    echo "Removing any existing Argo CD installation..."
    kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml || true
    
    echo "Creating Argo CD namespace..."
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    echo "Reinstalling Argo CD..."
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    read -p "Patching argocd-server LoadBalancer. What should the IP be?: " argoIp
    if [ -z "$argoIp" ]; then
        echo "❌ Error: IP address cannot be empty." >&2
        exit 1
    fi
    
    kubectl patch service argocd-server -n argocd --patch "{ \"spec\": { \"type\": \"LoadBalancer\", \"loadBalancerIP\": \"$argoIp\" } }"
    
    echo "⏳ Waiting for Argo CD Server deployment to be ready..."
    kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
    
    echo "Logging into Argo CD CLI..."
    original_pw=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo
    
    argocd login "$argoIp" --username admin --password "$original_pw" --insecure
    echo "Successfully logged in."
    
    read -p "Would you like to reset the admin password? (y/n): " resetPass
    if [ "$resetPass" = "y" ] || [ "$resetPass" = "Y" ]; then
        newPass="foo"
        newPassConfirm="bar"
        while [ "$newPass" != "$newPassConfirm" ]; do
            read -s -p "Enter new password: " newPass
            echo
            read -s -p "Repeat new password: " newPassConfirm
            echo
            if [ "$newPass" != "$newPassConfirm" ]; then
                echo "❌ Passwords do not match, please try again."
            else
                echo "🔄 Updating Argo CD admin password..."
                if argocd account update-password --current-password "$original_pw" --new-password "$newPass" --insecure; then
                    echo "✅ Password changed successfully."
                    break
                else
                    echo "❌ Failed to change password. Please try again."
                    newPass="foo"
                    newPassConfirm="bar"
                fi
            fi
        done
        
        echo "Logging into Argo CD CLI with new password..."
        argocd login "$argoIp" --username admin --password "$newPass" --insecure
        echo "Successfully logged in."
    fi
    
    echo "Checking for repository configuration..."
    repoUrl=$(argocd repo list -o json 2>/dev/null | jq -r '.[0].repo // empty')
    repoName=$(argocd repo list -o json 2>/dev/null | jq -r '.[0].name // empty')
    
    echo "Found the following repositories:"
    argocd repo list
    
    read -p "Would you like to use any of these repositories? (y/n): " oldRepo
    if [ "$oldRepo" = "n" ] || [ "$oldRepo" = "N" ]; then
        read -p "Would you like to add a new repository? (y/n): " newRepo
        if [ "$newRepo" = "y" ] || [ "$newRepo" = "Y" ]; then
            read -p "What is your GitHub URL?: " newRepoUrl
            read -p "What is the location of your GitHub SSH private key?: " newRepoPrivateKey
            echo "Creating repository integration..."
            argocd repo add "$newRepoUrl" --insecure-ignore-host-key --ssh-private-key-path "$newRepoPrivateKey"
            repoUrl=$newRepoUrl
        fi
    fi
    
    echo "Found the following applications:"
    argocd app list
    
    read -p "Would you like to create a new Argo CD application? (y/n): " newApp
    if [ "$newApp" = "y" ] || [ "$newApp" = "Y" ]; then
        read -p "What is your application name?: " appName
        read -p "What is your destination namespace? [argocd]: " namespace
        namespace=${namespace:-argocd}
        read -p "What is your destination server? [https://kubernetes.default.svc]: " appUrl
        appUrl=${appUrl:-https://kubernetes.default.svc}
        read -p "What is your repository URL? [$repoUrl]: " inputRepoUrl
        repoUrl=${inputRepoUrl:-$repoUrl}
        read -p "What is your repository path?: " repoPath
        
        argocd app create "$appName" \
            --dest-namespace "$namespace" \
            --dest-server "$appUrl" \
            --repo "$repoUrl" \
            --path "$repoPath"
        echo "✅ Application created."
    else
        echo "Done! Please open Argo CD UI here: https://$argoIp"
    fi
else
    echo "Goodbye."
fi
