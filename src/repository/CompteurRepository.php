<?php

namespace App\Repository;

use App\Entity\Compteur;
use DevNoKage\Database;

class CompteurRepository
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

    public function findByNumero(string $numero): ?Compteur
    {
        $sql = "SELECT * FROM compteurs WHERE numero = :numero AND actif = true";
        $stmt = $this->connection->prepare($sql);
        $stmt->bindParam(':numero', $numero);
        $stmt->execute();

        $data = $stmt->fetch();
        // Debugging line to check fetched data
        if (!$data) {
            return null;
        }

        return $this->hydrate($data);
    }

    public function save(Compteur $compteur): Compteur
    {
        if ($compteur->getId()) {
            return $this->update($compteur);
        }

        $sql = "INSERT INTO compteurs (numero, client_id, actif, date_creation) 
                VALUES (:numero, :client_id, :actif, :date_creation) RETURNING id";

        $stmt = $this->connection->prepare($sql);
        $stmt->bindValue(':numero', $compteur->getNumero());
        $stmt->bindValue(':client_id', $compteur->getClientId());
        $stmt->bindValue(':actif', $compteur->isActif(), \PDO::PARAM_BOOL);
        $stmt->bindValue(':date_creation', $compteur->getDateCreation()->format('Y-m-d H:i:s'));

        $stmt->execute();
        $id = $stmt->fetchColumn();
        $compteur->setId($id);

        return $compteur;
    }

    private function update(Compteur $compteur): Compteur
    {
        $sql = "UPDATE compteurs SET numero = :numero, client_id = :client_id, 
                actif = :actif WHERE id = :id";

        $stmt = $this->connection->prepare($sql);
        $stmt->bindValue(':id', $compteur->getId());
        $stmt->bindValue(':numero', $compteur->getNumero());
        $stmt->bindValue(':client_id', $compteur->getClientId());
        $stmt->bindValue(':actif', $compteur->isActif(), \PDO::PARAM_BOOL);

        $stmt->execute();

        return $compteur;
    }

    private function hydrate(array $data): Compteur
    {
        $compteur = new Compteur($data['id']);
        $compteur->setNumero($data['numero'])
            ->setClientId($data['client_id'])
            ->setActif($data['actif'])
            ->setDateCreation(new \DateTime($data['date_creation']));

        return $compteur;
    }
}