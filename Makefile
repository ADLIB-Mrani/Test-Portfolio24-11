PSQL ?= psql

.PHONY: installer verifier exemple
installer:
	$(PSQL) -X -v ON_ERROR_STOP=1 -f database/01_structure.sql
	$(PSQL) -X -v ON_ERROR_STOP=1 -f database/02_vues.sql
	$(PSQL) -X -v ON_ERROR_STOP=1 -f database/03_supabase.sql
	$(PSQL) -X -v ON_ERROR_STOP=1 -f database/04_demarrage.sql

verifier:
	$(PSQL) -X -v ON_ERROR_STOP=1 -f tests/contrats.sql

exemple:
	$(PSQL) -X -v ON_ERROR_STOP=1 -f examples/une_seance.sql
