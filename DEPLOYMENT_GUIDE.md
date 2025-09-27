# InnovateMart EKS Deployment Guide
**Project Bedrock - Production-Ready Kubernetes Infrastructure**

## Architecture Overview

This deployment creates a complete production-grade Kubernetes environment on AWS EKS with the following components:

### Infrastructure Components
- **Amazon EKS Cluster**: Kubernetes 1.28 with managed node groups
- **VPC**: Custom VPC with public/private subnets across 2 availability zones
- **Compute**: 2x t3.small EC2 instances (11 pods per node capacity)
- **Load Balancing**: AWS Application Load Balancer integration
- **Databases**: RDS PostgreSQL, RDS MySQL, and DynamoDB for microservices
- **Security**: IAM roles, policies, and read-only developer access

### Application Services
- **UI Service**: Frontend web interface (Spring Boot)
- **Catalog Service**: Product catalog management with MySQL backend
- **Cart Service**: Shopping cart functionality with DynamoDB backend
- **Orders Service**: Order processing with PostgreSQL backend
- **Assets Service**: Static file serving
- **Checkout Service**: Payment processing with Redis session storage

## Quick Start

### Prerequisites
- Terraform >= 1.6.0
- AWS CLI configured with appropriate permissions
- kubectl installed
- Git repository access

### Deployment Steps

1. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd innovatemart-bedrock
   ```

2. **Deploy Infrastructure**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

3. **Configure Kubernetes Access**
   ```bash
   aws eks update-kubeconfig --region eu-west-3 --name innovatemart-bedrock
   ```

4. **Deploy Application**
   ```bash
   kubectl apply -f retail-store-app.yaml
   ```

## Accessing the Application

### Main Application URL
The retail store application is accessible via the AWS Load Balancer:
```
http://abcf5af1839a94d93b9d00d0635b583d-2124112865.eu-west-3.elb.amazonaws.com/
```

## Developer Access Configuration

### Read-Only Developer User
A dedicated IAM user has been created for development team access:

**Credentials:**
- **Username**: `innovatemart-bedrock-developer-readonly`
- **Access Key ID**: `Deployed Separately`
- **Secret Access Key**: `Deployed Separately`

### Setting Up Developer Access

1. **Configure AWS CLI Profile**
   ```bash
   aws configure --profile innovatemart-developer
   # Enter the credentials above
   # Region: eu-west-3
   # Format: json
   ```

2. **Configure kubectl**
   ```bash
   aws eks update-kubeconfig --region eu-west-3 --name innovatemart-bedrock --profile innovatemart-developer
   ```

3. **Test Access**
   ```bash
   # These commands should work (read operations)
   kubectl get pods -n retail-store
   kubectl get nodes
   kubectl logs <pod-name> -n retail-store
   kubectl describe pod <pod-name> -n retail-store
   
   # These commands should fail (write operations)
   kubectl delete pod <pod-name> -n retail-store  # Should return "Forbidden"
   kubectl scale deployment ui --replicas=2 -n retail-store  # Should return "Forbidden"
   ```

## CI/CD Pipeline

### GitHub Actions Workflow
The repository includes automated CI/CD pipeline using GitHub Actions:

**Triggering Events:**
- **Pull Requests to main**: Runs `terraform plan` and security scanning
- **Pushes to main**: Runs `terraform apply` for automated deployment

**Required GitHub Secrets:**
```
AWS_ACCESS_KEY_ID=<your-aws-access-key>
AWS_SECRET_ACCESS_KEY=<your-aws-secret-key>
```

### Branching Strategy
- **Feature branches**: Create PR to trigger plan and validation
- **Main branch**: Automated deployment on merge
- **Security**: All changes reviewed via PR process

## Database Configuration

### Managed AWS Services
The deployment uses managed AWS services for production-grade persistence:

**PostgreSQL (Orders Service):**
- **Endpoint**: `innovatemart-bedrock-postgres.cd4mkqiuq2rz.eu-west-3.rds.amazonaws.com:5432`
- **Database**: `orders`
- **Instance**: `db.t3.micro`

**MySQL (Catalog Service):**
- **Endpoint**: `innovatemart-bedrock-mysql.cd4mkqiuq2rz.eu-west-3.rds.amazonaws.com:3306`
- **Database**: `catalog` 
- **Instance**: `db.t3.micro`

**DynamoDB (Cart Service):**
- **Table Name**: `innovatemart-bedrock-carts`
- **Billing**: Pay-per-request
- **GSI**: `customerId-index`

### Database Credentials
Database credentials are securely stored in:
- AWS Secrets Manager (recommended for production)
- Kubernetes secrets (current implementation)

## Infrastructure as Code

### Terraform Modules
The infrastructure is organized into reusable modules:

```
terraform/
├── main.tf              # Main configuration and module calls
├── variables.tf         # Input variables and defaults
├── outputs.tf          # Infrastructure outputs
├── versions.tf         # Provider version constraints
└── modules/
    ├── vpc/            # VPC, subnets, routing
    ├── eks/            # EKS cluster and node groups
    ├── rds/            # Managed databases
    └── iam/            # IAM roles and policies
```

### Key Resources Created
- **EKS Cluster**: `innovatemart-bedrock`
- **VPC**: `vpc-03655ee2fc4d46ab2`
- **Node Group**: 2x t3.small instances
- **RDS Instances**: PostgreSQL and MySQL
- **DynamoDB Table**: Carts storage
- **IAM Roles**: Cluster, node groups, load balancer controller
- **Security Groups**: Database access controls

## Monitoring and Troubleshooting

### Common Commands
```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# View application logs
kubectl logs -f deployment/ui -n retail-store

# Check service endpoints
kubectl get svc -n retail-store

# Describe resources for troubleshooting
kubectl describe pod <pod-name> -n retail-store
```

### Application Health Checks
Individual services can be tested:
```bash
# Catalog service API
kubectl port-forward service/catalog 8081:80 -n retail-store
curl http://localhost:8081/catalogue

# Check database connectivity
kubectl exec -it <catalog-pod> -n retail-store -- nc -zv catalog-mysql 3306
```

## Security Implementation

### Network Security
- **Private Subnets**: Application pods run in private subnets
- **Security Groups**: Database access restricted to EKS nodes
- **NAT Gateways**: Controlled internet access for private resources

### Access Control
- **IAM Roles**: Least-privilege access for EKS services
- **RBAC**: Kubernetes role-based access control
- **Read-Only Access**: Developer user cannot modify cluster resources

### Secrets Management
- Database passwords automatically generated and rotated
- AWS Secrets Manager integration for production credentials
- Kubernetes secrets for application configuration

## Cost Optimization

### Current Monthly Costs (Estimated)
- **EKS Cluster**: ~$73/month (control plane)
- **EC2 Instances**: ~$30/month (2x t3.small)
- **RDS Instances**: ~$40/month (2x db.t3.micro)
- **Load Balancers**: ~$16/month
- **NAT Gateways**: ~$32/month
- **Total**: ~$191/month

### Cost Reduction Options
- Use t3.micro for development environments
- Implement scheduled scaling for non-production
- Consider Fargate for serverless container execution
- Use RDS Aurora Serverless for variable workloads

## Cleanup and Destruction

To completely remove all infrastructure:

```bash
# Destroy Kubernetes resources first
kubectl delete namespace retail-store

# Then destroy AWS infrastructure
cd terraform
terraform destroy
```

**Warning**: This will permanently delete all data and resources.

## Support and Next Steps

### Production Readiness Checklist
- [ ] Enable EKS cluster logging
- [ ] Implement monitoring with CloudWatch/Prometheus
- [ ] Set up automated backups for RDS instances
- [ ] Configure SSL/TLS certificates
- [ ] Implement network policies
- [ ] Set up disaster recovery procedures

### Scaling Considerations
- **Horizontal Pod Autoscaler**: Scale pods based on CPU/memory
- **Cluster Autoscaler**: Add/remove nodes based on demand
- **Database Read Replicas**: Scale read operations
- **Multi-Region Deployment**: For global availability

---

**Deployment Date**: September 2025  
**Infrastructure Version**: v1.0  
**Cluster**: `innovatemart-bedrock`  
**Region**: `eu-west-3` (Paris)