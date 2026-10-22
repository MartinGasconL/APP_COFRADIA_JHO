package es.cofradia.repertorio.media;

/**
 * Se publica tras confirmar en BD la subida de una pista.
 * El procesamiento (conversión a MP3 + lectura de duración) ocurre de forma asíncrona.
 *
 * @param trackId      pista recién guardada
 * @param rawKey       ruta relativa del fichero tal cual se subió
 * @param extension    extensión en minúsculas sin punto (p. ej. {@code mp4})
 * @param previousKey  ruta del fichero de la versión anterior a limpiar, o null
 */
public record TrackUploadedEvent(Long trackId, String rawKey, String extension, String previousKey) {}
