package es.cofradia.repertorio.media;

import es.cofradia.repertorio.song.SongDto;
import es.cofradia.repertorio.song.SongTrack;
import es.cofradia.repertorio.song.TrackType;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.ResourceRegion;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/v1/songs/{songId}/tracks")
public class MediaController {

    /** Tamaño máximo de cada fragmento servido ante una petición Range. */
    private static final long CHUNK = 1024 * 1024;

    private final MediaService media;

    public MediaController(MediaService media) {
        this.media = media;
    }

    @PostMapping(value = "/{type}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.ACCEPTED)
    public SongDto.TrackResponse upload(@PathVariable Long songId,
                                       @PathVariable TrackType type,
                                       @RequestPart("file") MultipartFile file) throws IOException {
        return media.upload(songId, type, file);
    }

    @GetMapping("/{type}/audio")
    public ResponseEntity<ResourceRegion> stream(@PathVariable Long songId,
                                                 @PathVariable TrackType type,
                                                 @RequestHeader HttpHeaders headers) throws IOException {
        SongTrack track = media.playable(songId, type);
        Resource resource = new FileSystemResource(media.resolve(track));
        long length = resource.contentLength();
        MediaType contentType = track.getContentType() != null
                ? MediaType.parseMediaType(track.getContentType())
                : MediaType.parseMediaType("audio/mpeg");

        List<HttpRange> ranges = headers.getRange();
        if (ranges.isEmpty()) {
            return ResponseEntity.ok()
                    .contentType(contentType)
                    .header(HttpHeaders.ACCEPT_RANGES, "bytes")
                    .contentLength(length)
                    .body(new ResourceRegion(resource, 0, length));
        }

        HttpRange range = ranges.get(0);
        long start = range.getRangeStart(length);
        long end = range.getRangeEnd(length);
        long count = Math.min(CHUNK, end - start + 1);
        return ResponseEntity.status(HttpStatus.PARTIAL_CONTENT)
                .contentType(contentType)
                .header(HttpHeaders.ACCEPT_RANGES, "bytes")
                .body(new ResourceRegion(resource, start, count));
    }
}
