# mlops

## Prequisition

1. Docker 4.50.0 (209931)
2. Kubernetes v1.34.1
3. Helm v4.0.0
4. kind v0.30.0 

# Installation
```
chmod +x scripts/install_stack.sh
./scripts/install_infra.sh
```
[!NOTE]
**Don't Panic if KServe installation fails initially!**
 
During the **KServe** installation, you may see red error messages like `INSTALLATION FAILED` or `connection refused`. 
 
This is a known race condition where the KServe Webhook is not yet ready to validate resources. The `install_stack.sh` script is designed to handle this automatically:
1. It detects the failure.
2. It cleans up the "zombie" webhooks blocking the installation.
3. It waits 15 seconds and successfully retries.
 
**Action:** Please be patient and let the script finish. You will see a message: `⚠️ First attempt hit the Race Condition. Retrying...`
Verify UI

Minio
```
kubectl port-forward -n kserve service/minio-service 9000:9000 9001:9001
```

http://localhost:9000

mlflow
```
kubectl port-forward -n kserve service/mlflow-service 5000:5000
```
http://localhost:5000