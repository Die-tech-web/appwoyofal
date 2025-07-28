<?php

require_once __DIR__ . '/../vendor/autoload.php';

use Dotenv\Dotenv;

$dotenv = Dotenv::createImmutable(__DIR__ . '/../');
$dotenv->load();

$driver = $_ENV['DB_CONNECTION'] ?? 'pgsql';
$host = $_ENV['DB_HOST'] ?? 'aws-0-eu-west-3.pooler.supabase.com';
$port = $_ENV['DB_PORT'] ?? '5432';
$dbName = $_ENV['DB_DATABASE'] ?? 'postgres';
$user = $_ENV['DB_USERNAME'] ?? 'postgres.wyrxigcqkyrxiexzjuyq';
$password = $_ENV['DB_PASSWORD'] ?? 'madie';

if (empty($dbName) || empty($user)) {
    die("❌ Les variables de base de données ne sont pas correctement définies dans .env\n");
}

$dsn = "$driver:host=$host;port=$port;dbname=$dbName";

try {
    echo "🔗 Connexion à la base de données Woyofal...\n";
    echo "📋 Configuration: $driver://$user@$host:$port/$dbName\n\n";
    
    $pdo = new PDO($dsn, $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "✅ Connexion réussie à la base de données\n\n";

    // =====================================
    // 1. EXTENSION UUID-OSSP
    // =====================================
    echo "📦 Installation de l'extension UUID-OSSP...\n";
    $pdo->exec("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\" WITH SCHEMA public;");
    echo "✅ Extension UUID-OSSP installée\n\n";

    // =====================================
    // 2. FONCTIONS POSTGRESQL
    // =====================================
    echo "🔧 Création des fonctions PostgreSQL...\n";

    // Fonction pour mettre à jour updated_at
    $pdo->exec("
        CREATE OR REPLACE FUNCTION update_updated_at_column() 
        RETURNS TRIGGER AS \$\$
        BEGIN
            NEW.updated_at = CURRENT_TIMESTAMP;
            RETURN NEW;
        END;
        \$\$ LANGUAGE plpgsql;
    ");

    // Fonction pour vérifier l'existence d'un code recharge
    $pdo->exec("
        CREATE OR REPLACE FUNCTION exists_code_recharge(code text) 
        RETURNS boolean AS \$\$
        BEGIN
            RETURN EXISTS (SELECT 1 FROM achats WHERE code_recharge = code);
        END;
        \$\$ LANGUAGE plpgsql;
    ");

    // Fonction pour générer un code de recharge
    $pdo->exec("
        CREATE OR REPLACE FUNCTION generer_code_recharge() 
        RETURNS text AS \$\$
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
        \$\$ LANGUAGE plpgsql;
    ");

    // Fonction pour générer une référence d'achat
    $pdo->exec("
        CREATE OR REPLACE FUNCTION generer_reference_achat() 
        RETURNS text AS \$\$
        DECLARE
            nouvelle_reference TEXT;
            date_courante TEXT;
            numero_sequence INTEGER;
        BEGIN
            -- Format: WOY-YYYYMMDD-NNNN
            date_courante := TO_CHAR(CURRENT_DATE, 'YYYYMMDD');
            
            -- Obtenir le prochain numéro de séquence pour aujourd'hui
            SELECT COALESCE(MAX(CAST(SUBSTRING(reference FROM 'WOY-\\d{8}-(\\d{4})') AS INTEGER)), 0) + 1
            INTO numero_sequence
            FROM achats
            WHERE reference LIKE 'WOY-' || date_courante || '-%';
            
            nouvelle_reference := 'WOY-' || date_courante || '-' || LPAD(numero_sequence::TEXT, 4, '0');
            
            RETURN nouvelle_reference;
        END;
        \$\$ LANGUAGE plpgsql;
    ");

    // Fonction pour récupérer le dernier achat par date
    $pdo->exec("
        CREATE OR REPLACE FUNCTION get_last_achat_by_date(date_str text) 
        RETURNS TABLE(reference text) AS \$\$
        BEGIN
            RETURN QUERY
            SELECT a.reference
            FROM achats a
            WHERE a.reference LIKE 'WOY-' || date_str || '-%'
            ORDER BY a.reference DESC
            LIMIT 1;
        END;
        \$\$ LANGUAGE plpgsql;
    ");

    echo "✅ Fonctions PostgreSQL créées\n\n";

    // =====================================
    // 3. TABLE CLIENTS
    // =====================================
    echo "👥 Création de la table clients...\n";
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS clients (
            id SERIAL PRIMARY KEY,
            nom VARCHAR(100) NOT NULL,
            prenom VARCHAR(100) NOT NULL,
            telephone VARCHAR(20) NOT NULL,
            adresse TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    ");

    // Trigger pour updated_at sur clients
    $pdo->exec("
        DROP TRIGGER IF EXISTS update_clients_updated_at ON clients;
        CREATE TRIGGER update_clients_updated_at 
        BEFORE UPDATE ON clients 
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    ");

    echo "✅ Table clients créée\n";

    // =====================================
    // 4. TABLE COMPTEURS
    // =====================================
    echo "⚡ Création de la table compteurs...\n";
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS compteurs (
            id SERIAL PRIMARY KEY,
            numero VARCHAR(50) NOT NULL UNIQUE,
            client_id INTEGER NOT NULL,
            actif BOOLEAN DEFAULT true,
            date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_compteurs_client FOREIGN KEY (client_id) 
                REFERENCES clients(id) ON DELETE CASCADE
        );
    ");

    // Index sur compteurs
    $pdo->exec("CREATE INDEX IF NOT EXISTS idx_compteurs_numero ON compteurs(numero);");
    $pdo->exec("CREATE INDEX IF NOT EXISTS idx_compteurs_client ON compteurs(client_id);");
    $pdo->exec("CREATE INDEX IF NOT EXISTS idx_compteurs_actif ON compteurs(actif);");

    // Trigger pour updated_at sur compteurs
    $pdo->exec("
        DROP TRIGGER IF EXISTS update_compteurs_updated_at ON compteurs;
        CREATE TRIGGER update_compteurs_updated_at 
        BEFORE UPDATE ON compteurs 
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    ");

    echo "✅ Table compteurs créée\n";

    // =====================================
    // 5. TABLE TRANCHES
    // =====================================
    echo "📊 Création de la table tranches...\n";
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS tranches (
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
            CONSTRAINT check_prix_positif CHECK (prix_kw > 0)
        );
    ");

    // Index sur tranches
    $pdo->exec("CREATE INDEX IF NOT EXISTS idx_tranches_ordre ON tranches(ordre);");

    // Trigger pour updated_at sur tranches
    $pdo->exec("
        DROP TRIGGER IF EXISTS update_tranches_updated_at ON tranches;
        CREATE TRIGGER update_tranches_updated_at 
        BEFORE UPDATE ON tranches 
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    ");

    echo "✅ Table tranches créée\n";

    // =====================================
    // 6. TABLE ACHATS
    // =====================================
    echo "💰 Création de la table achats...\n";
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS achats (
            id SERIAL PRIMARY KEY,
            reference VARCHAR(100) NOT NULL UNIQUE,
            code_recharge VARCHAR(255) NOT NULL UNIQUE,
            numero_compteur VARCHAR(100) NOT NULL,
            montant NUMERIC(10,2) NOT NULL,
            nbre_kwt NUMERIC(10,2) NOT NULL,
            tranche VARCHAR(50),
            prix_kw NUMERIC(10,2),
            client_nom VARCHAR(255),
            date_achat TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            statut VARCHAR(50) DEFAULT 'success'
        );
    ");

    // Index sur achats
    $pdo->exec("CREATE INDEX IF NOT EXISTS idx_achats_reference ON achats(reference);");
    $pdo->exec("CREATE INDEX IF NOT EXISTS idx_achats_code_recharge ON achats(code_recharge);");
    $pdo->exec("CREATE INDEX IF NOT EXISTS idx_achats_numero_compteur ON achats(numero_compteur);");
    $pdo->exec("CREATE INDEX IF NOT EXISTS idx_achats_date_achat ON achats(date_achat);");
    $pdo->exec("CREATE INDEX IF NOT EXISTS idx_achats_statut ON achats(statut);");

    echo "✅ Table achats créée\n";

    // =====================================
    // 7. TABLE LOGS_ACHATS
    // =====================================
    echo "📝 Création de la table logs_achats...\n";
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS logs_achats (
            id SERIAL PRIMARY KEY,
            date_heure TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
            localisation VARCHAR(255),
            adresse_ip VARCHAR(45),
            statut VARCHAR(50) NOT NULL,
            numero_compteur VARCHAR(100),
            code_recharge VARCHAR(255),
            nbre_kwt NUMERIC(10,2),
            message_erreur TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    ");

    // Index sur logs_achats
    $pdo->exec("CREATE INDEX IF NOT EXISTS idx_logs_achats_date_heure ON logs_achats(date_heure);");
    $pdo->exec("CREATE INDEX IF NOT EXISTS idx_logs_achats_statut ON logs_achats(statut);");
    $pdo->exec("CREATE INDEX IF NOT EXISTS idx_logs_achats_numero_compteur ON logs_achats(numero_compteur);");

    echo "✅ Table logs_achats créée\n\n";

    echo "🎉 Migration de structure terminée avec succès !\n";
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    echo "📋 Résumé des éléments créés:\n";
    echo "📦 Extensions:\n";
    echo "   • uuid-ossp\n\n";
    echo "🔧 Fonctions PostgreSQL:\n";
    echo "   • update_updated_at_column()\n";
    echo "   • exists_code_recharge()\n";
    echo "   • generer_code_recharge()\n";
    echo "   • generer_reference_achat()\n";
    echo "   • get_last_achat_by_date()\n\n";
    echo "🗃️ Tables créées (avec contraintes et index):\n";
    echo "   • clients (avec trigger updated_at)\n";
    echo "   • compteurs (avec FK vers clients)\n";
    echo "   • tranches (avec contraintes métier)\n";
    echo "   • achats (avec contraintes d'unicité)\n";
    echo "   • logs_achats (pour audit)\n\n";
    echo "➡️  Prochaine étape: Exécuter le seeder pour insérer les données\n";
    echo "    php database/seeder.php\n";
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";

} catch (PDOException $e) {
    echo "❌ Erreur PDO : " . $e->getMessage() . "\n";
    echo "📍 Ligne : " . $e->getLine() . "\n";
    echo "📄 Fichier : " . $e->getFile() . "\n";
} catch (Exception $e) {
    echo "❌ Erreur générale : " . $e->getMessage() . "\n";
}