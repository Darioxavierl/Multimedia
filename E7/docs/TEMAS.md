# Sistema de Temas

**Sistema de Streaming Adaptativo DASH**

## Índice

1. [Introducción](#introducción)
2. [Arquitectura del Sistema de Temas](#arquitectura-del-sistema-de-temas)
3. [Variables CSS Disponibles](#variables-css-disponibles)
4. [Temas Predefinidos](#temas-predefinidos)
5. [Uso del Sistema](#uso-del-sistema)
6. [Personalización de Temas](#personalización-de-temas)
7. [Creación de Nuevos Temas](#creación-de-nuevos-temas)

## Introducción

El sistema de temas permite personalizar completamente la apariencia de la interfaz mediante CSS Custom Properties (variables CSS). Esta arquitectura proporciona:

- Consistencia visual en toda la aplicación
- Cambio de tema en tiempo real sin reconstruir contenedores
- Fácil personalización y creación de nuevos temas
- Mantenibilidad mejorada del código CSS

## Arquitectura del Sistema de Temas

### Estructura de Archivos

```
www/html/css/
├── variables.css     # Definición de variables y temas
└── styles.css        # Estilos que usan las variables
```

### Separación de Responsabilidades

#### variables.css
- Define todas las variables CSS en el scope `:root`
- Contiene las definiciones de temas con el selector `[data-theme="nombre"]`
- No contiene estilos visuales directos

#### styles.css
- Importa `variables.css`
- Usa las variables definidas mediante `var(--nombre-variable)`
- Contiene toda la lógica de layout y estilos

### Flujo de Aplicación de Temas

1. HTML tiene atributo `data-theme` en el elemento `<html>`
2. CSS lee el valor de `data-theme`
3. Se aplican las variables correspondientes al tema seleccionado
4. Todos los elementos que usan esas variables se actualizan automáticamente

## Variables CSS Disponibles

### Colores Primarios

#### --color-primary
```css
--color-primary: #4A90E2;
```
**Uso**: Color principal de la aplicación
**Elementos afectados**:
- Botones de acción primaria
- Bordes activos
- Enlaces
- Iconos de estado

#### --color-primary-dark
```css
--color-primary-dark: #357ABD;
```
**Uso**: Variante oscura del color primario
**Elementos afectados**:
- Estados hover de botones primarios
- Sombras de elementos primarios

#### --color-primary-light
```css
--color-primary-light: rgba(74, 144, 226, 0.1);
```
**Uso**: Variante clara del color primario con transparencia
**Elementos afectados**:
- Fondos de botones secundarios
- Backgrounds de elementos destacados

### Colores de Fondo

#### --background-primary
```css
--background-primary: #1a1a1a;
```
**Uso**: Fondo principal de la aplicación
**Elementos afectados**:
- Body de la página
- Contenedor principal

#### --background-secondary
```css
--background-secondary: #2d2d2d;
```
**Uso**: Fondo de elementos secundarios
**Elementos afectados**:
- Tarjetas de contenido
- Paneles laterales
- Formularios

#### --background-tertiary
```css
--background-tertiary: #3a3a3a;
```
**Uso**: Fondo de elementos terciarios
**Elementos afectados**:
- Estados hover
- Elementos anidados
- Separadores

### Colores de Texto

#### --text-primary
```css
--text-primary: #ffffff;
```
**Uso**: Texto principal
**Elementos afectados**:
- Títulos
- Texto de contenido principal
- Etiquetas importantes

#### --text-secondary
```css
--text-secondary: #b0b0b0;
```
**Uso**: Texto secundario
**Elementos afectados**:
- Descripciones
- Texto de ayuda
- Subtítulos

#### --text-muted
```css
--text-muted: #808080;
```
**Uso**: Texto atenuado
**Elementos afectados**:
- Placeholders
- Texto deshabilitado
- Notas al pie

### Colores de Éxito

#### --success-color
```css
--success-color: #4CAF50;
```
**Uso**: Indicador de éxito
**Elementos afectados**:
- Botón de iniciar streaming
- Mensajes de éxito
- Iconos de confirmación

#### --success-hover
```css
--success-hover: #45a049;
```
**Uso**: Estado hover de elementos de éxito
**Elementos afectados**:
- Hover de botón de inicio

### Colores de Error

#### --error-color
```css
--error-color: #f44336;
```
**Uso**: Indicador de error
**Elementos afectados**:
- Botón de detener streaming
- Mensajes de error
- Iconos de alerta

#### --error-hover
```css
--error-hover: #da190b;
```
**Uso**: Estado hover de elementos de error
**Elementos afectados**:
- Hover de botón de detención

### Bordes y Separadores

#### --border-color
```css
--border-color: rgba(255, 255, 255, 0.1);
```
**Uso**: Bordes sutiles
**Elementos afectados**:
- Bordes de tarjetas
- Separadores
- Límites de secciones

#### --border-color-light
```css
--border-color-light: rgba(255, 255, 255, 0.05);
```
**Uso**: Bordes muy sutiles
**Elementos afectados**:
- Separadores internos
- Líneas divisorias menores

### Sombras

#### --shadow-sm
```css
--shadow-sm: 0 2px 4px rgba(0, 0, 0, 0.1);
```
**Uso**: Sombra pequeña
**Elementos afectados**:
- Botones
- Elementos flotantes pequeños

#### --shadow-md
```css
--shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
```
**Uso**: Sombra mediana
**Elementos afectados**:
- Tarjetas
- Modales

#### --shadow-lg
```css
--shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.2);
```
**Uso**: Sombra grande
**Elementos afectados**:
- Menús desplegables
- Elementos de alto nivel de elevación

### Gradientes

#### --gradient-background
```css
--gradient-background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
```
**Uso**: Fondo con gradiente para encabezados
**Elementos afectados**:
- Cabecera principal
- Secciones destacadas

### Espaciado

#### --spacing-xs
```css
--spacing-xs: 0.25rem; /* 4px */
```
**Uso**: Espaciado extra pequeño

#### --spacing-sm
```css
--spacing-sm: 0.5rem; /* 8px */
```
**Uso**: Espaciado pequeño

#### --spacing-md
```css
--spacing-md: 1rem; /* 16px */
```
**Uso**: Espaciado mediano (base)

#### --spacing-lg
```css
--spacing-lg: 1.5rem; /* 24px */
```
**Uso**: Espaciado grande

#### --spacing-xl
```css
--spacing-xl: 2rem; /* 32px */
```
**Uso**: Espaciado extra grande

### Bordes Redondeados

#### --border-radius-sm
```css
--border-radius-sm: 4px;
```
**Uso**: Radio pequeño
**Elementos afectados**:
- Botones pequeños
- Badges

#### --border-radius-md
```css
--border-radius-md: 8px;
```
**Uso**: Radio mediano
**Elementos afectados**:
- Botones
- Inputs
- Tarjetas

#### --border-radius-lg
```css
--border-radius-lg: 12px;
```
**Uso**: Radio grande
**Elementos afectados**:
- Contenedores principales
- Modales

### Transiciones

#### --transition-speed
```css
--transition-speed: 0.3s;
```
**Uso**: Duración de transiciones
**Elementos afectados**:
- Animaciones de hover
- Cambios de estado
- Transiciones de color

## Temas Predefinidos

### Tema Default (Púrpura)

**Selector**: `[data-theme="default"]` o sin atributo

**Características**:
- Esquema oscuro
- Gradiente púrpura en encabezado
- Color primario azul (#4A90E2)
- Ideal para uso general

**Paleta de colores**:
- Primario: #4A90E2 (Azul)
- Gradiente: #667eea → #764ba2 (Púrpura)
- Fondo: #1a1a1a (Negro oscuro)

**Código**:
```css
:root,
[data-theme="default"] {
  --color-primary: #4A90E2;
  --gradient-background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  /* ... resto de variables ... */
}
```

### Tema Green (Verde)

**Selector**: `[data-theme="green"]`

**Características**:
- Esquema oscuro
- Gradiente verde en encabezado
- Color primario verde (#10B981)
- Ideal para streaming de naturaleza o contenido ecológico

**Paleta de colores**:
- Primario: #10B981 (Verde esmeralda)
- Gradiente: #34d399 → #059669 (Verde claro → Verde oscuro)
- Fondo: #1a1a1a (Negro oscuro)

**Código**:
```css
[data-theme="green"] {
  --color-primary: #10B981;
  --color-primary-dark: #059669;
  --color-primary-light: rgba(16, 185, 129, 0.1);
  --gradient-background: linear-gradient(135deg, #34d399 0%, #059669 100%);
}
```

### Tema Red (Rojo)

**Selector**: `[data-theme="red"]`

**Características**:
- Esquema oscuro
- Gradiente rojo en encabezado
- Color primario rojo (#EF4444)
- Ideal para contenido urgente o alertas

**Paleta de colores**:
- Primario: #EF4444 (Rojo intenso)
- Gradiente: #f87171 → #dc2626 (Rojo claro → Rojo oscuro)
- Fondo: #1a1a1a (Negro oscuro)

**Código**:
```css
[data-theme="red"] {
  --color-primary: #EF4444;
  --color-primary-dark: #dc2626;
  --color-primary-light: rgba(239, 68, 68, 0.1);
  --gradient-background: linear-gradient(135deg, #f87171 0%, #dc2626 100%);
}
```

### Tema Dark (Oscuro Extremo)

**Selector**: `[data-theme="dark"]`

**Características**:
- Esquema muy oscuro
- Gradiente oscuro en encabezado
- Color primario azul claro (#60A5FA)
- Ideal para reducir fatiga visual, uso nocturno

**Paleta de colores**:
- Primario: #60A5FA (Azul claro)
- Gradiente: #1e293b → #0f172a (Gris oscuro → Negro azulado)
- Fondo: #0a0a0a (Negro profundo)

**Código**:
```css
[data-theme="dark"] {
  --color-primary: #60A5FA;
  --color-primary-dark: #3b82f6;
  --color-primary-light: rgba(96, 165, 250, 0.1);
  
  --background-primary: #0a0a0a;
  --background-secondary: #1a1a1a;
  --background-tertiary: #2a2a2a;
  
  --text-primary: #e0e0e0;
  --text-secondary: #a0a0a0;
  --text-muted: #707070;
  
  --gradient-background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
}
```

## Uso del Sistema

### Cambio Manual en HTML

Editar el archivo `www/html/index.html`:

```html
<!-- Tema default (predeterminado) -->
<html lang="es">

<!-- Tema green -->
<html lang="es" data-theme="green">

<!-- Tema red -->
<html lang="es" data-theme="red">

<!-- Tema dark -->
<html lang="es" data-theme="dark">
```

Recargar página con `Ctrl+F5` para ver cambios.

### Cambio con Script

Usar el script proporcionado:

```bash
# Ver temas disponibles
./change-theme.sh

# Aplicar tema específico
./change-theme.sh green
./change-theme.sh red
./change-theme.sh dark
./change-theme.sh default
```

**Nota**: El script modifica automáticamente el archivo HTML.

### Cambio Dinámico con JavaScript

Agregar un selector de temas en la interfaz:

```javascript
// Cambiar tema dinámicamente
document.documentElement.setAttribute('data-theme', 'green');

// Ejemplo de selector de temas
const themeSelect = document.createElement('select');
themeSelect.innerHTML = `
  <option value="default">Default (Púrpura)</option>
  <option value="green">Verde</option>
  <option value="red">Rojo</option>
  <option value="dark">Oscuro</option>
`;

themeSelect.addEventListener('change', (e) => {
  document.documentElement.setAttribute('data-theme', e.target.value);
  localStorage.setItem('theme', e.target.value);
});

// Cargar tema guardado
const savedTheme = localStorage.getItem('theme');
if (savedTheme) {
  document.documentElement.setAttribute('data-theme', savedTheme);
  themeSelect.value = savedTheme;
}
```

## Personalización de Temas

### Modificar Tema Existente

1. Abrir `www/html/css/variables.css`
2. Localizar el selector del tema a modificar
3. Cambiar los valores de las variables

**Ejemplo**: Cambiar el color primario del tema verde

```css
[data-theme="green"] {
  --color-primary: #22c55e;  /* Verde más brillante */
  --color-primary-dark: #16a34a;
  /* ... */
}
```

4. Guardar archivo
5. Recargar página con `Ctrl+F5`

**Nota**: No requiere reconstruir contenedores

### Ajustar Solo Espaciado

Las variables de espaciado son globales. Para cambiarlas:

```css
:root {
  --spacing-md: 1.2rem;  /* Aumentar espaciado base */
  --spacing-lg: 1.8rem;  /* Aumentar espaciado grande */
}
```

Esto afecta todos los temas por igual.

### Ajustar Solo Sombras

```css
:root {
  --shadow-md: 0 6px 12px rgba(0, 0, 0, 0.15);  /* Sombra más pronunciada */
}
```

### Ajustar Velocidad de Transiciones

```css
:root {
  --transition-speed: 0.2s;  /* Transiciones más rápidas */
}
```

## Creación de Nuevos Temas

### Proceso Paso a Paso

#### 1. Definir Paleta de Colores

Elegir:
- Color primario principal
- Color primario oscuro (para hover)
- Color primario claro (para backgrounds)
- Colores de fondo (primario, secundario, terciario)
- Colores de texto (primario, secundario, muted)
- Gradiente para encabezado

**Herramientas útiles**:
- Coolors.co: Generador de paletas
- Adobe Color: Rueda de color
- ColorHunt: Inspiración de paletas

#### 2. Agregar Selector CSS

Editar `www/html/css/variables.css`:

```css
[data-theme="mi-tema"] {
  /* Color primario */
  --color-primary: #tu-color-hex;
  --color-primary-dark: #variante-oscura;
  --color-primary-light: rgba(r, g, b, 0.1);
  
  /* Fondos (opcional, hereda de :root si no se especifica) */
  --background-primary: #fondo-principal;
  --background-secondary: #fondo-secundario;
  --background-tertiary: #fondo-terciario;
  
  /* Textos (opcional) */
  --text-primary: #texto-principal;
  --text-secondary: #texto-secundario;
  --text-muted: #texto-atenuado;
  
  /* Gradiente */
  --gradient-background: linear-gradient(135deg, #color1 0%, #color2 100%);
}
```

#### 3. Modificar Script de Cambio de Tema

Editar `change-theme.sh`:

```bash
# Agregar a la lista de temas válidos
if [[ "$1" != "default" && "$1" != "green" && "$1" != "red" && "$1" != "dark" && "$1" != "mi-tema" ]]; then
  echo "Tema no válido. Opciones: default, green, red, dark, mi-tema"
  exit 1
fi
```

#### 4. Probar Nuevo Tema

```bash
# Aplicar nuevo tema
./change-theme.sh mi-tema

# Recargar página
# Ctrl+F5 en navegador
```

#### 5. Ajustar Variables Según Necesidad

Iterar sobre las variables hasta lograr el look deseado.

### Ejemplo Completo: Tema Azul Océano

```css
[data-theme="ocean"] {
  /* Colores primarios */
  --color-primary: #0ea5e9;  /* Azul cielo */
  --color-primary-dark: #0284c7;
  --color-primary-light: rgba(14, 165, 233, 0.1);
  
  /* Fondos oscuros con tinte azul */
  --background-primary: #0c1821;
  --background-secondary: #1a2332;
  --background-tertiary: #2d3e50;
  
  /* Textos con tinte azul claro */
  --text-primary: #e0f2fe;
  --text-secondary: #bae6fd;
  --text-muted: #7dd3fc;
  
  /* Gradiente océano */
  --gradient-background: linear-gradient(135deg, #0891b2 0%, #164e63 100%);
}
```

### Ejemplo Completo: Tema Claro

```css
[data-theme="light"] {
  /* Colores primarios */
  --color-primary: #2563eb;  /* Azul */
  --color-primary-dark: #1d4ed8;
  --color-primary-light: rgba(37, 99, 235, 0.1);
  
  /* Fondos claros */
  --background-primary: #ffffff;
  --background-secondary: #f3f4f6;
  --background-tertiary: #e5e7eb;
  
  /* Textos oscuros */
  --text-primary: #111827;
  --text-secondary: #4b5563;
  --text-muted: #9ca3af;
  
  /* Bordes más oscuros */
  --border-color: rgba(0, 0, 0, 0.1);
  --border-color-light: rgba(0, 0, 0, 0.05);
  
  /* Sombras más suaves */
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.07);
  --shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);
  
  /* Gradiente claro */
  --gradient-background: linear-gradient(135deg, #60a5fa 0%, #3b82f6 100%);
  
  /* Colores de éxito/error ajustados para fondo claro */
  --success-color: #16a34a;
  --success-hover: #15803d;
  --error-color: #dc2626;
  --error-hover: #b91c1c;
}
```

### Mejores Prácticas

1. **Consistencia**: Mantener coherencia en la saturación y brillo de colores
2. **Contraste**: Asegurar suficiente contraste entre texto y fondo (WCAG AA: 4.5:1)
3. **Pruebas**: Probar en diferentes dispositivos y tamaños de pantalla
4. **Documentación**: Documentar el propósito y uso de cada tema
5. **Gradientes**: Usar colores relacionados para gradientes armoniosos
6. **Variables Opcionales**: No es necesario redefinir todas las variables, solo las que cambian

### Herramientas de Validación

#### Contraste de Color
```bash
# Online: https://webaim.org/resources/contrastchecker/
# Verificar contraste entre texto y fondo
```

#### Visualización de Temas
```javascript
// En consola del navegador, probar todos los temas:
const themes = ['default', 'green', 'red', 'dark'];
let i = 0;
setInterval(() => {
  document.documentElement.setAttribute('data-theme', themes[i]);
  console.log('Tema actual:', themes[i]);
  i = (i + 1) % themes.length;
}, 3000);
```

## Integración con UI

### Selector de Temas en Interfaz

Agregar a `www/html/index.html`:

```html
<div class="theme-selector">
  <label for="theme-select">Tema:</label>
  <select id="theme-select">
    <option value="default">Default</option>
    <option value="green">Verde</option>
    <option value="red">Rojo</option>
    <option value="dark">Oscuro</option>
  </select>
</div>
```

Agregar a `www/html/js/ui-controller.js`:

```javascript
// Inicializar selector de temas
const themeSelect = document.getElementById('theme-select');
const savedTheme = localStorage.getItem('selected-theme') || 'default';

document.documentElement.setAttribute('data-theme', savedTheme);
themeSelect.value = savedTheme;

themeSelect.addEventListener('change', (e) => {
  const theme = e.target.value;
  document.documentElement.setAttribute('data-theme', theme);
  localStorage.setItem('selected-theme', theme);
});
```

Estilos para el selector en `www/html/css/styles.css`:

```css
.theme-selector {
  position: absolute;
  top: var(--spacing-md);
  right: var(--spacing-md);
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
}

.theme-selector label {
  color: var(--text-primary);
  font-size: 0.9rem;
}

.theme-selector select {
  background: var(--background-secondary);
  color: var(--text-primary);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius-sm);
  padding: var(--spacing-xs) var(--spacing-sm);
  cursor: pointer;
  transition: all var(--transition-speed);
}

.theme-selector select:hover {
  border-color: var(--color-primary);
}

.theme-selector select:focus {
  outline: none;
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px var(--color-primary-light);
}
```

## Troubleshooting

### Tema no se aplica

**Síntomas**: Los cambios en variables.css no se reflejan

**Soluciones**:
1. Vaciar caché del navegador (Ctrl+Shift+Del)
2. Forzar recarga (Ctrl+F5)
3. Verificar que no hay errores de sintaxis CSS (F12 → Console)
4. Verificar que el atributo `data-theme` está correctamente establecido

### Colores incorrectos

**Síntomas**: Algunos elementos no usan los colores del tema

**Soluciones**:
1. Verificar que styles.css usa `var(--nombre-variable)` en lugar de colores hardcodeados
2. Buscar en styles.css por valores hexadecimales (#) que deberían ser variables
3. Asegurarse de que variables.css se importa antes de styles.css

```css
/* Incorrecto */
.button {
  background: #4A90E2;
}

/* Correcto */
.button {
  background: var(--color-primary);
}
```

### Transiciones no funcionan

**Síntomas**: Los cambios de color son bruscos, sin transiciones

**Soluciones**:
1. Verificar que los elementos tienen la propiedad `transition`
2. Comprobar que se usa `var(--transition-speed)`

```css
.button {
  background: var(--color-primary);
  transition: all var(--transition-speed);
}
```

### Tema oscuro/claro difícil de leer

**Síntomas**: Contraste insuficiente entre texto y fondo

**Soluciones**:
1. Verificar contraste con herramientas online
2. Ajustar `--text-primary` y `--background-primary`
3. Asegurar ratio de contraste mínimo de 4.5:1 (WCAG AA)

```css
/* Mal contraste */
[data-theme="light"] {
  --text-primary: #cccccc;  /* Gris claro */
  --background-primary: #ffffff;  /* Blanco */
  /* Contraste: 1.6:1 - MALO */
}

/* Buen contraste */
[data-theme="light"] {
  --text-primary: #1f2937;  /* Gris muy oscuro */
  --background-primary: #ffffff;  /* Blanco */
  /* Contraste: 16.3:1 - EXCELENTE */
}
```

## Referencias

### Documentación CSS

- CSS Custom Properties: https://developer.mozilla.org/en-US/docs/Web/CSS/--*
- CSS Variables: https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties
- Data Attributes: https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/data-*

### Herramientas de Diseño

- Coolors: https://coolors.co/ (Generador de paletas)
- Adobe Color: https://color.adobe.com/ (Rueda de color)
- Color Hunt: https://colorhunt.co/ (Inspiración de paletas)
- WebAIM Contrast Checker: https://webaim.org/resources/contrastchecker/ (Validación de contraste)

### Accesibilidad

- WCAG 2.1: https://www.w3.org/WAI/WCAG21/quickref/
- Contrast Guidelines: https://webaim.org/articles/contrast/

---

**Autor**: Dario Portilla  
**Universidad de Cuenca**  
**Última actualización**: Enero 2026
