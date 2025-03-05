0. Install Docker && Docker-Compose
```console
curl -sSL https://raw.githubusercontent.com/docker/docker-install/master/install.sh | sudo bash 
sudo usermod -aG docker $USER
curl -sSL https://raw.githubusercontent.com/dcodev1702/install_docker/main/install_docker-compose.sh | sudo bash
```

1. Build ASP .NET APP on Ubuntu Linux
-------------------------------------
Install DOTNET SDK 9.0
```console
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
```
```console
sudo apt update
sudo apt install -y dotnet-sdk-9.0
```
Open up VS Code
---------------
 - Connect to Ubbuntu
   - Install C# Plugin
   - Docker Plugin

Create Basic DOTNET Web App:
----------------------------
```console
dotnet new webapp -o DemoApp
```
```console
dotnet publish -c Release -o ./publish
```
```console
cp Dockerfile DemoApp/publish
cd publish
```

2. The following command can be used to build a custom image
```console
sudo docker build -t demoapp .
```
3. Install Azure CLI
https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt

4. First log into the Azure container registry

This is not working for some reason, so just log into Azure CLI with your identity </br>
~~sudo az acr login --name squidproxy007 --username squidproxy007 --password < !!! COPY_PASSWORD_HERE !!! >~~

5. Then tag your image
```console
sudo docker tag demoapp squidproxy007.azurecr.io/demoapp:latest
```
6. Then push the image to the Azure Container registry
```console
sudo docker push squidproxy007.azurecr.io/demoapp:latest
```
7. Run an instance of the container in ACI
```console
az container create --resource-group MIR --location eastus2 --name demoapp-container --image squidproxy007.azurecr.io/demoapp:latest --registry-password <!!! COPY_PASSWORD_HERE !!!> --registry-username squidproxy007 --cpu 1 --memory 2 --vnet ZoADLab-VNET --os-type Linux --subnet ContainerNet --ports 8080 --environment-variables http_proxy="http://localhost:8080" --log-analytics-workspace <WORKSPACE_ID> --log-analytics-workspace-key <WORKSPACE SHARED KEY>
```

9. Log into a VM that has access to that subnet
   - Bring up web browser
     - Go to: http://10.0.2.5:8080

10. Go to Azure Container Instance and take a look at the container.

11. Investigate container table (CL) in Log Analytics
  - ContainerEvent_CL
  - ContainerInstanceLog_CL
