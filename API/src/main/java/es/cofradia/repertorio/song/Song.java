package es.cofradia.repertorio.song;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "songs")
public class Song {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false)
    private int bpm;

    @Column(name = "duration_seconds", nullable = false)
    private int durationSeconds;

    @Column(nullable = false)
    private boolean procession;

    @Column(nullable = false)
    private boolean exhibition;

    /** Borrador (visible solo en Estudio) vs canción oficial (Repertorio / Canciones). */
    @Column(nullable = false)
    private boolean draft;

    /** Información de la canción en Markdown (admite imágenes, vídeo y audio incrustados). */
    @Column(name = "info_markdown", columnDefinition = "MEDIUMTEXT")
    private String infoMarkdown;

    /** Borrado lógico (solo canciones oficiales; los borradores se borran de verdad). */
    @Column(nullable = false)
    private boolean deleted;

    @OneToMany(mappedBy = "song", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("branchKey, sortOrder")
    private List<SongSection> sections = new ArrayList<>();

    @OneToMany(mappedBy = "song", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<SongTrack> tracks = new ArrayList<>();

    protected Song() {}

    public Song(String title, String description, int bpm, int duration, boolean procession, boolean exhibition, boolean draft) {
        this.title = title;
        this.description = description;
        this.bpm = bpm;
        this.durationSeconds = duration;
        this.procession = procession;
        this.exhibition = exhibition;
        this.draft = draft;
    }

    public Long getId() { return id; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public int getBpm() { return bpm; }
    public int getDurationSeconds() { return durationSeconds; }
    public boolean isProcession() { return procession; }
    public boolean isExhibition() { return exhibition; }
    public boolean isDraft() { return draft; }
    public String getInfoMarkdown() { return infoMarkdown; }
    public void setInfoMarkdown(String infoMarkdown) { this.infoMarkdown = infoMarkdown; }
    public boolean isDeleted() { return deleted; }
    public void markDeleted() { this.deleted = true; }
    public List<SongSection> getSections() { return sections; }
    public List<SongTrack> getTracks() { return tracks; }

    public void update(String title, String description, int bpm, int duration, boolean procession, boolean exhibition, boolean draft) {
        this.title = title;
        this.description = description;
        this.bpm = bpm;
        this.durationSeconds = duration;
        this.procession = procession;
        this.exhibition = exhibition;
        this.draft = draft;
    }
}
