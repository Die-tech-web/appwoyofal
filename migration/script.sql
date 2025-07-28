--
-- PostgreSQL database migration
-- Structure de la base de données
--

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
-- Extensions
--
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

--
-- Suppression préalable des fonctions pour éviter conflits
--

DROP FUNCTION IF EXISTS public.exists_code_recharge(text);
DROP FUNCTION IF EXISTS public.generer_code_recharge();
DROP FUNCTION IF EXISTS public.generer_reference_achat();
DROP FUNCTION IF EXISTS public.get_last_achat_by_date(text);
DROP FUNCTION IF EXISTS public.update_updated_at_column();

--
-- Fonctions PL/pgSQL
--

-- Fonction pour vérifier l'existence d'un code de recharge
CREATE FUNCTION public.exists_code_recharge(code text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM achats WHERE code_recharge = code);
END;
$$;

-- Fonction pour générer un code de recharge unique
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

-- Fonction pour générer une référence d'achat
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

-- Fonction pour récupérer le dernier achat par date
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

-- Fonction trigger pour mettre à jour updated_at
CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

--
-- Tables
--

-- Table clients
CREATE TABLE IF NOT EXISTS public.clients (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    telephone VARCHAR(20) NOT NULL,
    adresse TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table tranches
CREATE TABLE IF NOT EXISTS public.tranches (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    min_montant NUMERIC(12,2) NOT NULL,
    max_montant NUMERIC(12,2),
    prix_kw NUMERIC(10,4) NOT NULL,
    ordre INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_montant_coherent CHECK (min_montant <= COALESCE(max_montant, min_montant)),
    CONSTRAINT check_ordre_positif CHECK (ordre > 0),
    CONSTRAINT check_prix_positif CHECK (prix_kw > 0::numeric)
);

-- Table compteurs
CREATE TABLE IF NOT EXISTS public.compteurs (
    id SERIAL PRIMARY KEY,
    numero VARCHAR(50) NOT NULL UNIQUE,
    client_id INTEGER NOT NULL,
    actif BOOLEAN DEFAULT true,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE
);

-- Table achats
CREATE TABLE IF NOT EXISTS public.achats (
    id SERIAL PRIMARY KEY,
    reference VARCHAR(100) NOT NULL UNIQUE,
    code_recharge VARCHAR(255) NOT NULL UNIQUE,
    numero_compteur VARCHAR(100) NOT NULL,
    montant NUMERIC(10,2) NOT NULL,
    nbre_kwt NUMERIC(10,2) NOT NULL,
    tranche VARCHAR(50),
    prix_kw NUMERIC(10,2),
    client_nom VARCHAR(255),
    date_achat TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    statut VARCHAR(50) DEFAULT 'success'
);

-- Table logs_achats
CREATE TABLE IF NOT EXISTS public.logs_achats (
    id SERIAL PRIMARY KEY,
    date_heure TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    localisation VARCHAR(255),
    adresse_ip VARCHAR(45),
    statut VARCHAR(50) NOT NULL,
    numero_compteur VARCHAR(100),
    code_recharge VARCHAR(255),
    nbre_kwt NUMERIC(10,2),
    message_erreur TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--
-- Index pour optimiser les performances
--

-- Index pour achats
CREATE INDEX IF NOT EXISTS idx_achats_reference ON public.achats USING btree (reference);
CREATE INDEX IF NOT EXISTS idx_achats_code_recharge ON public.achats USING btree (code_recharge);
CREATE INDEX IF NOT EXISTS idx_achats_numero_compteur ON public.achats USING btree (numero_compteur);
CREATE INDEX IF NOT EXISTS idx_achats_date_achat ON public.achats USING btree (date_achat);
CREATE INDEX IF NOT EXISTS idx_achats_statut ON public.achats USING btree (statut);

-- Index pour compteurs
CREATE INDEX IF NOT EXISTS idx_compteurs_numero ON public.compteurs USING btree (numero);
CREATE INDEX IF NOT EXISTS idx_compteurs_client ON public.compteurs USING btree (client_id);
CREATE INDEX IF NOT EXISTS idx_compteurs_actif ON public.compteurs USING btree (actif);

-- Index pour logs_achats
CREATE INDEX IF NOT EXISTS idx_logs_achats_date_heure ON public.logs_achats USING btree (date_heure);
CREATE INDEX IF NOT EXISTS idx_logs_achats_numero_compteur ON public.logs_achats USING btree (numero_compteur);
CREATE INDEX IF NOT EXISTS idx_logs_achats_statut ON public.logs_achats USING btree (statut);

-- Index pour tranches
CREATE INDEX IF NOT EXISTS idx_tranches_ordre ON public.tranches USING btree (ordre);

--
-- Suppression préalable des triggers (car pas de IF NOT EXISTS sur triggers)
--
DROP TRIGGER IF EXISTS update_clients_updated_at ON public.clients;
DROP TRIGGER IF EXISTS update_compteurs_updated_at ON public.compteurs;
DROP TRIGGER IF EXISTS update_tranches_updated_at ON public.tranches;

--
-- Triggers pour la mise à jour automatique des timestamps
--
CREATE TRIGGER update_clients_updated_at 
    BEFORE UPDATE ON public.clients 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_compteurs_updated_at 
    BEFORE UPDATE ON public.compteurs 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_tranches_updated_at 
    BEFORE UPDATE ON public.tranches 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
