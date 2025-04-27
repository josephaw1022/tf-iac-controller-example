# IAC Controller Demo

This project sets up a local GitOps environment using:
- **KinD** (Kubernetes in Docker)
- **Flux CD**
- **Tofu Controller** (Terraform GitOps Controller)
- **LocalStack** (AWS Cloud API Mock)

---

## 🛠 Prerequisites

You need these installed:

- Podman
- AWS CLI
- kubectl
- KinD
- Make
- Bash shell

✅ Works on Linux, MacOS, and Windows (WSL2 or native).

---

## 🚀 Quick Start

### 1. Bootstrap Full Environment

```bash
make bootstrap
```

This will:
- Create a KinD cluster
- Install LocalStack
- Install Flux
- Install Tofu Controller
- Apply Terraform GitOps resources

---

## 🔎 Verify Setup

### Step 1: Open a new terminal tab and port-forward LocalStack

```bash
make localstack-port-forward
```

_(Leave this running)_

---

### Step 2: In your original terminal tab, check resources

```bash
make awscli s3 ls
```

You should see something like:

```
2025-04-27 17:05:35 example-tf-iac-bucket
```

---

## 🧹 Cleanup

When you're done:

```bash
make delete-flux-tf
make delete-cluster
```