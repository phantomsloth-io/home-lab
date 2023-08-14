#!/bin/bash
read -p "Reset Argo-cd? (y/n)" proceed
if [ "$proceed" = "y" ]; then
	echo "Removing any existing argo files\n"
	kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	echo "Reinstalling Argo-cd\n"	
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	checkIp=false
	read -p "Patching argocd-server Load-Balancer. What should the IP be?" argoIp
	while [ "$checkIp" = false ]; do
		if [[ $argiIp =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                	checkIp=true
			kubectl patch service argocd-server -n argocd --patch '{ "spec": { "type": "LoadBalancer", "loadBalancerIP": "'$argoIp'" } }'
        	else
                	echo "Invalid IP address, try again"
        	fi		
	done
	echo "Logging into argocd cli"
	original_pw=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo)
	argocd login $argoIp --username admin --password $original_pw --insecure
	echo "Successfully logged in"
	read "Would you like to reset the admin password? (y/n)" resetPass
	if ["$resetPass" = "y"]; then
		newPass="foo"
		newPassConfirm="bar"
		while [ "$newPass" != "$newPassConfirm" ]; do
			read -p -s "Enter new password:" newPass
			read -p -s "Repeat new password:" newPassConfirm
			if [ "$newPass" != "$newPassConfirm" ]; then
				echo "Passwords do not match, please try again:"
			else
				echo "Password changed"
				break
			fi
		done
	fi
	echo "Logging into argocd cli with new password"
	argocd login $argoIp --username admin --password $newPass --insecure
	echo "Successfully logged in"
	echo "Checking for repo configuration"
	repoUrl=$(argocd repo list -o json | jq '[.[] ] | .[0]'.repo)
	repoName=$(argocd repo list -o json | jq '[.[] ] | .[0]'.name)
	echo "Found the following repos:"
	argocd repo list
	read -p "\nWould you like to use any of these repos? (y/n)" oldRepo
	if [ "$oldRepo" = "n" ]; then
		read -p "Would you like to add a new repo? (y/n)" newRepo
		if [ "$newRepo" = "y" ]; then
			read -p "What is your github url?" newRepoUrl
			read -p "What is the location of your github SSH private key?" newRepoPrivateKey
			echo "Creating integration"
			argocd repo add $newRepoUrl --insecure-ignore-host-key --ssh-private-key-path $newRepoPrivateKey
			repoUrl=$newRepoUrl
		fi
	fi
	echo "Found the following applications:"
	argocd app list
	read -p "\nWould you like to create a new Argocd application? (y/n)" newApp
	if [ "$newApp" = "y" ]; then
		read -p "What is your application name?" appName
		read -p "What is your destination namespace? [argocd]" namespace
		namespaces=${namespace:-argocd}
		read -p "What is your destination server? [https://kubernetes.default.svc]" appUrl
		appUrl=${appUrl:-https://kubernetes.default.svc}
		read -p "What is your repo Url? [$repoUrl]" repoUrl
		read -p "What is your repo path?" repoPath
		argocd app create $appName --dest-namespace $namespace --dest-server $appUrl --repo $repoUrl --path $repoPath
		echo "Application created"
	else
		echo "Done! Please open ArgoCD UI Here: $argoIp"
else
  echo "goodbye"
fi

