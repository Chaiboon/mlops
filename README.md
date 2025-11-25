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

# Verify UI

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