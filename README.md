# FreshBox: Arquitectura K8s de Alta Disponibilidad

## Nota del Arquitecto (Pablo)
Como Arquitecto Líder de este proyecto, mi objetivo ha sido transformar la infraestructura monolítica de FreshBox en un ecosistema basado en microservicios resilientes, escalables y seguros sobre Kubernetes (EKS). Esta migración no es solo un cambio tecnológico; es una evolución hacia una arquitectura preparada para el crecimiento acelerado, manteniendo la seguridad como pilar fundamental a pesar de las restricciones del entorno de laboratorio.

## Resumen de Diseño
- **Evolución:** Hemos pasado de una arquitectura basada en EC2 (Prueba 1) a una orquestada por Kubernetes (Prueba 2), permitiendo auto-escalado horizontal (HPA) basado en demanda real de CPU.
- **Alta Disponibilidad:** Despliegue distribuido en múltiples zonas de disponibilidad, garantizando que el servicio persista ante fallos de infraestructura.
- **Seguridad "Defense in Depth":** 
    - **Aislamiento de red:** Implementación de `NetworkPolicies` (Deny-All) para reducir la superficie de ataque.
    - **Cadena de suministro:** Integración de `Trivy` en CI/CD para escanear vulnerabilidades en imágenes antes de cualquier despliegue.
    - **Gestión de estado:** Uso de S3 + DynamoDB para garantizar integridad en los despliegues de infraestructura.

## Estructura del Repositorio
- `Freshbox/`: Código fuente de microservicios (Backend y Frontend).
- `k8s/`: Definiciones de despliegue, HPA, NetworkPolicies e Ingress.
- `terraform/`: Infraestructura como Código (IaC) modularizada (VPC, EKS, RDS, ECR).

## Cómo Desplegar
1. **Infraestructura:** Asegurarse de tener configurado el backend de Terraform (S3/DynamoDB). Ejecutar `terraform init` y `terraform apply` desde la carpeta `terraform/`.
2. **CI/CD:** El pipeline en `.github/workflows/pipeline.yaml` gestiona automáticamente la construcción, escaneo y despliegue.
3. **Secretos:** Configurar `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` y `AWS_REGION` en los GitHub Secrets del repositorio.

---
*Documentación técnica mantenida por Pablo, Arquitecto de Soluciones FreshBox.*
