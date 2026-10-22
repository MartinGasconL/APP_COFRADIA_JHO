package es.cofradia.repertorio.song;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "song_sections")
public class SongSection {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "song_id", nullable = false)
    private Song song;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String note;

    @Column(name = "start_seconds", nullable = false)
    private int startSeconds;

    @Column(name = "end_seconds", nullable = false)
    private int endSeconds;

    @Column(nullable = false)
    private String color;

    @Column(nullable = false)
    private boolean question;

    @Column(nullable = false)
    private boolean answer;

    /** Indicativo explícito: en esta parte hay desfase de bombos. No se deriva de las pistas. */
    @Column(nullable = false)
    private boolean desfase;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    /** null = línea principal. Con valor = parte de esa rama. */
    @Column(name = "branch_key")
    private String branchKey;

    /** sort_order de la parte principal tras la que bifurca la rama. */
    @Column(name = "branch_from")
    private Integer branchFrom;

    /** sort_order de la parte principal en la que la rama reconcilia. */
    @Column(name = "branch_to")
    private Integer branchTo;

    /** true = la canción sigue esta rama; false = sigue la línea principal (la rama queda guardada pero inactiva). */
    @Column(name = "branch_active", nullable = false)
    private boolean branchActive = true;

    @OneToMany(mappedBy = "section", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<SectionTrack> trackParts = new ArrayList<>();

    protected SongSection() {}

    public SongSection(Song song, String title, String note, int start, int end, String color,
                       boolean question, boolean answer, boolean desfase, int order,
                       String branchKey, Integer branchFrom, Integer branchTo, boolean branchActive) {
        this.song = song;
        this.title = title;
        this.note = note;
        this.startSeconds = start;
        this.endSeconds = end;
        this.color = color;
        this.question = question;
        this.answer = answer;
        this.desfase = desfase;
        this.sortOrder = order;
        this.branchKey = branchKey;
        this.branchFrom = branchFrom;
        this.branchTo = branchTo;
        this.branchActive = branchActive;
    }

    public void addTrack(TrackType type, double start, double end) {
        trackParts.add(new SectionTrack(this, type, start, end));
    }

    public Long getId() { return id; }
    public String getTitle() { return title; }
    public String getNote() { return note; }
    public int getStartSeconds() { return startSeconds; }
    public int getEndSeconds() { return endSeconds; }
    public String getColor() { return color; }
    public boolean isQuestion() { return question; }
    public boolean isAnswer() { return answer; }
    public boolean isDesfase() { return desfase; }
    public int getSortOrder() { return sortOrder; }
    public String getBranchKey() { return branchKey; }
    public Integer getBranchFrom() { return branchFrom; }
    public Integer getBranchTo() { return branchTo; }
    public boolean isBranchActive() { return branchActive; }
    public List<SectionTrack> getTrackParts() { return trackParts; }
}
