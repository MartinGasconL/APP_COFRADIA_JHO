package es.cofradia.repertorio.media;

import es.cofradia.repertorio.song.SongTrack;
import es.cofradia.repertorio.song.SongTrackRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
import org.springframework.transaction.support.TransactionTemplate;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.Set;

@Service
public class AudioProcessingService {

    private static final Logger log = LoggerFactory.getLogger(AudioProcessingService.class);

    /** Contenedores de vídeo: sin FFmpeg no hay forma de extraer el audio. */
    static final Set<String> VIDEO_CONTAINERS = Set.of("mp4", "mov", "mkv", "m4v", "avi", "3gp");

    private static final Map<String, String> CONTENT_TYPES = Map.of(
            "mp3", "audio/mpeg", "wav", "audio/wav", "ogg", "audio/ogg", "oga", "audio/ogg",
            "opus", "audio/opus", "webm", "audio/webm", "m4a", "audio/mp4", "aac", "audio/aac",
            "flac", "audio/flac");

    private final MediaStorage storage;
    private final Ffmpeg ffmpeg;
    private final SongTrackRepository tracks;
    private final TransactionTemplate tx;

    public AudioProcessingService(MediaStorage storage, Ffmpeg ffmpeg, SongTrackRepository tracks,
                                  PlatformTransactionManager txManager) {
        this.storage = storage;
        this.ffmpeg = ffmpeg;
        this.tracks = tracks;
        this.tx = new TransactionTemplate(txManager);
    }

    @Async("audioExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onUpload(TrackUploadedEvent event) {
        process(event);
    }

    void process(TrackUploadedEvent event) {
        String ext = event.extension();
        String rawKey = event.rawKey();
        try {
            if (ext.equals("mp3")) {
                Integer duration = ffmpeg.probeDurationSeconds(storage.resolve(rawKey)).orElse(null);
                finish(event.trackId(), "READY", rawKey, "audio/mpeg", size(rawKey), duration);
            } else if (ffmpeg.available()) {
                String mp3Key = rawKey.replaceAll("\\.[^.]+$", "") + ".mp3";
                ffmpeg.toMp3(storage.resolve(rawKey), storage.resolve(mp3Key));
                storage.deleteQuietly(rawKey);
                Integer duration = ffmpeg.probeDurationSeconds(storage.resolve(mp3Key)).orElse(null);
                finish(event.trackId(), "READY", mp3Key, "audio/mpeg", size(mp3Key), duration);
            } else if (VIDEO_CONTAINERS.contains(ext)) {
                finish(event.trackId(), "FAILED", null, null, null, null,
                        "No se pudo convertir el vídeo: FFmpeg no está instalado en el servidor");
            } else {
                // Formato de audio ya reproducible por el navegador: se conserva tal cual.
                finish(event.trackId(), "READY", rawKey,
                        CONTENT_TYPES.getOrDefault(ext, "application/octet-stream"), size(rawKey), null);
            }
        } catch (Exception e) {
            log.warn("Fallo procesando la pista {}: {}", event.trackId(), e.toString());
            finish(event.trackId(), "FAILED", null, null, null, null, e.getMessage());
        } finally {
            String previous = event.previousKey();
            if (previous != null && !previous.equals(rawKey)) {
                storage.deleteQuietly(previous);
            }
        }
    }

    private void finish(Long trackId, String status, String path, String contentType, Long size, Integer duration) {
        finish(trackId, status, path, contentType, size, duration, null);
    }

    private void finish(Long trackId, String status, String path, String contentType, Long size,
                        Integer duration, String error) {
        tx.executeWithoutResult(s -> tracks.findById(trackId).ifPresent(track -> {
            track.setMediaStatus(status);
            if (path != null) track.setMediaPath(path);
            if (contentType != null) track.setContentType(contentType);
            if (size != null) track.setSizeBytes(size);
            track.setDurationSeconds(duration);
        }));
        if (error != null) {
            log.info("Pista {} marcada como {}: {}", trackId, status, error);
        }
    }

    private Long size(String key) {
        try {
            Path p = storage.resolve(key);
            return Files.exists(p) ? Files.size(p) : null;
        } catch (Exception e) {
            return null;
        }
    }
}
