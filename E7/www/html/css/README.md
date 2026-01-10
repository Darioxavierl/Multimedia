# 🎨 Sistema de Variables CSS

## 📁 Estructura

```
www/html/css/
├── variables.css  → Variables de color, espaciado, sombras, etc.
└── styles.css     → Estilos que usan las variables
```

## 🎯 Uso de Variables

Todas las variables están definidas en `variables.css` y se usan en `styles.css`.

### Variables Principales

#### 🎨 Colores Primarios
```css
--color-primary: #667eea;       /* Azul principal */
--color-primary-dark: #764ba2;  /* Azul oscuro */
--color-primary-light: #8b9dff; /* Azul claro */
```

#### 🎨 Colores Secundarios
```css
--color-secondary: #f093fb;     /* Rosa */
--color-secondary-dark: #f5576c; /* Rosa oscuro */
```

#### 📄 Fondos
```css
--bg-main: #ffffff;        /* Fondo principal (blanco) */
--bg-container: #f8f9fa;   /* Fondo de contenedores */
--bg-dark: #000000;        /* Fondo oscuro (video) */
```

#### 📝 Textos
```css
--text-primary: #333333;   /* Texto principal */
--text-secondary: #555555; /* Texto secundario */
--text-light: #ffffff;     /* Texto claro (botones) */
```

#### ✅ Estados
```css
--color-success: #2e7d32;      /* Verde éxito */
--color-error: #c33333;        /* Rojo error */
--color-info: #1976d2;         /* Azul información */
```

## 🔄 Cambiar Esquema de Colores

### Opción 1: Editar variables.css directamente

Edita `www/html/css/variables.css` en la sección `:root`:

```css
:root {
    --color-primary: #TU_COLOR;
    --color-primary-dark: #TU_COLOR_OSCURO;
    /* ... */
}
```

### Opción 2: Usar un tema predefinido

En el `<body>` del HTML, agrega `data-theme`:

```html
<!-- Tema por defecto (morado/azul) -->
<body>

<!-- Tema verde -->
<body data-theme="green">

<!-- Tema rojo -->
<body data-theme="red">

<!-- Modo oscuro -->
<body data-theme="dark">
```

## 🎨 Temas Disponibles

### 1. Tema por Defecto (Morado/Azul)
- Color principal: `#667eea` (Azul)
- Color secundario: `#f093fb` (Rosa)
- **Actual**

### 2. Tema Verde
```html
<body data-theme="green">
```
- Color principal: `#4caf50` (Verde)
- Color secundario: `#66bb6a` (Verde claro)

### 3. Tema Rojo
```html
<body data-theme="red">
```
- Color principal: `#f44336` (Rojo)
- Color secundario: `#ff6f60` (Rojo claro)

### 4. Modo Oscuro
```html
<body data-theme="dark">
```
- Fondo oscuro
- Textos claros
- Colores ajustados para contraste

## ✏️ Crear Tu Propio Tema

1. Abre `www/html/css/variables.css`

2. Agrega un nuevo bloque al final:

```css
[data-theme="mi-tema"] {
    --color-primary: #FF5733;
    --color-primary-dark: #C70039;
    --color-primary-light: #FF8C66;
    
    --color-secondary: #FFC300;
    --color-secondary-dark: #DAA520;
    
    --gradient-primary: linear-gradient(135deg, #FF5733 0%, #C70039 100%);
    --gradient-background: linear-gradient(135deg, #FF5733 0%, #900C3F 100%);
    
    --shadow-md: 0 4px 15px rgba(255, 87, 51, 0.4);
    --shadow-lg: 0 6px 20px rgba(255, 87, 51, 0.6);
}
```

3. Usa en HTML:
```html
<body data-theme="mi-tema">
```

## 🎯 Variables de Espaciado

```css
--spacing-xs: 8px;   /* Extra pequeño */
--spacing-sm: 12px;  /* Pequeño */
--spacing-md: 15px;  /* Mediano */
--spacing-lg: 20px;  /* Grande */
--spacing-xl: 30px;  /* Extra grande */
```

## 🎯 Variables de Bordes

```css
--border-radius-sm: 5px;   /* Bordes pequeños */
--border-radius-md: 10px;  /* Bordes medianos */
--border-radius-lg: 15px;  /* Bordes grandes */
--border-radius-xl: 25px;  /* Bordes extra grandes (botones) */
```

## 🎯 Variables de Sombras

```css
--shadow-sm: 0 2px 4px rgba(0, 0, 0, 0.1);
--shadow-md: 0 4px 15px rgba(102, 126, 234, 0.4);
--shadow-lg: 0 6px 20px rgba(102, 126, 234, 0.6);
--shadow-xl: 0 20px 60px rgba(0, 0, 0, 0.3);
```

## 📝 Ejemplos de Cambios Rápidos

### Cambiar color de botones:
```css
/* En variables.css */
--color-primary: #e91e63;        /* Rosa fucsia */
--color-primary-dark: #c2185b;   /* Rosa oscuro */
```

### Cambiar fondo de la página:
```css
/* En variables.css */
--gradient-background: linear-gradient(135deg, #00b4db 0%, #0083b0 100%);
```

### Cambiar espaciado general:
```css
/* En variables.css */
--spacing-lg: 30px;  /* Aumentar espacio entre elementos */
--spacing-xl: 50px;  /* Más padding en contenedor */
```

## 🔄 Aplicar Cambios

1. **Edita** `www/html/css/variables.css`
2. **Guarda** el archivo
3. **Recarga** la página (Ctrl+F5)
4. ✅ **Listo!** Los cambios se aplican inmediatamente

No necesitas reconstruir contenedores ni ejecutar scripts. Solo recargar la página.

## 💡 Tips

- **Mantén consistencia**: Usa las variables en lugar de valores hardcoded
- **Usa temas**: Crea temas para diferentes contextos
- **Documenta cambios**: Si agregas variables nuevas, actualiza esta guía
- **Prueba contrastes**: Asegúrate de que los colores sean legibles

## 🎨 Generadores de Paletas Útiles

- [Coolors](https://coolors.co/) - Generador de paletas
- [Adobe Color](https://color.adobe.com/) - Rueda de colores
- [Material Design Colors](https://materialui.co/colors) - Colores Material
