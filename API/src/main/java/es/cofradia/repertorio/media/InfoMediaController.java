package es.cofradia.repertorio.media;

import es.cofradia.repertorio.song.SongService;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.ResourceRegion;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

/** Imágenes, vídeos y audios que se incrustan en la información (Markdown) de una canción. */
@RestController
@RequestMapping("/api/v1/songs/{songId}/info-media")
public class InfoMediaController {

    private static final long CHUNK = 1024 * 1024;

    /** Extensión permitida -> tipo de contenido. Lista cerrada: no se sirve nada que el navegador pueda ejecutar (html, svg…). */
    private static final Map<String, String> TYPES = Map.ofEntries(
            Map.entry("png", "image/png"), Map.entry("jpg", "image/jpeg"), Map.entry("jpeg", "image/jpeg"),
            Map.entry("gif", "image/gif"), Map.entry("webp", "image/webp"),
            Map.entry("mp4", "video/mp4"), Map.entry("webm", "video/webm"),
            Map.entry("mp3", "audio/mpeg"), Map.entry("m4a", "audio/mp4"),
            Map.entry("wav", "audio/wav"), Map.entry("ogg", "audio/ogg"));

    public record Uploaded(String url, String kind, String name) {}

    private final MediaStorage storage;
    private final SongService songs;

    public InfoMediaController(MediaStorage storage, SongService songs) {
        this.storage = storage;
        this.songs = songs;
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public Uploaded upload(@PathVariable Long songId, @RequestPart("file") MultipartFile file) throws IOException {
        songs.find(songId); // 404 si la canción no existe
        String original = file.getOriginalFilename() == null ? "archivo" : file.getOriginalFilename();
        String ext = extension(original);
        String type = TYPES.get(ext);
        if (type == null) {
            throw new ResponseStatusException(HttpStatus.UNSUPPORTED_MEDIA_TYPE,
                    "Formato no admitido. Usa png, jpg, gif, webp, mp4, webm, mp3, m4a, wav u ogg.");
        }
        String name = UUID.randomUUID() + "." + ext;
        storage.store(key(songId, name), file.getInputStream());
        return new Uploaded("/api/v1/songs/" + songId + "/info-media/" + name, type.substring(0, type.indexOf('/')), original);
    }

    @GetMapping("/{name:[0-9a-f-]{36}[.][a-z0-9]{3,4}}")
    public ResponseEntity<ResourceRegion> serve(@PathVariable Long songId, @PathVariable String name,
                                                @RequestHeader HttpHeaders headers) throws IOException {
        String type = TYPES.get(extension(name));
        if (type == null || !storage.exists(key(songId, name))) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND);
        }
        Resource resource = new FileSystemResource(storage.resolve(key(songId, name)));
        long length = resource.contentLength();
        MediaType contentType = MediaType.parseMediaType(type);

        List<HttpRange> ranges = headers.getRange();
        if (ranges.isEmpty()) {
            return ResponseEntity.ok().contentType(contentType)
                    .header(HttpHeaders.ACCEPT_RANGES, "bytes")
                    .header("X-Content-Type-Options", "nosniff")
                    .cacheControl(CacheControl.noCache())
                    .body(new ResourceRegion(resource, 0, length));
        }
        HttpRange range = ranges.get(0);
        long start = range.getRangeStart(length);
        long end = range.getRangeEnd(length);
        long count = Math.min(CHUNK, end - start + 1);
        return ResponseEntity.status(HttpStatus.PARTIAL_CONTENT).contentType(contentType)
                .header(HttpHeaders.ACCEPT_RANGES, "bytes")
                .header("X-Content-Type-Options", "nosniff")
                .body(new ResourceRegion(resource, start, count));
    }

    private static String key(Long songId, String name) {
        return "songs/" + songId + "/info/" + name;
    }

    private static String extension(String filename) {
        int dot = filename.lastIndexOf('.');
        return dot < 0 ? "" : filename.substring(dot + 1).toLowerCase(Locale.ROOT);
    }
}
