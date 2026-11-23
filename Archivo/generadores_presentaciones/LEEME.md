# Generadores de las presentaciones y del documento de lecciones

Scripts de Node (pptxgenjs y docx). Se corren desde esta carpeta con `NODE_PATH` apuntando a un `node_modules`
que tenga `pptxgenjs` y `docx` (`npm install pptxgenjs docx`). Rutas absolutas de la skill pptx dentro de los scripts: ajustar si cambian.

- `presentacion_5min.js SALIDA.pptx`: 7 diapositivas para exponer en 5 minutos (usa `p_*.png` y `portada.png`).
- `presentacion_ejecutiva.js SALIDA.pptx VIDEO.mp4 [encuesta.json]`: 2 diapositivas. Sin `encuesta.json` muestra "pendiente de captura".
  Formato de `encuesta.json`: `{"escalaMax": 5, "nota": "Respondió: ...", "preguntas": [{"texto": "...", "calificacion": 4.5}]}`.
- `lecciones_aprendidas.js SALIDA.docx`: documento de hallazgos y lecciones aprendidas.
- `poster.png`: portada del video dentro de la presentación ejecutiva.

- `presentacion_completa.js SALIDA.pptx VIDEO.mp4 encuesta_resultados.json`: presentación ejecutiva completa de 17 diapositivas (fases 1 a 4, justificaciones de cambios, video, satisfacción y lecciones; usa `i1..i4.png`, `p_*.png`).
