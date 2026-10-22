package es.cofradia.repertorio.media;

import es.cofradia.repertorio.song.*;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Locale;
import java.util.Objects;
import java.util.Set;

import static org.springframework.http.HttpStatus.*;

@Service
public class MediaService {

    /** Extensiones admitidas: audio reproducible + contenedores de vídeo (se convierten). */
    private static final Set<String> ALLOWED = Set.of(
            "mp3", "wav", "ogg", "oga", "opus", "webm", "m4a", "aac", "flac",
            "mp4", "mov", "mkv", "m4v", "avi", "3gp");

    private final SongService songs;
    private final SongTrackRepository tracks;
    private final MediaStorage storage;
    private final ApplicationEventPublisher events;

    public MediaService(SongService songs, SongTrackRepository tracks, MediaStorage storage,
                        ApplicationEventPublisher events) {
        this.songs = songs;
        this.tracks = tracks;
        this.storage = storage;
        this.events = events;
    }

    @Transactional
    public SongDto.TrackResponse upload(Long songId, TrackType type, MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(BAD_REQUEST, "El fichero está vacío");
        }
        String original = Objects.requireNonNullElse(file.getOriginalFilename(), "pista").trim();
        String ext = extension(original);
        if (!ALLOWED.contains(ext)) {
            throw new ResponseStatusException(UNSUPPORTED_MEDIA_TYPE,
                    "Formato no admitido (." + ext + "). Usa MP3, WAV, OGG, M4A o MP4.");
        }

        Song song = songs.find(songId);
        SongTrack track = tracks.findBySongIdAndType(songId, type).orElse(null);
        int version = track != null ? track.getMediaVersion() + 1 : 1;
        String previousKey = track != null ? track.getMediaPath() : null;

        String rawKey = "songs/%d/%s-v%d.%s".formatted(songId, type.name().toLowerCase(Locale.ROOT), version, ext);
        storage.store(rawKey, file.getInputStream());

        if (track == null) {
            track = new SongTrack(song, type, original, rawKey, "PROCESSING");
            song.getTracks().add(track);
        } else {
            track.setOriginalFilename(original);
            track.setMediaPath(rawKey);
            track.setMediaStatus("PROCESSING");
        }
        track.setContentType(file.getContentType());
        track.setSizeBytes(file.getSize());
        track.setDurationSeconds(null);
        track.setMediaVersion(version);
        track = tracks.save(track);

        events.publishEvent(new TrackUploadedEvent(track.getId(), rawKey, ext, previousKey));
        return SongDto.TrackResponse.of(track);
    }

    /** Pista lista para reproducir; lanza 404/409 con mensaje claro si no lo está. */
    @Transactional(readOnly = true)
    public SongTrack playable(Long songId, TrackType type) {
        SongTrack track = tracks.findBySongIdAndType(songId, type)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND,
                        "No hay audio para la pista " + type.name().toLowerCase(Locale.ROOT)));
        if (!"READY".equals(track.getMediaStatus())) {
            throw new ResponseStatusException(CONFLICT,
                    "%s".formatted("PROCESSING".equals(track.getMediaStatus())
                            ? "El audio se está procesando, inténtalo en unos segundos"
                            : "El audio de esta pista no está disponible"));
        }
        Path path = storage.resolve(track.getMediaPath());
        if (!Files.exists(path)) {
            throw new ResponseStatusException(NOT_FOUND, "El fichero de audio no existe en el servidor");
        }
        return track;
    }

    public Path resolve(SongTrack track) {
        return storage.resolve(track.getMediaPath());
    }

    private static String extension(String filename) {
        int dot = filename.lastIndexOf('.');
        return dot >= 0 ? filename.substring(dot + 1).toLowerCase(Locale.ROOT) : "";
    }
}
