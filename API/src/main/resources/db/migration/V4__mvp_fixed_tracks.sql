-- MVP: pistas fijas -> tambor, bombo, bombo desfase 1, bombo desfase 2, todos juntos.
UPDATE song_tracks         SET track_type = 'BOMBO_DESFASE1' WHERE track_type = 'DESFASE1';
UPDATE song_tracks         SET track_type = 'BOMBO_DESFASE2' WHERE track_type = 'DESFASE2';
UPDATE song_section_tracks SET track_type = 'BOMBO_DESFASE1' WHERE track_type = 'DESFASE1';
UPDATE song_section_tracks SET track_type = 'BOMBO_DESFASE2' WHERE track_type = 'DESFASE2';

DELETE FROM song_tracks         WHERE track_type IN ('DESFASE3', 'DESFASE4', 'DESFASE5');
DELETE FROM song_section_tracks WHERE track_type IN ('DESFASE3', 'DESFASE4', 'DESFASE5');
