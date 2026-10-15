# Guía de Contribución para FreshBox

¡Gracias por querer contribuir! Para mantener la arquitectura limpia, sigue estas reglas:

1. **Ramificaciones (Branching):** Nunca hagas push directo a `main`. Crea ramas como `feat/nuevo-microservicio` o `fix/seguridad`.
2. **Infraestructura:** Cualquier cambio en Terraform debe ser probado localmente con `terraform plan` antes de subirlo.
3. **Seguridad:** No añadas nunca archivos `.tfstate` o credenciales al repositorio. Usa las variables de entorno configuradas en GitHub Actions.
4. **Manifiestos K8s:** Cada servicio nuevo debe tener su propio Deployment y Service siguiendo la nomenclatura existente (`<nombre>-deployment.yaml`).

Cualquier cambio será validado automáticamente por el pipeline de CI/CD.
