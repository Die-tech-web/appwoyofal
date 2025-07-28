--
-- PostgreSQL database dump
--

-- Dumped from database version 15.13 (Debian 15.13-1.pgdg120+1)
-- Dumped by pg_dump version 15.13 (Debian 15.13-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: exists_code_recharge(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.exists_code_recharge(code text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM achats WHERE code_recharge = code);
END;
$$;


ALTER FUNCTION public.exists_code_recharge(code text) OWNER TO postgres;

--
-- Name: generer_code_recharge(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generer_code_recharge() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    code_recharge TEXT;
    tentatives INTEGER := 0;
    max_tentatives INTEGER := 10;
BEGIN
    LOOP
        -- Format: XXXX-XXXX-XXXX-XXXX (16 chiffres)
        code_recharge := LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0') || '-' ||
                         LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0') || '-' ||
                         LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0') || '-' ||
                         LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0');
        
        -- Vérifier l'unicité
        IF NOT EXISTS (SELECT 1 FROM achats WHERE code_recharge = code_recharge) THEN
            EXIT;
        END IF;
        
        tentatives := tentatives + 1;
        IF tentatives >= max_tentatives THEN
            -- Si trop de tentatives, ajouter un timestamp
            code_recharge := code_recharge || '-' || EXTRACT(EPOCH FROM NOW())::INTEGER;
            EXIT;
        END IF;
    END LOOP;
    
    RETURN code_recharge;
END;
$$;


ALTER FUNCTION public.generer_code_recharge() OWNER TO postgres;

--
-- Name: generer_reference_achat(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generer_reference_achat() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    nouvelle_reference TEXT;
    date_courante TEXT;
    numero_sequence INTEGER;
BEGIN
    -- Format: WOY-YYYYMMDD-NNNN
    date_courante := TO_CHAR(CURRENT_DATE, 'YYYYMMDD');
    
    -- Obtenir le prochain numéro de séquence pour aujourd'hui
    SELECT COALESCE(MAX(CAST(SUBSTRING(reference FROM 'WOY-\d{8}-(\d{4})') AS INTEGER)), 0) + 1
    INTO numero_sequence
    FROM achats
    WHERE reference LIKE 'WOY-' || date_courante || '-%';
    
    nouvelle_reference := 'WOY-' || date_courante || '-' || LPAD(numero_sequence::TEXT, 4, '0');
    
    RETURN nouvelle_reference;
END;
$$;


ALTER FUNCTION public.generer_reference_achat() OWNER TO postgres;

--
-- Name: get_last_achat_by_date(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_last_achat_by_date(date_str text) RETURNS TABLE(reference text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT a.reference
    FROM achats a
    WHERE a.reference LIKE 'WOY-' || date_str || '-%'
    ORDER BY a.reference DESC
    LIMIT 1;
END;
$$;


ALTER FUNCTION public.get_last_achat_by_date(date_str text) OWNER TO postgres;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: achats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.achats (
    id integer NOT NULL,
    reference character varying(100) NOT NULL,
    code_recharge character varying(255) NOT NULL,
    numero_compteur character varying(100) NOT NULL,
    montant numeric(10,2) NOT NULL,
    nbre_kwt numeric(10,2) NOT NULL,
    tranche character varying(50),
    prix_kw numeric(10,2),
    client_nom character varying(255),
    date_achat timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    statut character varying(50) DEFAULT 'success'::character varying
);


ALTER TABLE public.achats OWNER TO postgres;

--
-- Name: achats_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.achats_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.achats_id_seq OWNER TO postgres;

--
-- Name: achats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.achats_id_seq OWNED BY public.achats.id;


--
-- Name: clients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clients (
    id integer NOT NULL,
    nom character varying(100) NOT NULL,
    prenom character varying(100) NOT NULL,
    telephone character varying(20) NOT NULL,
    adresse text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.clients OWNER TO postgres;

--
-- Name: clients_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.clients_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.clients_id_seq OWNER TO postgres;

--
-- Name: clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.clients_id_seq OWNED BY public.clients.id;


--
-- Name: compteurs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.compteurs (
    id integer NOT NULL,
    numero character varying(50) NOT NULL,
    client_id integer NOT NULL,
    actif boolean DEFAULT true,
    date_creation timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.compteurs OWNER TO postgres;

--
-- Name: compteurs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.compteurs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.compteurs_id_seq OWNER TO postgres;

--
-- Name: compteurs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.compteurs_id_seq OWNED BY public.compteurs.id;


--
-- Name: logs_achats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.logs_achats (
    id integer NOT NULL,
    date_heure timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    localisation character varying(255),
    adresse_ip character varying(45),
    statut character varying(50) NOT NULL,
    numero_compteur character varying(100),
    code_recharge character varying(255),
    nbre_kwt numeric(10,2),
    message_erreur text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.logs_achats OWNER TO postgres;

--
-- Name: logs_achats_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.logs_achats_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.logs_achats_id_seq OWNER TO postgres;

--
-- Name: logs_achats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.logs_achats_id_seq OWNED BY public.logs_achats.id;


--
-- Name: tranches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tranches (
    id integer NOT NULL,
    nom character varying(100) NOT NULL,
    min_montant numeric(12,2) NOT NULL,
    max_montant numeric(12,2),
    prix_kw numeric(10,4) NOT NULL,
    ordre integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_montant_coherent CHECK ((min_montant <= COALESCE(max_montant, min_montant))),
    CONSTRAINT check_ordre_positif CHECK ((ordre > 0)),
    CONSTRAINT check_prix_positif CHECK ((prix_kw > (0)::numeric))
);


ALTER TABLE public.tranches OWNER TO postgres;

--
-- Name: tranches_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tranches_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tranches_id_seq OWNER TO postgres;

--
-- Name: tranches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tranches_id_seq OWNED BY public.tranches.id;


--
-- Name: achats id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.achats ALTER COLUMN id SET DEFAULT nextval('public.achats_id_seq'::regclass);


--
-- Name: clients id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients ALTER COLUMN id SET DEFAULT nextval('public.clients_id_seq'::regclass);


--
-- Name: compteurs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compteurs ALTER COLUMN id SET DEFAULT nextval('public.compteurs_id_seq'::regclass);


--
-- Name: logs_achats id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.logs_achats ALTER COLUMN id SET DEFAULT nextval('public.logs_achats_id_seq'::regclass);


--
-- Name: tranches id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tranches ALTER COLUMN id SET DEFAULT nextval('public.tranches_id_seq'::regclass);


--
-- Data for Name: achats; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.achats (id, reference, code_recharge, numero_compteur, montant, nbre_kwt, tranche, prix_kw, client_nom, date_achat, created_at, statut) FROM stdin;
1	WOY-20250727-6060	1977-9016-5639-8453	CPT123456	100.00	1.02	Tranche 1	98.00	Die NIANG	2025-07-27 08:59:53	2025-07-27 08:59:53.382653	success
2	WOY-20250727-8173	1135-2308-7747-1166	CPT123456	1000.00	10.20	Tranche 1	98.00	Die NIANG	2025-07-27 09:41:56	2025-07-27 09:41:56.253276	success
3	WOY-20250727-2782	4903-2478-2420-2809	CPT123456	100.00	1.02	Tranche 1	98.00	Die NIANG	2025-07-27 10:30:41	2025-07-27 10:30:41.577837	success
4	WOY-20250727-2307	6561-3565-4471-9012	CPT123456	100.00	1.02	Tranche 1	98.00	Die NIANG	2025-07-27 10:59:03	2025-07-27 10:59:03.35908	success
5	WOY-20250727-1549	6289-3771-5554-1525	CPT123456	100.00	1.02	Tranche 1	98.00	Die NIANG	2025-07-27 10:59:45	2025-07-27 10:59:45.91649	success
\.


--
-- Data for Name: clients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clients (id, nom, prenom, telephone, adresse, created_at, updated_at) FROM stdin;
14	NIANG	Die	+221771234567	Dakar, Sénégal	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
15	DIOP	Fatou	+221772345678	Thiès, Sénégal	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
16	FALL	Moussa	+221773456789	Saint-Louis, Sénégal	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
17	BA	Aminata	+221774567890	Kaolack, Sénégal	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
18	SARR	Ibrahima	+221775678901	Ziguinchor, Sénégal	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
19	SOW	Ousmane	+221776789012	Dakar, Sénégal	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
20	KANE	Khady	+221777890123	Rufisque, Sénégal	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
21	DIALLO	Mamadou	+221778901234	Kolda, Sénégal	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
\.


--
-- Data for Name: compteurs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.compteurs (id, numero, client_id, actif, date_creation, created_at, updated_at) FROM stdin;
14	CPT123456	14	t	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
15	CPT789012	15	t	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
16	CPT345678	16	t	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
17	CPT901234	17	t	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
18	CPT567890	18	f	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
19	CPT111222	19	t	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
20	CPT333444	20	t	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
21	CPT555666	21	t	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
\.


--
-- Data for Name: logs_achats; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.logs_achats (id, date_heure, localisation, adresse_ip, statut, numero_compteur, code_recharge, nbre_kwt, message_erreur, created_at) FROM stdin;
1	2025-07-27 08:49:19	Dakar, Sénégal	172.19.0.1	Échec	CPT123456	\N	\N	SQLSTATE[42P01]: Undefined table: 7 ERROR:  relation "achats" does not exist\nLINE 1: INSERT INTO achats (reference, code_recharge, numero_compteu...\n                    ^	2025-07-27 08:49:19.239885
2	2025-07-27 08:56:25	Dakar, Sénégal	172.19.0.1	Échec	CPT123456	\N	\N	SQLSTATE[42P01]: Undefined table: 7 ERROR:  relation "achats" does not exist\nLINE 1: INSERT INTO achats (reference, code_recharge, numero_compteu...\n                    ^	2025-07-27 08:56:25.804369
3	2025-07-27 08:58:22	Dakar, Sénégal	172.19.0.1	Échec	CPT123456	\N	\N	SQLSTATE[42703]: Undefined column: 7 ERROR:  column "statut" of relation "achats" does not exist\nLINE 2: ...          nbre_kwt, tranche, prix_kw, date_achat, statut, cl...\n                                                             ^	2025-07-27 08:58:22.619359
4	2025-07-27 08:59:53	Dakar, Sénégal	172.19.0.1	Success	CPT123456	1977-9016-5639-8453	1.02	\N	2025-07-27 08:59:53.385488
5	2025-07-27 09:41:56	Dakar, Sénégal	172.19.0.1	Success	CPT123456	1135-2308-7747-1166	10.20	\N	2025-07-27 09:41:56.254475
6	2025-07-27 10:30:41	Dakar, Sénégal	172.19.0.1	Success	CPT123456	4903-2478-2420-2809	1.02	\N	2025-07-27 10:30:41.585127
7	2025-07-27 10:59:03	Dakar, Sénégal	172.19.0.1	Success	CPT123456	6561-3565-4471-9012	1.02	\N	2025-07-27 10:59:03.360458
8	2025-07-27 10:59:45	Dakar, Sénégal	172.19.0.1	Success	CPT123456	6289-3771-5554-1525	1.02	\N	2025-07-27 10:59:45.920016
\.


--
-- Data for Name: tranches; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tranches (id, nom, min_montant, max_montant, prix_kw, ordre, created_at, updated_at) FROM stdin;
1	Tranche 1	0.00	5000.00	98.0000	1	2025-07-26 18:09:55.437341	2025-07-26 18:09:55.437341
2	Tranche 2	5001.00	15000.00	105.0000	2	2025-07-26 18:09:55.437341	2025-07-26 18:09:55.437341
3	Tranche 3	15001.00	30000.00	115.0000	3	2025-07-26 18:09:55.437341	2025-07-26 18:09:55.437341
4	Tranche 4	30001.00	\N	125.0000	4	2025-07-26 18:09:55.437341	2025-07-26 18:09:55.437341
9	Tranche 1	0.00	5000.00	98.0000	1	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
10	Tranche 2	5001.00	15000.00	105.0000	2	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
11	Tranche 3	15001.00	30000.00	115.0000	3	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
12	Tranche 4	30001.00	\N	125.0000	4	2025-07-27 00:31:20.435672	2025-07-27 00:31:20.435672
\.


--
-- Name: achats_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.achats_id_seq', 5, true);


--
-- Name: clients_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.clients_id_seq', 21, true);


--
-- Name: compteurs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.compteurs_id_seq', 21, true);


--
-- Name: logs_achats_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.logs_achats_id_seq', 8, true);


--
-- Name: tranches_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tranches_id_seq', 12, true);


--
-- Name: achats achats_code_recharge_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.achats
    ADD CONSTRAINT achats_code_recharge_key UNIQUE (code_recharge);


--
-- Name: achats achats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.achats
    ADD CONSTRAINT achats_pkey PRIMARY KEY (id);


--
-- Name: achats achats_reference_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.achats
    ADD CONSTRAINT achats_reference_key UNIQUE (reference);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: compteurs compteurs_numero_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compteurs
    ADD CONSTRAINT compteurs_numero_key UNIQUE (numero);


--
-- Name: compteurs compteurs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compteurs
    ADD CONSTRAINT compteurs_pkey PRIMARY KEY (id);


--
-- Name: logs_achats logs_achats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.logs_achats
    ADD CONSTRAINT logs_achats_pkey PRIMARY KEY (id);


--
-- Name: tranches tranches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tranches
    ADD CONSTRAINT tranches_pkey PRIMARY KEY (id);


--
-- Name: idx_achats_code_recharge; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_achats_code_recharge ON public.achats USING btree (code_recharge);


--
-- Name: idx_achats_date_achat; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_achats_date_achat ON public.achats USING btree (date_achat);


--
-- Name: idx_achats_numero_compteur; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_achats_numero_compteur ON public.achats USING btree (numero_compteur);


--
-- Name: idx_achats_reference; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_achats_reference ON public.achats USING btree (reference);


--
-- Name: idx_achats_statut; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_achats_statut ON public.achats USING btree (statut);


--
-- Name: idx_compteurs_actif; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_compteurs_actif ON public.compteurs USING btree (actif);


--
-- Name: idx_compteurs_client; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_compteurs_client ON public.compteurs USING btree (client_id);


--
-- Name: idx_compteurs_numero; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_compteurs_numero ON public.compteurs USING btree (numero);


--
-- Name: idx_logs_achats_date_heure; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_logs_achats_date_heure ON public.logs_achats USING btree (date_heure);


--
-- Name: idx_logs_achats_numero_compteur; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_logs_achats_numero_compteur ON public.logs_achats USING btree (numero_compteur);


--
-- Name: idx_logs_achats_statut; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_logs_achats_statut ON public.logs_achats USING btree (statut);


--
-- Name: idx_tranches_ordre; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tranches_ordre ON public.tranches USING btree (ordre);


--
-- Name: clients update_clients_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: compteurs update_compteurs_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_compteurs_updated_at BEFORE UPDATE ON public.compteurs FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: tranches update_tranches_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_tranches_updated_at BEFORE UPDATE ON public.tranches FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: compteurs compteurs_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compteurs
    ADD CONSTRAINT compteurs_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

