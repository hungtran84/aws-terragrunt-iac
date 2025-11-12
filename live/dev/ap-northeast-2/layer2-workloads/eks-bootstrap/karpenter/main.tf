# Karpenter Configuration Resources
# EC2NodeClass and NodePool for Karpenter auto-scaling

locals {
  karpenter_enabled = var.karpenter_enabled && var.enable_karpenter_config
}

################################################################################
# EC2NodeClass - Defines how Karpenter configures EC2 instances
################################################################################

resource "kubectl_manifest" "karpenter_ec2nodeclass" {
  count = local.karpenter_enabled ? 1 : 0
  
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
      labels:
        app.kubernetes.io/part-of: eks-bootstrap
        app.kubernetes.io/managed-by: terraform
    spec:
      amiSelectorTerms:
        - alias: bottlerocket@latest
      
      role: ${var.cluster_name}-karpenter-node
      
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      
      tags:
        karpenter.sh/discovery: ${var.cluster_name}
        Environment: ${var.environment}
        ManagedBy: terraform
        Component: eks-bootstrap
        Name: ${var.cluster_name}-karpenter-node
  YAML
}

################################################################################
# NodePool - Defines when to provision nodes and instance requirements
################################################################################

resource "kubectl_manifest" "karpenter_nodepool_default" {
  count = local.karpenter_enabled ? 1 : 0
  
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
      labels:
        app.kubernetes.io/part-of: eks-bootstrap
        app.kubernetes.io/managed-by: terraform
    spec:
      template:
        metadata:
          labels:
            nodepool: default
            environment: ${var.environment}
        spec:
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: default
          
          requirements:
            # Architecture
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
            
            # Operating System
            - key: kubernetes.io/os
              operator: In
              values: ["linux"]
            
            # Capacity Type (on-demand or spot)
            - key: karpenter.sh/capacity-type
              operator: In
              values: ${jsonencode(var.karpenter_capacity_type)}
            
            # Instance Categories (c, m, r, t, etc.)
            - key: karpenter.k8s.aws/instance-category
              operator: In
              values: ${jsonencode(var.karpenter_instance_categories)}
            
            # Instance Generation (greater than 2 = gen 3+)
            - key: karpenter.k8s.aws/instance-generation
              operator: Gt
              values: ["${var.karpenter_instance_generation}"]
      
      # Resource limits for all nodes managed by this NodePool
      limits:
        cpu: ${var.karpenter_nodepool_limits.cpu}
        memory: ${var.karpenter_nodepool_limits.memory}
      
      # Disruption settings
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 1m
      
      # Priority weight (higher = preferred)
      weight: 10
  YAML
  
  depends_on = [kubectl_manifest.karpenter_ec2nodeclass]
}

################################################################################
# Additional NodePool for Spot Instances (Disabled by default)
################################################################################

resource "kubectl_manifest" "karpenter_nodepool_spot" {
  count = 0  # Disabled - can be enabled if spot instances are needed
  
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: spot
      labels:
        app.kubernetes.io/part-of: eks-bootstrap
        app.kubernetes.io/managed-by: terraform
    spec:
      template:
        metadata:
          labels:
            nodepool: spot
            environment: ${var.environment}
        spec:
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: default
          
          requirements:
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
            - key: kubernetes.io/os
              operator: In
              values: ["linux"]
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot"]
            - key: karpenter.k8s.aws/instance-category
              operator: In
              values: ["c", "m", "r"]
            - key: karpenter.k8s.aws/instance-generation
              operator: Gt
              values: ["3"]
      
      limits:
        cpu: 200
        memory: 800Gi
      
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 30s
      
      weight: 5  # Lower priority than on-demand
  YAML
  
  depends_on = [kubectl_manifest.karpenter_ec2nodeclass]
}
