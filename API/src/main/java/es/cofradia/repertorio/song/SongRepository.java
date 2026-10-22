package es.cofradia.repertorio.song;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SongRepository extends JpaRepository<Song, Long> {

    // Solo 'sections' en el fetch join: traer 'sections' y 'tracks' a la vez (dos List)
    // provoca MultipleBagFetchException. 'tracks' se carga lazy dentro de la transacción.
    @EntityGraph(attributePaths = {"sections"})
    Optional<Song> findDetailedById(Long id);

    List<Song> findByDeletedFalseOrderById();
}
