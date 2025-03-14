# :calendar: Planify

Organiza tu tiempo y colabora con tu equipo como nunca antes. **Planify** es la herramienta definitiva para gestionar eventos, citas y tareas en un calendario colaborativo, accesible desde cualquier dispositivo. Di adiós al caos de horarios y hola a la productividad compartida.

Planify es una aplicación de escritorio que permite a los usuarios crear, compartir y gestionar calendarios y eventos.

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
Planify ofrece una interfaz intuitiva con vistas. A continuación, se detallan las vistas implementadas hasta el momento:

### 1. Vistas Implementadas
#### 🔹 Inicio
> **Descripción:** Pantalla principal con una visión general del calendario.

#### 🔹 Crear un evento
> **Descripción:** Formulario para crear un evento dentro de Planify. Debes rellenar un formulario ingresando un nombre no vacío con un máximo 20 caracteres, una ubicación no vacía, una fecha futura y una hora.

<a name="item2"></a>
## 🚀 Instalación

Sigue estos pasos para instalar y ejecutar Planify en tu máquina local:

1. Clona el repositorio:
   ```bash
   git clone https://github.com/usuario/planify.git

## 📌 Uso

1. Iniciar la aplicación
2. Crear evento.
3. Futuras implementaciones de Planify...

<a name="item4"></a>
## 🛠 Tecnologías Utilizadas

### Entorno de Desarrollo
![IntelliJ](https://img.shields.io/badge/IntelliJ-%23000000.svg?style=for-the-badge&logo=intellij-idea&logoColor=white)  
> **Descripción:** Usamos IntelliJ para el desarrollo del código fuente del proyecto, integrando herramientas para frontend y backend. Lo elegimos por su soporte nativo para Git, Docker y frameworks como Spring, optimizando nuestro flujo de trabajo.

### Frontend
![SceneBuilder](https://img.shields.io/badge/SceneBuilder-%230092CC.svg?style=for-the-badge&logo=java&logoColor=white) ![JavaFX](https://img.shields.io/badge/JavaFX-%23FF6200.svg?style=for-the-badge&logo=java&logoColor=white)  
> **Descripción:** SceneBuilder facilita la creación visual de interfaces gráficas (GUIs) para JavaFX mediante un enfoque drag-and-drop, generando automáticamente archivos FXML que definen la estructura de la interfaz.

### Backend
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-%236DB33F.svg?style=for-the-badge&logo=springboot&logoColor=white)  
> **Descripción:** Extensión de Spring Framework que simplifica la creación de proyectos Java con configuraciones predeterminadas, soporte para conexiones a bases de datos y compatibilidad con el modelo MVC empleado en el proyecto.

### Gestión de Dependencias
![Maven](https://img.shields.io/badge/Maven-%23C71A36.svg?style=for-the-badge&logo=apachemaven&logoColor=white)  
> **Descripción:** Utilizamos Maven por su facilidad para gestionar dependencias y desplegar proyectos Java, asegurando una construcción eficiente y reproducible.

### Base de Datos
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-%23336791.svg?style=for-the-badge&logo=postgresql&logoColor=white)  
> **Descripción:** Elegimos PostgreSQL para la gestión de la base de datos debido a su robustez y la experiencia previa del equipo con esta herramienta.  
> *Estructura de la base de datos (pendiente de actualización):*  
> `<img src="bd.png" alt="Estructura de la Base de Datos" width="800"/>`

### Contenerización
![Docker](https://img.shields.io/badge/Docker-%232496ED.svg?style=for-the-badge&logo=docker&logoColor=white)  
> **Descripción:** Docker nos permite empaquetar la aplicación y sus dependencias en contenedores aislados, garantizando que Planify se ejecute consistentemente en cualquier entorno, independientemente del sistema operativo o configuración.

A continuación, se muestra la estructura de la base de datos utilizada en el proyecto:

<img src="bd.png" alt="Estructura de la Base de Datos" width="800"/>

### Notificaciones
![WebSockets](https://img.shields.io/badge/websockets-%23009688.svg?style=for-the-badge&logo=websocket&logoColor=white)
### Mapas Interactivos
![Google Maps](https://img.shields.io/badge/Google%20Maps-%234285F4.svg?style=for-the-badge&logo=googlemaps&logoColor=white)

<a name="item5"></a>
## 🔎 Material externo

En esta sección hemos incluído enlaces a material externo sobre el que nos hemos apoyado para realizar algunas partes de la web ParkIT 🚘:

1. Users-card: hemos utilizado una [plantilla de Bootstrap](https://startbootstrap.com/theme/personal). Dicha plantilla se puede utilizar y modificar por presentar una licencia MIT.
2. Navbar: Hemos utilizado la documentación que ofrece [Bootstrap](https://getbootstrap.com/docs/5.3/components/navbar/).
3. Extension en VSCode: para el uso de Bootstrap y elementos preconstruidos, [Bootstrap 5 Quick Snippets](https://github.com/anburocky3/bootstrap5-snippets/tree/master)

<a name="item6"></a>
## 🤝 Contribución

1. Haz un fork del repositorio.
2. Crea una rama nueva (`git checkout -b feature-nueva`).
3. Realiza tus cambios y haz un commit (`git commit -m 'Agrega nueva funcionalidad'`).
4. Envía un pull request.
<a name="item7"></a>
## 👥 Contribuidores

Agradecemos a todas las personas que han contribuido a este proyecto:
- [Javier Aceituno Monja](https://github.com/jaceituno16)
- [Alex Guillermo Bonilla Taco](https://github.com/alexboni97)
- [Juan Pablo Fernández de la Torre](https://github.com/juanpf04)
- [Paula López Solla](https://github.com/Paula211)
- [Adrián Rodríguez Margallo](https://github.com/adrizz8)
- [Sergio Sánchez Carrasco](https://github.com/WalterDeRacagua) 

<a name="item8"></a>
## 📜 Licencia

Este proyecto está bajo la licencia [Apache License](LICENSE).
