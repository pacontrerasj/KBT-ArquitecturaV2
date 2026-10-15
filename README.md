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

## Escenarios de Despliegue: Producción vs. Laboratorio
Este repositorio contiene una arquitectura de nivel profesional (Producción). Sin embargo, para permitir su despliegue exitoso en entornos limitados como **AWS Learner Lab**, he aplicado las siguientes consideraciones:

1. **Configuración de Seguridad Avanzada (Comentada):**
   - Recursos como `KMS Keys` (Cifrado de Secrets en EKS) y `VPC Flow Logs` (Auditoría de red) están presentes en el código pero comentados. 
   - *Justificación:* Estos recursos requieren privilegios elevados de IAM (`iam:CreateRole`, `kms:CreateKey`) que suelen estar restringidos en cuentas de estudiante.
   - *Modo Producción:* Para llevar esto a un entorno empresarial real, simplemente descomenta los bloques de código marcados como "CONFIGURACIÓN PRO" y asegúrate de que el Service Account del pipeline tenga los permisos IAM necesarios.

2. **Justificación de Riesgos:**
   - He priorizado la viabilidad del despliegue (asegurando que el pipeline de GitHub Actions funcione) sobre la implementación de logs de auditoría profundos, manteniendo el resto de las capas de seguridad (Trivy, Checkov, NetworkPolicies) totalmente operativas.


---
*Documentación técnica mantenida por Pablo, Arquitecto de Soluciones FreshBox.*
