package es.cofradia.repertorio.media;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Path;

/**
 * Abstracción del almacenamiento de ficheros de audio.
 * La implementación actual guarda en disco local; en fase 2 se puede sustituir
 * por MinIO/S3 sin tocar el resto del código.
 */
public interface MediaStorage {

    /**
     * Guarda un stream y devuelve la ruta relativa con la que quedará referenciado en BD.
     * @param key ruta relativa deseada (p. ej. {@code songs/12/tambor-v1.mp3})
     */
    String store(String key, InputStream data) throws IOException;

    /** Resuelve una ruta relativa a una ruta absoluta del sistema de ficheros. */
    Path resolve(String relativePath);

    /** Borra el fichero; no falla si no existe. */
    void deleteQuietly(String relativePath);

    boolean exists(String relativePath);
}
