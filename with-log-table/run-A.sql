BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
INSERT INTO things (id) VALUES ('A');
INSERT INTO log VALUES ((SELECT string_agg(id,'') FROM things));
COMMIT;
