<?php

require_once __DIR__ . '/../vendor/autoload.php';

// Charger les variables d'environnement
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->load();

try {
    $host = $_ENV['DB_HOST'] ?? 'aws-0-eu-west-3.pooler.supabase.com';
    $port = $_ENV['DB_PORT'] ?? '5432';
    $dbname = $_ENV['DB_NAME'] ?? 'postgres';
    $username = $_ENV['DB_USER'] ?? 'postgres.wyrxigcqkyrxiexzjuyq';
    $password = $_ENV['DB_PASSWORD'] ?? 'madie';

    

    $dsn = "pgsql:host=$host;port=$port;dbname=$dbname";
    $pdo = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);

    echo "Connexion à la base de données réussie!\n";

    // Vérifier si on doit reset les tables
    $reset = in_array('--reset', $argv);

    if ($reset) {
        echo "Suppression des tables existantes...\n";
        $pdo->exec("DROP TABLE IF EXISTS request_logs CASCADE");
        $pdo->exec("DROP TABLE IF EXISTS citoyens CASCADE");
        $pdo->exec("DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE");
        echo "Tables supprimées.\n";
    }

    // Exécuter les migrations
    $migrationFiles = glob(__DIR__ . '/*.sql');
    sort($migrationFiles);

    foreach ($migrationFiles as $file) {
        $filename = basename($file);
        echo "Exécution de la migration: $filename\n";
        
        $sql = file_get_contents($file);
        $pdo->exec($sql);
        
        echo "Migration $filename exécutée avec succès.\n";
    }

    echo "\nToutes les migrations ont été exécutées avec succès!\n";

} catch (PDOException $e) {
    echo "Erreur de connexion ou d'exécution: " . $e->getMessage() . "\n";
    exit(1);
} catch (Exception $e) {
    echo "Erreur: " . $e->getMessage() . "\n";
    exit(1);
}