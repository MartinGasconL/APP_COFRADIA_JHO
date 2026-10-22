package es.cofradia.repertorio.song;

import es.cofradia.repertorio.media.MediaStorage;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.NoSuchElementException;

@Service
public class SongService {

    private final SongRepository repository;
    private final MediaStorage storage;

    public SongService(SongRepository repository, MediaStorage storage) {
        this.repository = repository;
        this.storage = storage;
    }

    @Transactional
    public List<SongDto.Response> list() {
        return repository.findByDeletedFalseOrderById().stream().map(this::toResponse).toList();
    }

    /** Borra una canción: los borradores de verdad (con su audio), las oficiales lógicamente. */
    @Transactional
    public void delete(Long id) {
        Song s = repository.findDetailedById(id)
                .orElseThrow(() -> new NoSuchElementException("Canción no encontrada"));
        if (s.isDraft()) {
            for (SongTrack t : s.getTracks()) {
                if (t.getMediaPath() != null) storage.deleteQuietly(t.getMediaPath());
            }
            repository.delete(s);
        } else {
            s.markDeleted();
        }
    }

    @Transactional
    public SongDto.Response get(Long id) {
        return toResponse(find(id));
    }

    @Transactional
    public SongDto.Response create(SongDto.Request r) {
        Song s = new Song(r.title().trim(), r.description(), r.bpm(), r.durationSeconds(), r.procession(), r.exhibition(), r.draft());
        replaceSections(s, r.sections());
        s.setInfoMarkdown(r.info());
        return toResponse(repository.save(s));
    }

    @Transactional
    public SongDto.Response update(Long id, SongDto.Request r) {
        Song s = find(id);
        s.update(r.title().trim(), r.description(), r.bpm(), r.durationSeconds(), r.procession(), r.exhibition(), r.draft());
        s.setInfoMarkdown(r.info());
        replaceSections(s, r.sections());
        return toResponse(s);
    }

    public Song find(Long id) {
        Song s = repository.findDetailedById(id)
                .orElseThrow(() -> new NoSuchElementException("Canción no encontrada"));
        if (s.isDeleted()) throw new NoSuchElementException("Canción no encontrada");
        return s;
    }

    private void replaceSections(Song s, List<SongDto.SectionRequest> sections) {
        s.getSections().clear();
        if (sections == null) return;
        int mainOrder = 0;
        java.util.Map<String, Integer> branchOrder = new java.util.HashMap<>();
        for (var x : sections) {
            if (x.endSeconds() <= x.startSeconds()) {
                throw new IllegalArgumentException("El final de una parte debe ser posterior al inicio");
            }
            int order;
            if (x.branchKey() == null || x.branchKey().isBlank()) {
                order = mainOrder++;
            } else {
                order = branchOrder.getOrDefault(x.branchKey(), 0);
                branchOrder.put(x.branchKey(), order + 1);
            }
            SongSection section = new SongSection(s, x.title(), x.note(), x.startSeconds(), x.endSeconds(),
                    x.color(), x.question(), x.answer(), x.desfase(), order,
                    x.branchKey() == null || x.branchKey().isBlank() ? null : x.branchKey(),
                    x.branchFrom(), x.branchTo(), x.branchActive() == null || x.branchActive());
            if (x.tracks() != null) {
                for (var t : x.tracks()) {
                    // [start,end] es un recorte dentro del audio de la pista (offset en segundos con decimales)
                    double start = Math.max(0, t.startSeconds());
                    double end = Math.max(start + 0.05, t.endSeconds());
                    section.addTrack(t.type(), start, end);
                }
            }
            s.getSections().add(section);
        }
    }

    public SongDto.Response toResponse(Song s) {
        List<SongDto.TrackResponse> tracks = s.getTracks().stream()
                .map(SongDto.TrackResponse::of)
                .toList();
        List<SongDto.SectionResponse> sections = s.getSections().stream()
                .map(x -> new SongDto.SectionResponse(x.getId(), x.getTitle(), x.getNote(),
                        x.getStartSeconds(), x.getEndSeconds(), x.getColor(), x.isQuestion(), x.isAnswer(), x.isDesfase(),
                        x.getBranchKey(), x.getBranchFrom(), x.getBranchTo(), x.isBranchActive(),
                        x.getTrackParts().stream()
                                .map(t -> new SongDto.SectionTrackResponse(t.getType(), t.getStartSeconds(), t.getEndSeconds()))
                                .toList()))
                .toList();
        return new SongDto.Response(s.getId(), s.getTitle(), s.getDescription(), s.getBpm(),
                s.getDurationSeconds(), s.isProcession(), s.isExhibition(), s.isDraft(), s.getInfoMarkdown(), tracks, sections);
    }
}
