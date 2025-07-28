<?php

require_once __DIR__ . '/../vendor/autoload.php';

use Dotenv\Dotenv;

// Charger les variables d'environnement
$dotenv = Dotenv::createImmutable(__DIR__ . '/../');
$dotenv->load();

try {
    // Suppression des espaces en trop dans les variables .env
    $host     = trim($_ENV['DB_HOST'] ?? 'aws-0-eu-west-3.pooler.supabase.com');
    $port     = trim($_ENV['DB_PORT'] ?? '5432');
    $dbname   = trim($_ENV['DB_NAME'] ?? 'postgres');
    $username = trim($_ENV['DB_USER'] ?? 'postgres.wyrxigcqkyrxiexzjuyq');
    $password = trim($_ENV['DB_PASSWORD'] ?? 'madie');

    // Chaîne de connexion
    $dsn = "pgsql:host=$host;port=$port;dbname=$dbname";

    // Connexion PDO
    $pdo = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);

    echo "✅ Connexion à la base de données réussie.\n";

    // Vérifie si l'on passe l'option --reset
    $reset = in_array('--reset', $argv);

    if ($reset) {
        echo "🔄 Suppression des données existantes...\n";
        $pdo->exec("TRUNCATE TABLE request_logs RESTART IDENTITY CASCADE");
        $pdo->exec("TRUNCATE TABLE citoyens RESTART IDENTITY CASCADE");
        $pdo->exec("TRUNCATE TABLE logs_achats RESTART IDENTITY CASCADE"); // Ligne ajoutée
        echo "✅ Données supprimées.\n";
    }

    // Chargement des fichiers .sql
    $seedFiles = glob(__DIR__ . '/*.sql');
    sort($seedFiles);

    foreach ($seedFiles as $file) {
        $filename = basename($file);
        echo "📥 Exécution du seed : $filename\n";
        $sql = file_get_contents($file);
        $pdo->exec($sql);
        echo "✅ Seed $filename exécuté avec succès.\n";
    }

    echo "\n🎉 Tous les fichiers de seed ont été exécutés avec succès.\n";

} catch (PDOException $e) {
    echo "❌ Erreur de base de données : " . $e->getMessage() . "\n";
    exit(1);
} catch (Exception $e) {
    echo "❌ Erreur : " . $e->getMessage() . "\n";
    exit(1);
}
