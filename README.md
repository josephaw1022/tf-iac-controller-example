# IAC Controller Demo

This project sets up a local GitOps flow using:
- KinD (Kubernetes in Docker)
- Flux CD
- Tofu Controller
- LocalStack (AWS service emulation)

---

## 🛠 Prerequisites

- Podman 
- AWS CLI (`aws`)
- kubectl (`kubectl`)
- KinD (`kind`)
- Make (`make`)
- Bash shell available (`bash`)

✅ Compatible with Linux, MacOS, and Windows (WSL2 or native installations)

## 🚀 Quick Start

### 1. Start LocalStack

```bash
make localstack-up
```

### 2. Create Kubernetes Cluster

```bash
make create-cluster
```

### 3. Install Flux and Tofu Controller

```bash
make install-flux
make install-tofu-controller
```

### 4. Deploy GitOps Resources

```bash
make apply-flux-tf
```

---

## 🔍 Verify

Use AWS CLI to interact with LocalStack:

```bash
make awscli s3 ls
```

> Example: list S3 buckets created by Terraform.

---

## 🧹 Cleanup

```bash
make delete-flux-tf
make delete-cluster
make localstack-down
```
