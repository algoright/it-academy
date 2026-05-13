/*
=================================================================================
=================================================================================
NIVELL 1 - Exercicis 1, 2, 3, 4, 5, 6, 7, 8
NIVELL 2 - Exercicis 1, 2, 3, 4
=================================================================================
=================================================================================
Responsable: Alicia Domínguez Garnelo | Periode consultes: 05/05/2026-11/05/2026
=================================================================================
=================================================================================


=================================================================================
Exercici 1 A partir dels documents adjunts (estructura_dades i dades_introduir), 
importa les dues taules. Mostra les característiques principals de l'esquema creat
 i explica les diferents taules i variables que existeixen. Assegura't d'incloure
 un diagrama que il·lustri la relació entre les diferents taules i variables.
=================================================================================
*/

/*=============================================================================== 
En aquest punt cal executar els arxius .sql facilitats pel mentor:
  - estructura_dades
  - dades_introduir 
================================================================================*/

USE transactions;

-- Llistat de taules disponibles			
SHOW TABLES;

-- Anàlisi de l’estructura de la taula company
DESCRIBE company;

-- Quantificació de registres de la taula company
SELECT COUNT(*)
FROM company;

-- Anàlisi de l’estructura de la taula transactions
DESCRIBE transaction;

-- Quantificació de registres de la taula company
SELECT COUNT(*)
FROM transaction;

-- Normalització de tipus de dades (alineació clau primària i forana)

-- 1er PAS Obtenir el nom de la FK
SELECT CONSTRAINT_NAME
FROM information_schema.table_constraints
WHERE TABLE_NAME = 'transaction'
AND CONSTRAINT_TYPE = 'FOREIGN KEY';

-- 2n PAS Eliminació de la FK
ALTER TABLE transaction
DROP FOREIGN KEY transaction_ibfk_1;

-- 3r PAS Modificació de la columna
ALTER TABLE transaction
MODIFY company_id VARCHAR(15);

-- 4t PAS Creació de la FK
ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_company
FOREIGN KEY (company_id)
REFERENCES company(id);

-- Verificació D'ids únics a transactions

SELECT COUNT(DISTINCT company_id)
FROM transaction;

-- Anàlisi de relacions entre taules
SHOW CREATE TABLE company;
SHOW CREATE TABLE transaction;

-- CONDICIÓ D'STOP PER VERIFICAR UN COP EXECUTAT L'EXERCICI
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'STOP aquí';

/*
=================================================================================
Exercici 2 Utilitzant JOIN realitzaràs les següents consultes:

    Llistat dels països que estan generant vendes.
    Des de quants països es generen les vendes.
    Identifica la companyia amb la mitjana més gran de vendes.
=================================================================================*/

USE transactions;

-- Llistat dels països que estan generant operacions (JOIN requerit)
SELECT DISTINCT country AS paisos_operadors
FROM company c
JOIN transaction t ON c.id = t.company_id
WHERE declined = 0;

-- Des de quants països es generen operacions (utilitzant JOIN)
SELECT COUNT(DISTINCT country) AS total_paisos_amb_operacions
FROM company
JOIN transaction ON company.id = transaction.company_id
WHERE declined = 0;

-- Identifica la companyia amb la mitjana més gran d'operacions (utilitzant JOIN)
SELECT company.company_name AS nom_empresa, ROUND(AVG(transaction.amount), 3) AS mitjana_vendes
FROM company
JOIN transaction ON company.id = transaction.company_id
WHERE declined = 0
GROUP BY company.company_name, company.id
ORDER BY mitjana_vendes DESC
LIMIT 1;

/*
=================================================================================
Exercici 3 Utilitzant només subconsultes (sense utilitzar JOIN):

    3.1 Mostra totes les transaccions realitzades per empreses d'Alemanya.
    
    3.2 Llista les empreses que han realitzat transaccions per un amount superior a 
    la mitjana de totes les transaccions. 
    
    3.3 Eliminaran del sistema les empreses que no tenen transaccions registrades, 
    entrega el llistat d'aquestes empreses.
=================================================================================*/

USE transactions;

-- Consulta 3.1

SELECT id, credit_card_id AS id_targeta_credit, company_id AS id_empresa, user_id AS id_usuari, lat, longitude AS longitud, timestamp AS data, amount AS import, declined AS rebutjada
FROM transaction t
WHERE declined = 0
AND EXISTS (
	SELECT 1
    FROM company c
    WHERE c.id = t.company_id
    AND country = 'Germany'
    );

-- Consulta 3.2

SELECT DISTINCT company_name AS nom_empresa
FROM company c
WHERE EXISTS (
	SELECT 1
    FROM transaction t
    WHERE c.id = t.company_id
    AND t.amount > (
		SELECT avg(amount)
        FROM transaction
        WHERE declined = 0)
	AND t.declined = 0
    );

-- Consulta 3.3

SELECT DISTINCT company_name as nom_empresa
FROM company c
WHERE NOT EXISTS (
	SELECT 1
    FROM transaction t
    WHERE c.id = t.company_id
);

/*
=================================================================================
Exercici 4 La teva tasca és dissenyar i crear una taula anomenada "credit_card" 
que emmagatzemi detalls crucials sobre les targetes de crèdit. La nova taula ha 
de ser capaç d'identificar de manera única cada targeta i establir una relació 
adequada amb les altres dues taules ("transaction" i "company"). Després de crear
 la taula serà necessari que ingressis la informació del document denominat 
 "dades_introduir_credit". Recorda mostrar el diagrama i realitzar una breu 
 descripció d'aquest.
=================================================================================
*/

USE transactions;

-- Creació de la taula credit_card
CREATE TABLE IF NOT EXISTS credit_card (
	id VARCHAR(15) PRIMARY KEY,
    iban VARCHAR(50),
    pan VARCHAR(25),
    pin CHAR(4),
    cvv CHAR(3),
    expiring_date VARCHAR(20)
);

-- CONDICIÓ D'STOP PER EXECUTAR FIXER SQL AMB DADES DE CREDIT
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'STOP aquí';

/*====================================================================================
Executar aquí el fitxer: dades_introduir_credit.sql
=====================================================================================*/

-- Verificació de càrrega de dades
SELECT *
FROM credit_card
LIMIT 10;

-- Visualització de valors abans de la conversió
SELECT expiring_date
FROM credit_card
LIMIT 50;

-- Conversió de VARCHAR a DATE
UPDATE credit_card
SET expiring_date = STR_TO_DATE(expiring_date, '%m/%d/%y')
WHERE id IS NOT NULL
LIMIT 9999999999; 

-- Visualització de dades després de la conversió
SELECT *
FROM credit_card
LIMIT 100;

-- Comprovació de NULLs després de la conversió
SELECT COUNT(*)
FROM credit_card
WHERE expiring_date IS NULL;


-- Canvi de tipus de dada a DATE
ALTER TABLE credit_card
MODIFY expiring_date DATE;

-- Creació de la clau forana amb credit_card
ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_credit_card
FOREIGN KEY (credit_card_id)
REFERENCES credit_card(id);

-- Verificació de coherència de dades 
SELECT DISTINCT t.credit_card_id
FROM transaction t
WHERE NOT EXISTS (
	SELECT 1
    FROM credit_card c
    WHERE c.id = t.credit_card_id
);

-- Revisió estructural de les taules
SHOW CREATE TABLE transaction;
SHOW CREATE TABLE credit_card;
SHOW CREATE TABLE company;

-- CONDICIÓ D'STOP FINAL
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'STOP aquí';


/*
=================================================================================
Exercici 5 El departament de Recursos Humans ha identificat un error en el número 
de compte associat a la targeta de crèdit amb ID CcU-2938. La informació que ha de
mostrar-se per a aquest registre és: TR323456312213576817699999. 
Recorda mostrar que el canvi es va realitzar.
=================================================================================
*/

USE transactions;

-- Verificació de les dades abans d'eliminar-les
SELECT id, pan
FROM credit_card
LIMIT 20;

-- Modificació de dades associades a una targeta de crèdit
UPDATE credit_card
SET iban = 'TR323456312213576817699999'
where id = 'CcU-2938';

-- Comprovació
SELECT *
FROM credit_card
WHERE id = 'CcU-2938';

SELECT *
FROM transaction
LIMIT 10;

/*
=================================================================================
Exercici 6 En la taula "transaction" ingressa una nova transacció 
=================================================================================
*/

USE transactions;

-- Creació d'un registre per a la nova empresa
INSERT INTO company(id) VALUES ('b-9999'); 

-- Verificació de la creació
SELECT *
FROM company
WHERE id = 'b-9999';

-- Creació d'un registre per a la nova targeta
INSERT INTO credit_card(id) VALUES ('CcU-9999'); 

-- Verificació de la creació
SELECT *
from credit_card
WHERE id = 'CcU-9999';

-- Inserim la venda a la bbdd:

INSERT INTO transaction (
id, 
credit_card_id,
company_id,
user_id,
lat, 
timestamp,
longitude, 
amount,
declined)
VALUES (
'108B1D1D-5B23-A76C-55EF-C568E49A99DD',
'CcU-9999', 
'b-9999', 
9999,
829.999,
NOW(),
-117.999,
111.11,
0);

-- Verificació de l'enregistrament
SELECT *
FROM transaction
WHERE id = '108B1D1D-5B23-A76C-55EF-C568E49A99DD';

/*
=================================================================================
Exercici 7 Des de recursos humans et sol·liciten eliminar la columna "pan" de la 
taula credit_card. Recorda mostrar el canvi realitzat.
=================================================================================
*/

USE transactions;

-- Verifiquem
SELECT COUNT(*)
FROM pan
LIMIT 20;

-- Eliminem
ALTER TABLE credit_card
DROP COLUMN pan;

-- Comprovem
SELECT * 
FROM credit_card
LIMIT 5;

-- Segona comprovació
DESCRIBE credit_card;

/*
=================================================================================
Exercici 8 Descarrega els arxius CSV que trobaràs a l'apartat de recursos:

    american_users.csv
    european_users.csv
    companies.csv
    credit_cards.csv
    transactions.csv

Estudia'ls i dissenya una base de dades amb un esquema d'estrella que contingui, 
almenys 4 taules de les quals puguis realitzar les següents onsultes.
=================================================================================
*/
-- Consultem la configuració de MySQL per a treballar amb arxius
SHOW VARIABLES LIKE 'secure_file_priv';

-- Creació de la base de dades 

CREATE DATABASE IF NOT EXISTS operations;
USE operations;

-- Creació de les taules temporals
CREATE TABLE temporal_companies (
    company_id VARCHAR(15),
    company_name VARCHAR(255),
    phone VARCHAR(30),
    email VARCHAR(100),
    country VARCHAR(100),
    website VARCHAR(255)
);

CREATE TABLE temporal_users (
    id VARCHAR(20),
    name VARCHAR(100),
    surname VARCHAR(100),
    phone VARCHAR(30),
    email VARCHAR(100),
    birth_date VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    address VARCHAR(255)
);

CREATE TABLE temporal_credit_cards (
    id VARCHAR(20),
    user_id VARCHAR(20),
    iban VARCHAR(34),
    pan VARCHAR(30),
    pin VARCHAR(10),
    cvv VARCHAR(10),
    track1 TEXT,
    track2 TEXT,
    expiring_date VARCHAR(20)
);

CREATE TABLE temporal_transactions (
    id VARCHAR(36),
    card_id VARCHAR(20),
    company_id VARCHAR(15),
    user_id VARCHAR(20),
    timestamp VARCHAR(30),
    amount VARCHAR(20),
    declined VARCHAR(5),
    product_ids VARCHAR(255),
    lat VARCHAR(30),
    longitude VARCHAR(30)
);

-- Càrrega de dades usuaris americans i canadencs
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__ american_users.csv' 
INTO TABLE temporal_users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'  #no carregaba amb '\r\n'
IGNORE 1 ROWS; 

-- Verificació
SELECT COUNT(*)
FROM temporal_users;

-- Càrrega de dades usuaris europeus
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1.Ex.8__ european_users.csv'
INTO TABLE temporal_users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n' #no carregaba amb '\r\n'
IGNORE 1 ROWS;

-- Verificació i conteig
SELECT COUNT(*)
FROM temporal_users;

-- Càrrega d'empreses
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1.Ex.8__ companies.csv'
INTO TABLE temporal_companies
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- Verificació i conteig
SELECT COUNT(*)
FROM temporal_companies;

-- Càrrega de dades bancàries
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1.Ex.8__ credit_cards.csv'
INTO TABLE temporal_credit_cards
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Verificació i conteig
SELECT COUNT(*)
FROM temporal_credit_cards;

-- Càrrega de dades d'operacions (transactions)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1.Ex.8__ transactions.csv'
INTO TABLE temporal_transactions
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    id,
    card_id,
    company_id,
    timestamp,
    amount,
    declined,
    product_ids,
    user_id,
    lat,
    longitude
);

-- Verificació i conteig
SELECT COUNT(*)
FROM temporal_transactions;

-- Creació de taules definitives amb nova columna continent a users per filtrar usuaris

CREATE TABLE companies (
    company_id VARCHAR(15) PRIMARY KEY,
    company_name VARCHAR(255),
    phone VARCHAR(30),
    email VARCHAR(100),
    country VARCHAR(100),
    website VARCHAR(255)
);

CREATE TABLE users (
    user_key INT AUTO_INCREMENT PRIMARY KEY,
    source_user_id VARCHAR(20),
    name VARCHAR(100),
    surname VARCHAR(100),
    phone VARCHAR(30),
    email VARCHAR(100),
    birth_date DATE,
    address VARCHAR(255),
    postal_code VARCHAR(20),
    continent VARCHAR(20)
);

CREATE TABLE credit_cards (
    card_id VARCHAR(20) PRIMARY KEY,
    user_id VARCHAR(20),
    iban VARCHAR(34),
    pan VARCHAR(30),
    pin CHAR(4),
    cvv CHAR(3),
    track1 TEXT,
    track2 TEXT,
    expiring_date DATE
);

CREATE TABLE transactions (
    id VARCHAR(36) PRIMARY KEY,
    card_id VARCHAR(20),
    company_id VARCHAR(15),
    user_key INT,
    timestamp DATETIME,
    amount DECIMAL(10,2),
    declined BOOLEAN,
    product_ids VARCHAR(255),
    lat DECIMAL(10,8),
    longitude DECIMAL(11,8)
);

-- Transferència de dades a taules finales amb transformacions

INSERT INTO companies (
    company_id,
    company_name,
    phone,
    country,
    email,
    website
)
SELECT
    company_id,
    company_name,
    phone,
    email,
    country,
    website
FROM temporal_companies;

INSERT INTO users (
    source_user_id, 
    name, 
    surname, 
    phone, 
    email,
    birth_date, 
    address, 
    postal_code, 
    continent
)
SELECT
    id,
    name,
    surname,
    phone,
    email,
    STR_TO_DATE(birth_date, '%b %d, %Y'),
    address,
    postal_code,
    CASE
        WHEN address LIKE '%United States%' OR address LIKE '%Canada%' THEN 'America'
        ELSE 'Europe'
    END
FROM temporal_users;

INSERT INTO credit_cards
SELECT
    id,
    user_id,
    iban,
    pan,
    LEFT(pin,4),
    LEFT(cvv,3),
    track1,
    track2,
    STR_TO_DATE(expiring_date, '%m/%d/%y')
FROM temporal_credit_cards;

INSERT INTO transactions (
    id,
    card_id,
    company_id,
    user_key,
    timestamp,
    amount,
    declined,
    product_ids,
    lat,
    longitude
)
SELECT
    id,
    card_id,
    company_id,
    user_id,
    STR_TO_DATE(timestamp, '%Y-%m-%d %H:%i:%s'),
    CAST(amount AS DECIMAL(10,2)),
    CAST(declined AS UNSIGNED),
    product_ids,
    ROUND(lat,8),
    ROUND(longitude,8)
FROM temporal_transactions;

-- Creació d'una taula de dimensió de temps

CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE,
    year_number INT,
    month_number INT,
    month_name VARCHAR(15),
    quarter_number INT,
    day_name VARCHAR(15),
    is_weekend BOOLEAN
);

-- Creació de claus foranas (FKs)

ALTER TABLE transactions
ADD CONSTRAINT fk_card
FOREIGN KEY (card_id) REFERENCES credit_cards(card_id);

ALTER TABLE transactions
ADD CONSTRAINT fk_company
FOREIGN KEY (company_id) REFERENCES companies(company_id);

ALTER TABLE transactions
ADD CONSTRAINT fk_user
FOREIGN KEY (user_key) REFERENCES users(user_key);

-- Eliminació de les taules temporals
DROP TABLE IF EXISTS temporal_companies;
DROP TABLE IF EXISTS temporal_users;
DROP TABLE IF EXISTS temporal_credit_cards;
DROP TABLE IF EXISTS temporal_transactions;

-- Verificació de la estrucura de les taules
SHOW CREATE TABLE companies;
SHOW CREATE TABLE credit_cards;
SHOW CREATE TABLE dim_date;
SHOW CREATE TABLE transactions;
SHOW CREATE TABLE users;

-- Conexió de dim_date amb el model

-- Afegim columna amb camp per la FK
ALTER TABLE transactions
ADD COLUMN date_key INT;

-- Omplim les dades a transactions
UPDATE transactions
SET date_key = DATE_FORMAT(timestamp, '%Y%m%d')
WHERE id IS NOT NULL
LIMIT 999999999999;

-- Omplim de les dades a dim_table
INSERT INTO dim_date (
    date_key,
    full_date,
    year_number,
    month_number,
    month_name,
    quarter_number,
    day_name,
    is_weekend
)
SELECT DISTINCT
    date_key,
    DATE(timestamp),
    YEAR(timestamp),
    MONTH(timestamp),
    MONTHNAME(timestamp),
    QUARTER(timestamp),
    DAYNAME(timestamp),
    CASE
        WHEN DAYOFWEEK(timestamp) IN (1,7) THEN TRUE
        ELSE FALSE
	END
FROM transactions;

-- Creem la FK
ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_date
FOREIGN KEY (date_key)
REFERENCES dim_date(date_key);

-- Verifiquem les dades:

SELECT COUNT(*)
FROM dim_date;

-- Visualitzem les dades

SELECT *
FROM dim_date
LIMIT 20;

-- Verificació de coincidència de registres 

SELECT DISTINCT date_key
FROM transactions;


/*
=================================================================================
Exercici 9 Realitza una subconsulta que mostri tots els usuaris amb més de 80 
transaccions utilitzant almenys 2 taules.
=================================================================================
*/

USE operations;

SELECT
    user_key AS id_heavy_user,
    name AS nom,
    surname AS cognom
FROM users u
WHERE (
    SELECT COUNT(*)
    FROM transactions t
    WHERE t.user_key = u.user_key
    AND t.declined = 0
) > 80;

/*
=================================================================================
Exercici 10 Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la 
companyia Donec Ltd, utilitza almenys 2 taules.
=================================================================================
*/

USE operations;

SELECT AVG(amount) AS import_mitja, cc.iban, c.company_name AS nom_empresa
FROM transactions t
JOIN companies c ON t.company_id = c.company_id
JOIN credit_cards cc ON t.card_id = cc.card_id
WHERE c.company_name = 'Donec Ltd'
AND t.declined = 0
GROUP BY cc.iban;

/*===============================================================================
=================================================================================
NIVELL 2 - Exercicis 1, 2, 3, 4, 5
=================================================================================
=================================================================================
Responsable: Alicia Domínguez Garnelo | Periode consultes: 05/05/2026-11/05/2026
=================================================================================
===============================================================================*/


/*
=================================================================================
Exercici 1 Identifica els cinc dies que es va generar la quantitat més gran 
d'ingressos a l'empresa per vendes. Mostra la data de cada transacció juntament 
amb el total de les vendes.
=================================================================================
*/
USE operations;

SELECT d.full_date as data_transacció, SUM(ROUND(amount, 3)) AS total_vendes
FROM transactions t
JOIN dim_date d
ON t.date_key = d.date_key
WHERE declined= 0
GROUP BY d.full_date
ORDER BY total_vendes DESC
LIMIT 5;

/*
=================================================================================
Exercici 2 Presenta el nom, telèfon, país, data i amount, d'aquelles empreses que 
van realitzar transaccions amb un valor comprès entre 350 i 400 euros i en alguna 
d'aquestes dates: 29 d'abril del 2015, 20 de juliol del 2018 i 13 de març del 2024. 
Ordena els resultats de major a menor quantitat.
=================================================================================
*/

USE operations;

SELECT *
FROM companies;

-- Consulta final
SELECT 
    c.company_name AS nom,
    c.phone AS telefon,
    c.country AS pais,
    d.full_date AS data_transacció,
	ROUND(t.amount, 3) AS import
FROM transactions t
JOIN companies c
    ON t.company_id = c.company_id
JOIN dim_date d
    ON t.date_key = d.date_key
WHERE t.amount BETWEEN 350 AND 400
	AND t.declined = 0
	AND (
		d.full_date = '2015-04-29'
		OR d.full_date = '2018-07-20'
		OR d.full_date = '2024-03-13'
        )
ORDER BY t.amount DESC;

/*==============================================================================
Exercici 3 Necessitem optimitzar l'assignació dels recursos i dependrà de la 
capacitat operativa que es requereixi, per la qual cosa et demanen la informació
sobre la quantitat de transaccions que realitzen les empreses, però el departament
de recursos humans és exigent i vol un llistat de les empreses on especifiquis
si tenen igual o més de 400 transaccions o menys.
==============================================================================*/

USE operations;

SELECT
	c.company_name AS nom,
    COUNT(*) AS quantitat_transaccions,
	CASE
		WHEN COUNT(t.id) >= 400 THEN 'Igual o superior a 400'
        ELSE 'Inferior a 400'
	END AS Capacitat_operativa
FROM transactions t
JOIN companies c
ON t.company_id = c.company_id
WHERE t.declined = 0
GROUP BY c.company_id, c.company_name
ORDER BY quantitat_transaccions DESC;

/*
=================================================================================
Exercici 4 Elimina de la taula transaction el registre amb 
ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de dades
=================================================================================
*/

USE operations;

-- Verifiquem l'existéncia del registre:
SELECT *
FROM transactions
WHERE transactions.id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

-- Creem una taula de backup per registres eliminats
CREATE TABLE transactions_backup (
    id VARCHAR(36) PRIMARY KEY,
    card_id VARCHAR(20),
    company_id VARCHAR(15),
    user_key INT,
    timestamp DATETIME,
    amount DECIMAL(10,2),
    declined BOOLEAN,
    product_ids VARCHAR(255),
    lat DECIMAL(10,8),
    longitude DECIMAL(11,8)
);
-- Movem l'arxiu de transactions a backup

INSERT INTO transactions_backup (
    id,
    card_id,
    company_id,
    user_key,
    timestamp,
	amount,
    declined,
    product_ids,
    lat,
    longitude
)
SELECT 
    id,
    card_id,
    company_id,
    user_key,
    timestamp,
	amount,
    declined,
    product_ids,
    lat,
    longitude
FROM transactions
WHERE transactions.id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

-- Verifiquem la backup
SELECT *
FROM transactions_backup
WHERE transactions_backup.id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

-- Eliminem el registre de forma segura
DELETE 
FROM transactions
WHERE transactions.id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

-- Verificació de la eliminació
SELECT *
FROM transactions
WHERE transactions.id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';


/*=================================================================================
Exercici 4 La secció de màrqueting desitja tenir accés a informació específica 
per a realitzar anàlisi i estratègies efectives. S'ha sol·licitat crear una vista 
que proporcioni detalls clau sobre les companyies i les seves transaccions. 
Serà necessària que creïs una vista anomenada VistaMarketing que contingui 
la següent informació: Nom de la companyia. Telèfon de contacte. 
País de residència. Mitjana de compra realitzat per cada companyia. 
Presenta la vista creada, ordenant les dades de major a menor mitjana de compra.
=================================================================================*/

USE operations;

CREATE VIEW VistaMarqueting AS
SELECT 
    c.company_name AS nom_de_la_companyia,
    c.phone AS telefon_de_contacte,
    c.country AS pais_de_residencia,
	ROUND(AVG(t.amount),3) AS mitjana_de_compra
FROM transactions t
JOIN companies c
ON t.company_id = c.company_id
WHERE t.declined = 0
GROUP BY c.company_id
ORDER BY mitjana_de_compra DESC;

-- Verificació de creació de la vista
SHOW FULL TABLES
WHERE Table_type = 'VIEW';

-- Ús de la vista
SELECT *
FROM vistamarqueting;

/*===============================================================================
=================================================================================
NIVELL 3 - Exercicis 1, 2
=================================================================================
=================================================================================
Responsable: Alicia Domínguez Garnelo | Periode consultes: 12/05/2025
=================================================================================
===============================================================================*/

/*=================================================================================
Exercici 1 Crea una nova taula que reflecteixi l'estat de les targetes de crèdit 
basat en si les tres últimes transaccions han estat declinades aleshores és inactiu, 
si almenys una no és rebutjada aleshores és actiu. Partint d’aquesta taula respon:

👉 Quantes targetes estan actives?
=================================================================================*/

USE operations;

-- Query final (CTE, ROW_NUMBER, PARTITION BY, JOIN, SUBCONSULTA A FROM)
WITH transaccions_ordenades AS (     
	SELECT 
		t.card_id,
        t.declined,
		ROW_NUMBER() OVER (
		PARTITION BY t.card_id       
		ORDER BY d.full_date DESC
		) AS ordre_transaccio        
FROM transactions t
JOIN dim_date d
ON t.date_key = d.date_key
)                                   
SELECT COUNT(*) AS targetes_actives
FROM (
	SELECT card_id
    FROM transaccions_ordenades 
    WHERE ordre_transaccio <=3
    GROUP BY card_id
    HAVING SUM(declined) < 3          
) AS targetes_filtre_estat;

-- Creació de vista per verificar dades
CREATE VIEW v_transaccions_ordenades AS     
	SELECT 
		t.card_id,
        t.declined,
		ROW_NUMBER() OVER (
		PARTITION BY t.card_id       
		ORDER BY d.full_date DESC
		) AS ordre_transaccio        
FROM transactions t
JOIN dim_date d
ON t.date_key = d.date_key; 

-- Executem la vista (verificar funcionament row number)
SELECT *
FROM v_transaccions_ordenades;
