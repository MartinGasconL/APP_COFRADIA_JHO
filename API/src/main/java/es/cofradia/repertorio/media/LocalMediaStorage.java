package es.cofradia.repertorio.media;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.*;

@Component
public class LocalMediaStorage implements MediaStorage {

    private final Path root;

    public LocalMediaStorage(@Value("${cofradia.media-dir}") String dir) {
        this.root = Path.of(dir).toAbsolutePath().normalize();
    }

    @Override
    public String store(String key, InputStream data) throws IOException {
        Path target = safeResolve(key);
        Files.createDirectories(target.getParent());
        try (InputStream in = data) {
            Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
        }
        return key;
    }

    @Override
    public Path resolve(String relativePath) {
        return safeResolve(relativePath);
    }

    @Override
    public void deleteQuietly(String relativePath) {
        try {
            Files.deleteIfExists(safeResolve(relativePath));
        } catch (IOException ignored) {
            // best-effort
        }
    }

    @Override
    public boolean exists(String relativePath) {
        return Files.exists(safeResolve(relativePath));
    }

    private Path safeResolve(String relativePath) {
        Path resolved = root.resolve(relativePath).normalize();
        if (!resolved.startsWith(root)) {
            throw new IllegalArgumentException("Ruta de medios no permitida");
        }
        return resolved;
    }
}
