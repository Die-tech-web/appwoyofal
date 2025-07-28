<?php

namespace App\Repository;

use App\Entity\Tranche;
use DevNoKage\Database;


class TrancheRepository
{
    private \PDO $connection;
    
    public function __construct()
    {
       $this->connection = Database::getInstance(
            'pgsql',
            'aws-0-eu-west-3.pooler.supabase.com ',
            5432,
            'postgres',
            'postgres.wyrxigcqkyrxiexzjuyq',
            'madie'
        )->getConnexion();
    }
    public function findAll(): array
    {
        $sql = "SELECT * FROM tranches ORDER BY ordre ASC";
        $stmt = $this->connection->prepare($sql);
        $stmt->execute();
        
        $tranches = [];
        while ($data = $stmt->fetch()) {
            $tranches[] = $this->hydrate($data);
        }
        
        return $tranches;
    }
    
    public function findForMontant(float $montant): ?Tranche
    {
        $sql = "SELECT * FROM tranches WHERE :montant >= minimum AND :montant <= maximum ORDER BY ordre ASC LIMIT 1";
        $stmt = $this->connection->prepare($sql);
        $stmt->bindValue(':montant', $montant);
        $stmt->execute();
        
        $data = $stmt->fetch();
        if (!$data) {
            return null;
        }
        
        return $this->hydrate($data);
    }
    
    private function hydrate(array $data): Tranche
    {
        $tranche = new Tranche($data['id']);
        $tranche->setNom($data['nom'])
                ->setMin($data['minimum'])
                ->setMax($data['maximum'])
                ->setPrixKw($data['prix_kw'])
                ->setOrdre($data['ordre']);
        
        return $tranche;
    }
}