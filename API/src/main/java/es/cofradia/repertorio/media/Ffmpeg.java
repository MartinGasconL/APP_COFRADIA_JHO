package es.cofradia.repertorio.media;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.TimeUnit;

/**
 * Envoltura fina sobre los binarios ffmpeg/ffprobe (procesos externos).
 * Requiere FFmpeg instalado en el servidor; si no está, {@link #available()} devuelve false
 * y el flujo de subida degrada con elegancia (acepta audio ya reproducible sin convertir).
 */
@Component
public class Ffmpeg {

    private static final Logger log = LoggerFactory.getLogger(Ffmpeg.class);

    private final String ffmpegPath;
    private final String ffprobePath;

    public Ffmpeg(@Value("${cofradia.ffmpeg-path}") String ffmpegPath,
                  @Value("${cofradia.ffprobe-path}") String ffprobePath) {
        this.ffmpegPath = ffmpegPath;
        this.ffprobePath = ffprobePath;
    }

    public boolean available() {
        try {
            return run(List.of(ffmpegPath, "-version"), 10).exitCode == 0;
        } catch (Exception e) {
            return false;
        }
    }

    /** Extrae la pista de audio y la codifica como MP3 192 kbps. */
    public void toMp3(Path input, Path output) throws IOException, InterruptedException {
        Result r = run(List.of(ffmpegPath, "-y", "-i", input.toString(),
                "-vn", "-acodec", "libmp3lame", "-b:a", "192k", output.toString()), 300);
        if (r.exitCode != 0) {
            throw new IOException("FFmpeg falló (código " + r.exitCode + "): " + tail(r.output));
        }
    }

    public Optional<Integer> probeDurationSeconds(Path file) {
        try {
            Result r = run(List.of(ffprobePath, "-v", "error",
                    "-show_entries", "format=duration",
                    "-of", "default=noprint_wrappers=1:nokey=1", file.toString()), 30);
            if (r.exitCode != 0) return Optional.empty();
            String value = r.output.trim();
            if (value.isEmpty() || value.equals("N/A")) return Optional.empty();
            return Optional.of((int) Math.round(Double.parseDouble(value)));
        } catch (Exception e) {
            log.debug("ffprobe no pudo leer la duración de {}: {}", file, e.toString());
            return Optional.empty();
        }
    }

    private Result run(List<String> command, int timeoutSeconds) throws IOException, InterruptedException {
        ProcessBuilder pb = new ProcessBuilder(command).redirectErrorStream(true);
        Process process = pb.start();
        StringBuilder out = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                out.append(line).append('\n');
            }
        }
        if (!process.waitFor(timeoutSeconds, TimeUnit.SECONDS)) {
            process.destroyForcibly();
            throw new IOException("FFmpeg superó el tiempo máximo (" + timeoutSeconds + "s)");
        }
        return new Result(process.exitValue(), out.toString());
    }

    private static String tail(String s) {
        String[] lines = s.strip().split("\n");
        int from = Math.max(0, lines.length - 3);
        return String.join(" | ", List.of(lines).subList(from, lines.length));
    }

    private record Result(int exitCode, String output) {}
}
