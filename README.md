# FreshBox EP3: Arquitectura Hibrida EKS + Serverless

FreshBox evoluciona de una plataforma EKS (EP2) a una arquitectura hibrida en AWS: los productos siguen en microservicios sobre EKS y el carrito/ordenes se procesan con Lambda, API Gateway, DynamoDB y SQS. El frontend se publica como sitio estatico en S3.

## Arquitectura

```text
Navegador
   |
   +--> S3 (frontend estatico)
   |
   +--> API Gateway (REST, stage prod)
          |
          +--> /api/products* ----------> ALB -> EKS (4 microservicios) -> RDS MySQL
          |
          +--> /api/cart* --------------> Lambda procesar-carrito -> DynamoDB
          |
          +--> /api/orders ------------> Lambda crear-orden -> DynamoDB + SQS
                                                               |
                                                               v
                                                    Lambda procesar-orden
                                                    -> RDS MySQL
                                                    -> limpia DynamoDB
```

### Componentes

- **EKS**: get-products, create-product, update-product, delete-product. Servicios `NodePort`; el ALB los expone con `target-type: instance`.
- **API Gateway**: 8 rutas requeridas por la guia + `GET /api/products/{id}` adicional, con CORS. Los productos se integran por `HTTP_PROXY` al ALB; carrito y ordenes por `AWS_PROXY` a Lambda.
- **Lambdas**:
  - `freshbox-procesar-carrito`: GET/POST/DELETE del carrito en DynamoDB.
  - `freshbox-crear-orden`: lee el carrito, calcula total y publica en SQS.
  - `freshbox-procesar-orden`: consumer SQS, inserta en MySQL y limpia el carrito.
- **DynamoDB**: tabla `carrito-freshbox`, PK `userId`, SK `productId`, TTL.
- **SQS**: cola de ordenes con DLQ y redrive.
- **RDS MySQL**: `productos` y `ordenes`; la inicializacion se ejecuta con un Job de Kubernetes.
- **S3**: `freshbox-frontend-<ACCOUNT_ID>`, sitio web estatico. El pipeline inyecta la URL de API Gateway en `js/config.js`.

## Estructura

```text
Freshbox/
  lambdas/                    # 3 funciones Lambda y sus dependencias
  microserviciosEKSBackend/   # 4 microservicios de productos
  microservicioEKSFrontend/   # frontend estatico para S3
k8s/                          # Deployments, Services, Ingress, HPA, NetworkPolicy y Job SQL
terraform/
  modules/vpc/                # VPC, subnets, endpoints, tags ALB
  modules/eks/                # Cluster y node group
  modules/rds/                # MySQL privado
  modules/ecr/                # Repos de las 4 imagenes backend
  modules/dynamodb/           # Carrito
  modules/messaging/          # SQS + DLQ
  modules/serverless/         # Lambdas, API Gateway, CORS y trigger SQS
sql/init.sql                  # Esquema y datos de demostracion
```

## Pipeline

`.github/workflows/pipeline.yaml` se ejecuta en `push` a `main` y tiene 5 etapas:

1. **lint-and-validate**: TFLint, Checkov y validacion de YAML.
2. **terraform**: empaqueta Lambdas, aprovisiona infraestructura y publica `rds_endpoint` y `vpc_id`.
3. **build-and-push**: construye y escanea las 4 imagenes backend; ya no construye frontend.
4. **deploy**: instala AWS Load Balancer Controller, aplica manifiestos, elimina el frontend de EKS y espera el DNS del ALB.
5. **finalize**: segundo `terraform apply` con `alb_dns`, publica el frontend en S3, ejecuta el Job SQL y hace pruebas end-to-end.

### Por que dos applies

El ALB lo crea el AWS Load Balancer Controller a partir del Ingress, por lo que su DNS no existe en el primer apply. API Gateway se crea apuntando a un placeholder y el job `finalize` lo actualiza con el DNS real. El trigger de `aws_api_gateway_deployment` incluye `alb_dns` para forzar el redeploy.

## Despliegue

### Requisitos

- Cuenta AWS Academy Learner Lab con `LabRole`.
- Secretos del repositorio:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_SESSION_TOKEN`
  - `DB_PASSWORD` (8-41 caracteres, sin `/`, `"`, `@` ni espacios)

Las credenciales de Learner Lab expiran. Si el pipeline falla en `aws sts get-caller-identity`, actualiza los tres secretos de AWS.

### Ejecucion

1. Hacer merge a `main` o lanzar el workflow manualmente.
2. Revisar el resumen del run: URLs de API Gateway, frontend S3 y endpoint RDS.
3. Verificar los recursos en la consola AWS.
4. Guardar evidencias: RDS, Lambda, API Gateway, SQS, DynamoDB, bucket S3 y pruebas de carrito/orden.

### Validacion local

```bash
cd terraform
terraform fmt -recursive
terraform init -backend=false
terraform validate
tflint

cd ..
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/pipeline.yaml'))"
kubectl apply --dry-run=client --validate=false -f k8s/
```

No ejecutar `terraform apply` ni `destroy` localmente: el pipeline es el unico responsable de modificar AWS.

## Endpoints

Con el stage `prod`:

- `GET /api/products`
- `POST /api/products`
- `GET /api/products/{id}` (adicional, no contado en las 8 rutas de la guia)
- `PUT /api/products/{id}`
- `DELETE /api/products/{id}`
- `GET /api/cart?userId=...`
- `POST /api/cart`
- `DELETE /api/cart/{productId}?userId=...`
- `POST /api/orders`

## Seguridad y restricciones del laboratorio

- **LabRole**: el Learner Lab restringe `iam:CreateRole`; las Lambdas usan `LabRole`. En produccion se debe inyectar `lambda_role_arn` con roles de minimo privilegio por funcion.
- **S3 por CLI**: el proveedor de Terraform no puede leer buckets por una restriccion de `s3:GetBucketObjectLockConfiguration`; el pipeline crea y configura el bucket con AWS CLI.
- **Sin NAT Gateway**: Process-Order corre en subnets privadas y usa el VPC endpoint de DynamoDB; RDS es privado. Cart y Create-Order corren fuera de la VPC.
- **NetworkPolicy**: default-deny; se permite DNS, MySQL y trafico entre pods. El ALB en modo `instance` conserva el origen dentro de la VPC.
- **RDS**: `MultiAZ=false` y `gp2` en el lab. En produccion usar `db_multi_az=true`, `gp3` y una clase adecuada.
- **Imagenes**: el pipeline construye `linux/amd64` para los nodos `t3.medium`. El script `scripts/ecr-push.sh` de la carpeta padre compila `arm64` y no debe usarse.

## Diferencias con la guia docente

- La guia sugiere VPC `/22`; el proyecto usa `/16` para mantener el rango existente de EP2.
- La guia sugiere EKS en subnets privadas; el proyecto mantiene los nodos en subnets publicas para evitar NAT Gateway en Learner Lab.
- La guia sugiere `db.t4g.small`; el proyecto usa `db.t3.micro` por disponibilidad/costo en el lab. `db_multi_az` queda como variable.
- Se usan 3 Lambdas y 8 rutas, igual que la guia, pero los roles son `LabRole` por restriccion de IAM.

## Destruccion

El workflow `Destroy Infrastructure` elimina Terraform, ECR y, por defecto, el bucket S3 del frontend. El bucket de state se conserva salvo que se marque `delete_state_bucket`.

## Evidencias recomendadas

- `aws rds describe-db-instances` con RDS privado y disponible.
- `aws lambda list-functions` con las 3 funciones.
- `aws apigateway get-rest-apis` y URL del stage `prod`.
- `aws sqs get-queue-attributes` y DLQ.
- `aws dynamodb describe-table`.
- `aws s3 ls` y URL del sitio.
- Flujo E2E: agregar al carrito, crear orden y verificar que el carrito queda vacio.
- Run de GitHub Actions en verde con los jobs `terraform`, `deploy` y `finalize`.

---

Documentacion actualizada para EP3. Mantener el detalle de decisiones y restricciones al entregar.
