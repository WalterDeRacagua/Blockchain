# :calendar: Planify

Organiza tu tiempo y colabora con tu equipo como nunca antes. **Planify** es la herramienta definitiva para gestionar eventos, citas y tareas en un calendario colaborativo, accesible desde cualquier dispositivo. Di adiós al caos de horarios y hola a la productividad compartida.

Planify es una aplicación web (optimizada principalmente para móviles) que permite a los usuarios crear, compartir y gestionar calendarios en tiempo real, con funciones avanzadas de colaboración y notificaciones.

## 📂 Contenidos
- [Diseño de la Aplicación](#item1)
- [Instalación](#item2)
- [Uso](#item3)
- [Tecnologías Utilizadas](#item4)
- [Material Externo](#item5)
- [Contribución](#item6)
- [Contribuidores](#item7)
- [Licencia](#item8)

<a name="item1"></a>
## 🖥️ Diseño de la Aplicación
Planify ofrece una interfaz intuitiva con vistas adaptadas según el tipo de usuario (particular, equipo o administrador). Cada rol tiene permisos y funcionalidades específicas para optimizar la experiencia. A continuación, se detallan las vistas implementadas:

### 1. Vistas Implementadas
#### 🔹 Inicio
> **Descripción:** Pantalla principal con una visión general del calendario, eventos próximos y accesos rápidos a funciones clave.  
> **URL:** [`/`](http://localhost:8080/)

#### 🔹 Iniciar Sesión
> **Descripción:** Formulario para que usuarios individuales, equipos o administradores accedan a sus cuentas.  
> **URL:** [`/login`](http://localhost:8080/login)

#### 🔹 Ayuda
> **Descripción:** Sección con documentación, preguntas frecuentes y soporte técnico.  
> **URL:** [`/help`](http://localhost:8080/help)

### 2. Vistas de Usuario Particular
#### 🔹 Perfil
> **Descripción:** Espacio para gestionar datos personales, preferencias y notificaciones.  
> **URL:** [`/user/{id}`](http://localhost:8080/user/2)

#### 🔹 Mi Calendario
> **Descripción:** Vista personalizada del calendario con eventos y tareas del usuario.  
> **URL:** [`/user/calendar`](http://localhost:8080/user/calendar)  
> > **Vista Accesible:** Formulario para añadir un nuevo evento.  
> > **URL:** [`/user/add-event`](http://localhost:8080/user/add-event)

#### 🔹 Eventos
> **Descripción:** Lista de eventos activos con opciones para editar o eliminar.  
> **URL:** [`/user/my-events`](http://localhost:8080/user/my-events)

### 3. Vistas de Equipo
#### 🔹 Perfil de Equipo
> **Descripción:** Gestión de la cuenta del equipo, incluyendo miembros y permisos.  
> **URL:** [`/team/{id}`](http://localhost:8080/team/3)

#### 🔹 Calendario Compartido
> **Descripción:** Vista del calendario colaborativo con eventos de todos los miembros.  
> **URL:** [`/team/shared-calendar`](http://localhost:8080/team/shared-calendar)

#### 🔹 Gestión de Eventos
> **Descripción:** Herramienta para crear, modificar o supervisar eventos del equipo.  
> **URL:** [`/team/manage-events`](http://localhost:8080/team/manage-events)

#### 🔹 Invitar Miembros
> **Descripción:** Formulario para añadir nuevos integrantes al equipo.  
> **URL:** [`/team/invite`](http://localhost:8080/team/invite)

### 4. Próximamente
#### 🔹 Acerca de
> **Descripción:** Información sobre Planify y su propósito.

#### 🔹 Registrarse
> **Descripción:** Formulario para crear cuentas de usuario o equipo.

#### 🔹 Historial
> **Descripción:** Registro de eventos pasados con estadísticas de uso.

<a name="item2"></a>
## 🚀 Instalación

Sigue estos pasos para instalar y ejecutar Planify en tu máquina local:

1. Clona el repositorio:
   ```bash
   git clone https://github.com/usuario/planify.git
