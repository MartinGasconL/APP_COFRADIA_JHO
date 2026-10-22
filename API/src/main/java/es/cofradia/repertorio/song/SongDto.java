package es.cofradia.repertorio.song;

import jakarta.validation.constraints.*;
import java.util.*;

public final class SongDto {
    private SongDto() {}

    public record Request(
            @NotBlank @Size(max = 180) String title,
            String description,
            @Min(30) @Max(240) int bpm,
            @Min(1) int durationSeconds,
            boolean procession,
            boolean exhibition,
            boolean draft,
            @Size(max = 200_000) String info,
            List<SectionRequest> sections) {}

    public record SectionRequest(
            @NotBlank String title,
            String note,
            @Min(0) int startSeconds,
            @Min(1) int endSeconds,
            @NotBlank String color,
            boolean question,
            boolean answer,
            boolean desfase,
            String branchKey,
            Integer branchFrom,
            Integer branchTo,
            Boolean branchActive,
            List<SectionTrackRequest> tracks) {}

    public record SectionTrackRequest(@NotNull TrackType type, @DecimalMin("0") double startSeconds, @DecimalMin("0") double endSeconds) {}

    public record SectionTrackResponse(TrackType type, double startSeconds, double endSeconds) {}

    public record TrackResponse(
            Long id,
            TrackType type,
            String originalFilename,
            String status,
            Integer durationSeconds,
            int version) {

        public static TrackResponse of(SongTrack t) {
            return new TrackResponse(t.getId(), t.getType(), t.getOriginalFilename(),
                    t.getMediaStatus(), t.getDurationSeconds(), t.getMediaVersion());
        }
    }

    public record SectionResponse(
            Long id, String title, String note, int startSeconds, int endSeconds,
            String color, boolean question, boolean answer, boolean desfase,
            String branchKey, Integer branchFrom, Integer branchTo, boolean branchActive,
            List<SectionTrackResponse> tracks) {}

    public record Response(
            Long id, String title, String description, int bpm, int durationSeconds,
            boolean procession, boolean exhibition, boolean draft, String info,
            List<TrackResponse> tracks, List<SectionResponse> sections) {}
}
