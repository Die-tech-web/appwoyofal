<?php

require_once __DIR__ . '/../vendor/autoload.php';

// Charger les variables d'environnement
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->load();

try {
    $host = $_ENV['DB_HOST'] ?? 'aws-0-eu-west-3.pooler.supabase.com ';
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

    // Vérifier si on doit reset les données
    $reset = in_array('--reset', $argv);

    if ($reset) {
        echo "Suppression des données existantes...\n";
        $pdo->exec("TRUNCATE TABLE request_logs RESTART IDENTITY CASCADE");
        $pdo->exec("TRUNCATE TABLE citoyens RESTART IDENTITY CASCADE");
        echo "Données supprimées.\n";
    }

    // Exécuter les fichiers SQL de seed
    $seedFiles = glob(__DIR__ . '/*.sql');
    sort($seedFiles);

    foreach ($seedFiles as $file) {
        $filename = basename($file);
        echo "Exécution du seed: $filename\n";
        $sql = file_get_contents($file);
        $pdo->exec($sql);
        echo "Seed $filename exécuté avec succès.\n";
    }

    echo "\nToutes les données de seed ont été insérées avec succès!\n";

} catch (PDOException $e) {
    echo "Erreur de base de données: " . $e->getMessage() . "\n";
    exit(1);
} catch (Exception $e) {
    echo "Erreur: " . $e->getMessage() . "\n";
    exit(1);
}