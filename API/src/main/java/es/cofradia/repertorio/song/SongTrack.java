package es.cofradia.repertorio.song;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "song_tracks")
public class SongTrack {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "song_id", nullable = false)
    private Song song;

    @Enumerated(EnumType.STRING)
    @Column(name = "track_type", nullable = false)
    private TrackType type;

    @Column(name = "original_filename", nullable = false)
    private String originalFilename;

    /** Ruta relativa dentro del almacenamiento de medios. */
    @Column(name = "media_path", nullable = false)
    private String mediaPath;

    @Column(name = "media_status", nullable = false)
    private String mediaStatus = "PENDING";

    @Column(name = "content_type")
    private String contentType;

    @Column(name = "size_bytes")
    private Long sizeBytes;

    @Column(name = "duration_seconds")
    private Integer durationSeconds;

    @Column(name = "media_version", nullable = false)
    private int mediaVersion = 1;

    @Column(name = "updated_at", insertable = false, updatable = false)
    private Instant updatedAt;

    protected SongTrack() {}

    public SongTrack(Song song, TrackType type, String originalFilename, String mediaPath, String mediaStatus) {
        this.song = song;
        this.type = type;
        this.originalFilename = originalFilename;
        this.mediaPath = mediaPath;
        this.mediaStatus = mediaStatus;
    }

    public Long getId() { return id; }
    public Song getSong() { return song; }
    public TrackType getType() { return type; }
    public String getOriginalFilename() { return originalFilename; }
    public String getMediaPath() { return mediaPath; }
    public String getMediaStatus() { return mediaStatus; }
    public String getContentType() { return contentType; }
    public Long getSizeBytes() { return sizeBytes; }
    public Integer getDurationSeconds() { return durationSeconds; }
    public int getMediaVersion() { return mediaVersion; }
    public Instant getUpdatedAt() { return updatedAt; }

    public void setOriginalFilename(String v) { this.originalFilename = v; }
    public void setMediaPath(String v) { this.mediaPath = v; }
    public void setMediaStatus(String v) { this.mediaStatus = v; }
    public void setContentType(String v) { this.contentType = v; }
    public void setSizeBytes(Long v) { this.sizeBytes = v; }
    public void setDurationSeconds(Integer v) { this.durationSeconds = v; }
    public void setMediaVersion(int v) { this.mediaVersion = v; }
}
