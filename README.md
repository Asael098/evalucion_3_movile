📦 Paquexpress - Sistema de Logística y Entregas

Paquexpress es una solución integral para la gestión de entregas de última milla. Consta de una aplicación móvil/web para repartidores y un backend robusto para la administración de paquetes, permitiendo el rastreo en tiempo real mediante GPS y evidencia fotográfica.

🚀 Características Principales

Roles de Usuario: Sistema seguro con roles diferenciados (Administrador y Trabajador).

Gestión de Paquetes (CRUD): El administrador puede crear, asignar, modificar y eliminar paquetes.

Gestión de Empleados: Registro y administración de repartidores.

Prueba de Entrega (PoD): Captura obligatoria de evidencia fotográfica usando la cámara del dispositivo.

Geolocalización:

Captura de coordenadas GPS de alta precisión.

Geocodificación Inversa: Conversión automática de coordenadas a dirección física (Calle, Número, Ciudad) mediante API de Nominatim.

Mapa Interactivo: Visualización de la ubicación actual en la App (OpenStreetMap).

Multiplataforma: Funciona en Android, iOS y Web.

🛠️ Tecnologías Utilizadas

Backend (API)

Lenguaje: Python 3.10+

Framework: FastAPI

Base de Datos: MySQL

ORM: SQLAlchemy

Servidor: Uvicorn

Frontend (App Móvil/Web)

Framework: Flutter (Dart)

Librerías Clave:

http: Conexión con API REST.

geolocator: Obtención de coordenadas GPS.

image_picker: Uso de cámara nativa.

flutter_map & latlong2: Mapas interactivos OpenSource.

📋 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

Git

Python 3.x

Flutter SDK

[enlace sospechoso eliminado] (XAMPP o Workbench recomendado).

⚙️ Instrucciones de Instalación

1. Clonar el Repositorio

git clone [https://github.com/tu-usuario/paquexpress.git](https://github.com/tu-usuario/paquexpress.git)
cd paquexpress


2. Configurar Base de Datos (MySQL)

Abre tu gestor de base de datos (phpMyAdmin, Workbench, DBeaver).

Crea una nueva base de datos llamada db_paquexpress.

Ejecuta el script SQL proporcionado en database/script.sql (o copia la estructura de las tablas P9_users, P9_packages, P9_deliveries).

3. Configurar y Ejecutar Backend

Navega a la carpeta del servidor:

cd backend


Crea un entorno virtual (opcional pero recomendado):

python -m venv venv
# Windows:
venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate


Instala las dependencias:

pip install fastapi uvicorn sqlalchemy mysql-connector-python pydantic python-multipart requests


Importante: Abre main.py y verifica la variable DATABASE_URL. Asegúrate de que coincida con tu usuario y contraseña de MySQL:

# Ejemplo: usuario 'root', sin contraseña
DATABASE_URL = "mysql+mysqlconnector://root:@localhost:3306/db_paquexpress"


Inicia el servidor:

uvicorn main:app --reload --host 0.0.0.0


La API estará corriendo en http://localhost:8000

4. Configurar y Ejecutar Frontend (Flutter)

Navega a la carpeta de la aplicación:

cd frontend_app


Instala las dependencias de Flutter:

flutter pub get


Configuración de IP (Crítico):

Abre el archivo lib/config.dart.

Cambia la variable baseUrl dependiendo de dónde ejecutarás la App:

// Si usas Emulador de Android:
const String baseUrl = "[http://10.0.2.2:8000](http://10.0.2.2:8000)";

// Si usas Celular Físico o Web (Usa la IP local de tu PC):
// Ejecuta 'ipconfig' (Windows) o 'ifconfig' (Mac/Linux) para ver tu IP.
const String baseUrl = "[http://192.168.1.](http://192.168.1.)XX:8000"; 


Ejecuta la aplicación:

flutter run


📖 Guía de Uso

Credenciales por Defecto

El script de base de datos incluye usuarios de prueba:

Rol

Usuario

Contraseña

Administrador

admin

admin123

Trabajador

agente1

paquexpress123

Flujo Administrativo

Inicia sesión como Admin.

En el menú lateral, ve a "Gestionar Empleados" para dar de alta nuevos repartidores.

En la pantalla principal, asigna paquetes seleccionando al repartidor y escribiendo la dirección.

Puedes borrar paquetes o empleados si es necesario.

Flujo de Trabajador

Inicia sesión con cuenta de Trabajador.

Verás la lista de tus paquetes pendientes.

Selecciona un paquete para ver el detalle y mapa.

Toma una foto (obligatoria) y espera a que el GPS detecte tu ubicación.

Presiona "Confirmar Entrega". El servidor validará la dirección y guardará la evidencia.

📱 Capturas de Pantalla

Login

Panel Admin

Mapa y Entrega







📄 Licencia

Este proyecto es de uso académico/educativo.
