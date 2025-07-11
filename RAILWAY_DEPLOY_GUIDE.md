# 🚀 Guía de Despliegue en Railway - Edtools Chatwoot

## 📋 Variables de Entorno Requeridas

### 🔧 Configuración Automática (Railway)
Estas variables las genera Railway automáticamente:
- `DATABASE_URL` - Conexión a PostgreSQL
- `REDIS_URL` - Conexión a Redis
- `PORT` - Puerto del servidor (automático)

### 🔑 Variables que DEBES Configurar

#### **Claves Secretas (CRÍTICAS)**
```bash
# Generar con: rails secret
SECRET_KEY_BASE=tu-clave-secreta-muy-larga-64-caracteres
DEVISE_JWT_SECRET_KEY=otra-clave-secreta-muy-larga-64-caracteres
```

#### **URLs de tu Aplicación**
```bash
# Reemplaza con tu dominio de Railway
FRONTEND_URL=https://tu-app.railway.app
HELPCENTER_URL=https://tu-app.railway.app
```

#### **Email (Opcional para empezar)**
```bash
MAILER_SENDER_EMAIL=noreply@tudominio.com
```

### 📧 Configuración de Email (Opcional)

Para usar email, agrega estas variables:
```bash
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=tu-email@gmail.com
SMTP_PASSWORD=tu-app-password
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
```

## 🎯 Pasos para Desplegar

### 1. **Preparar Servicios en Railway**

En tu dashboard de Railway:
1. **Añadir PostgreSQL** - Servicio → Database → PostgreSQL
2. **Añadir Redis** - Servicio → Database → Redis
3. **Conectar tu repositorio** - Servicio → GitHub → edtools-chatwoot

### 2. **Configurar Variables de Entorno**

En Railway Dashboard → Settings → Variables:

**Variables Críticas:**
```
SECRET_KEY_BASE=tu-clave-generada-con-rails-secret
DEVISE_JWT_SECRET_KEY=otra-clave-generada-con-rails-secret
FRONTEND_URL=https://tu-app.railway.app
HELPCENTER_URL=https://tu-app.railway.app
```

**Variables Opcionales:**
```
MAILER_SENDER_EMAIL=noreply@tudominio.com
ENABLE_ACCOUNT_SIGNUP=true
FORCE_SSL=true
```

### 3. **Generar Claves Secretas**

```bash
# En tu terminal local, ejecuta:
rails secret
# Copia el resultado a SECRET_KEY_BASE

rails secret
# Copia el resultado a DEVISE_JWT_SECRET_KEY
```

### 4. **Desplegar**

```bash
# Hacer commit de los cambios
git add .
git commit -m "Optimizar configuración para Railway"
git push origin main
```

Railway detectará automáticamente los cambios y redesplegar.

## 🔍 Verificación del Despliegue

### ✅ Checks de Éxito

1. **Logs de Railway** deben mostrar:
   ```
   ✅ Database migration completed
   ✅ Assets precompiled
   ✅ Server starting on port 3000
   ✅ Puma starting in cluster mode
   ```

2. **URL de tu app** debe cargar sin error 502

3. **Healthcheck** debe responder OK

### ❌ Problemas Comunes

**Error 502 persiste:**
- Revisa que `SECRET_KEY_BASE` y `DEVISE_JWT_SECRET_KEY` estén configurados
- Verifica que `FRONTEND_URL` apunte a tu dominio Railway
- Checa logs de Railway para errores específicos

**Error de Base de Datos:**
- Confirma que PostgreSQL esté conectado
- Verifica que `DATABASE_URL` esté presente

**Error de Redis:**
- Confirma que Redis esté conectado
- Verifica que `REDIS_URL` esté presente

## 🎛️ Configuración Avanzada

### pgvector (AI Features)

Si quieres funciones completas de IA:
1. Usa Railway PostgreSQL template con pgvector
2. O tu configuración actual funcionará con modo fallback

### Workers de Sidekiq

Para activar workers:
1. Ve a Railway Dashboard
2. Añade nuevo servicio desde el mismo repositorio
3. Configura comando: `bundle exec sidekiq -C config/sidekiq.yml`

### Almacenamiento de Archivos

Para producción, considera:
- AWS S3: Configura `S3_BUCKET_NAME`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- O mantén `ACTIVE_STORAGE_SERVICE=local` para empezar

## 🔧 Comandos Útiles

```bash
# Ver logs en tiempo real
railway logs

# Conectar a la base de datos
railway connect

# Ejecutar migraciones manualmente
railway run bundle exec rails db:migrate

# Generar nueva clave secreta
railway run rails secret
```

## 🆘 Soporte

Si tienes problemas:
1. Revisa los logs de Railway
2. Verifica que todas las variables estén configuradas
3. Confirma que PostgreSQL y Redis estén conectados
4. Asegúrate de que no tengas errores en el código

## 📊 Monitoreo

Railway proporciona:
- Métricas de CPU y memoria
- Logs en tiempo real
- Alertas automáticas
- Healthchecks

Tu aplicación estará lista en: `https://tu-app.railway.app`

---

*Esta guía está optimizada para tu configuración específica de edtools-chatwoot y Railway.*