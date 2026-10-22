package es.cofradia.repertorio.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig implements WebMvcConfigurer {

    private final String[] origins;

    public CorsConfig(@Value("${cofradia.cors-origins}") String origins) {
        this.origins = origins.split("\\s*,\\s*");
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                // Patrones (admiten comodines de host/puerto): en desarrollo el frontend
                // se sirve por http o https, en localhost o en la IP de la LAN (móvil).
                .allowedOriginPatterns(origins)
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                // El navegador necesita leer estas cabeceras para el streaming con Range.
                .exposedHeaders("Content-Range", "Accept-Ranges", "Content-Length", "Content-Disposition")
                .maxAge(3600);
    }
}
