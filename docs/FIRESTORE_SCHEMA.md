# Esquema Firestore - UPTP Control

## Colecciones

### users/{uid}
```
nombre: string
email: string
rol: string          → "admin" (único rol en esta versión)
activo: boolean
created_at: timestamp
```

### secciones/{seccionId}
```
nombre: string       → "1er Año Sección A"
codigo: string       → "1A"
turno: string        → "Mañana" | "Tarde" | "Noche"
anio_escolar: number → 2026
activo: boolean
created_at: timestamp
```

### materias/{materiaId}
```
nombre: string          → "Matemáticas"
codigo: string          → "MAT"
descripcion: string?
horas_semanales: number → 4
activo: boolean
created_at: timestamp
```

### seccion_materias/{id}
Relación muchos a muchos entre secciones y materias.
Cada sección puede tener distintas materias.
```
seccion_id: string
seccion_nombre: string      ⚡ desnormalizado
materia_id: string
materia_nombre: string      ⚡ desnormalizado
aula: string?
horario: string?
```

### estudiantes/{estudianteId}
```
cedula: string
nombre: string
apellido: string
email: string?
telefono: string?
fecha_nacimiento: timestamp?
activo: boolean
created_at: timestamp
```

### inscripciones/{inscripcionId}
Vincula un estudiante con una sección.
```
estudiante_id: string
estudiante_nombre: string   ⚡ desnormalizado
seccion_id: string
seccion_nombre: string      ⚡ desnormalizado
anio_escolar: number
estatus: string             → "activo" | "retirado"
fecha_inscripcion: timestamp
```

### evaluaciones/{evaluacionId}
Pertenece a una seccion_materia. La suma de ponderaciones no debe exceder 100%.
```
seccion_materia_id: string
materia_nombre: string      ⚡ desnormalizado
seccion_nombre: string      ⚡ desnormalizado
nombre: string              → "Parcial 1"
tipo: string                → "Examen" | "Tarea" | "Quiz" | "Proyecto" | "Participación"
ponderacion: number         → 25 (porcentaje)
fecha: timestamp?
activo: boolean
created_at: timestamp
```

### notas/{notaId}
Calificación de un estudiante en una evaluación específica.
```
evaluacion_id: string
evaluacion_nombre: string   ⚡ desnormalizado
estudiante_id: string
estudiante_nombre: string   ⚡ desnormalizado
materia_nombre: string      ⚡ desnormalizado
seccion_id: string
calificacion: number        → 0 a 20
observacion: string?
created_at: timestamp
updated_at: timestamp
```

## Índices Compuestos Requeridos

1. `notas` → estudiante_id (ASC) + created_at (DESC)
2. `evaluaciones` → seccion_materia_id (ASC) + activo (ASC) + fecha (DESC)
3. `inscripciones` → seccion_id (ASC) + estatus (ASC)
4. `notas` → evaluacion_id (ASC)

## Relaciones
```
Sección ──1:N──→ seccion_materias ←──N:1── Materia
Sección ──1:N──→ inscripciones ←──N:1── Estudiante
seccion_materia ──1:N──→ evaluaciones
evaluacion ──1:N──→ notas ←──N:1── Estudiante
```

## Notas sobre desnormalización
Los campos marcados con ⚡ son copias de datos para evitar lecturas adicionales en Firestore.
Si se actualiza el nombre de una sección/materia/estudiante, hay que actualizar los documentos relacionados.
