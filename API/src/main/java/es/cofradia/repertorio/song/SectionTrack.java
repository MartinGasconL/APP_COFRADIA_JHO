package es.cofradia.repertorio.song;

import jakarta.persistence.*;

/**
 * Una pista que interviene en una parte, con su propio fragmento temporal
 * (p. ej. el bombo entra más tarde que el tambor dentro de la misma parte).
 */
@Entity
@Table(name = "song_section_tracks",
        uniqueConstraints = @UniqueConstraint(name = "uk_section_track", columnNames = {"section_id", "track_type"}))
public class SectionTrack {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "section_id", nullable = false)
    private SongSection section;

    @Enumerated(EnumType.STRING)
    @Column(name = "track_type", nullable = false)
    private TrackType type;

    /** Recorte dentro del audio de la pista, en segundos con decimales (offset). */
    @Column(name = "start_seconds", nullable = false)
    private double startSeconds;

    @Column(name = "end_seconds", nullable = false)
    private double endSeconds;

    protected SectionTrack() {}

    public SectionTrack(SongSection section, TrackType type, double startSeconds, double endSeconds) {
        this.section = section;
        this.type = type;
        this.startSeconds = startSeconds;
        this.endSeconds = endSeconds;
    }

    public Long getId() { return id; }
    public TrackType getType() { return type; }
    public double getStartSeconds() { return startSeconds; }
    public double getEndSeconds() { return endSeconds; }
}
