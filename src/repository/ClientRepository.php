<?php

namespace App\Repository;

use App\Entity\Client;
use DevNoKage\Database;


class ClientRepository
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
    
    public function findById(int $id): ?Client
    {
        $sql = "SELECT * FROM clients WHERE id = :id";
        $stmt = $this->connection->prepare($sql);
        $stmt->bindParam(':id', $id, \PDO::PARAM_INT);
        $stmt->execute();
        
        $data = $stmt->fetch();
        if (!$data) {
            return null;
        }
        
        return $this->hydrate($data);
    }
    
    public function save(Client $client): Client
    {
        if ($client->getId()) {
            return $this->update($client);
        }
        
        $sql = "INSERT INTO clients (nom, prenom, telephone, adresse) 
                VALUES (:nom, :prenom, :telephone, :adresse) RETURNING id";
        
        $stmt = $this->connection->prepare($sql);
        $stmt->bindValue(':nom', $client->getNom());
        $stmt->bindValue(':prenom', $client->getPrenom());
        $stmt->bindValue(':telephone', $client->getTelephone());
        $stmt->bindValue(':adresse', $client->getAdresse());
        
        $stmt->execute();
        $id = $stmt->fetchColumn();
        $client->setId($id);
        
        return $client;
    }
    
    private function update(Client $client): Client
    {
        $sql = "UPDATE clients SET nom = :nom, prenom = :prenom, 
                telephone = :telephone, adresse = :adresse WHERE id = :id";
        
        $stmt = $this->connection->prepare($sql);
        $stmt->bindValue(':id', $client->getId());
        $stmt->bindValue(':nom', $client->getNom());
        $stmt->bindValue(':prenom', $client->getPrenom());
        $stmt->bindValue(':telephone', $client->getTelephone());
        $stmt->bindValue(':adresse', $client->getAdresse());
        
        $stmt->execute();
        
        return $client;
    }
    
    private function hydrate(array $data): Client
    {
        $client = new Client($data['id']);
        $client->setNom($data['nom'])
               ->setPrenom($data['prenom'])
               ->setTelephone($data['telephone'])
               ->setAdresse($data['adresse']);
        
        return $client;
    }
}