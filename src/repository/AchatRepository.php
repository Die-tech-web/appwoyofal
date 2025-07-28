<?php

namespace App\Repository;

use App\Entity\Achat;
use DevNoKage\Database;


class AchatRepository
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
    
    public function save(Achat $achat): Achat
    {
        $sql = "INSERT INTO achats (reference, code_recharge, numero_compteur, montant, 
                nbre_kwt, tranche, prix_kw, date_achat, statut, client_nom) 
                VALUES (:reference, :code_recharge, :numero_compteur, :montant, 
                :nbre_kwt, :tranche, :prix_kw, :date_achat, :statut, :client_nom) RETURNING id";
        
        $stmt = $this->connection->prepare($sql);
        $stmt->bindValue(':reference', $achat->getReference());
        $stmt->bindValue(':code_recharge', $achat->getCodeRecharge());
        $stmt->bindValue(':numero_compteur', $achat->getNumeroCompteur());
        $stmt->bindValue(':montant', $achat->getMontant());
        $stmt->bindValue(':nbre_kwt', $achat->getNbreKwt());
        $stmt->bindValue(':tranche', $achat->getTranche());
        $stmt->bindValue(':prix_kw', $achat->getPrixKw());
        $stmt->bindValue(':date_achat', $achat->getDateAchat()->format('Y-m-d H:i:s'));
        $stmt->bindValue(':statut', $achat->getStatut());
        $stmt->bindValue(':client_nom', $achat->getClientNom());
        
        $stmt->execute();
        $id = $stmt->fetchColumn();
        $achat->setId($id);
        
        return $achat;
    }
    
    public function findByReference(string $reference): ?Achat
    {
        $sql = "SELECT * FROM achats WHERE reference = :reference";
        $stmt = $this->connection->prepare($sql);
        $stmt->bindParam(':reference', $reference);
        $stmt->execute();
        
        $data = $stmt->fetch();
        if (!$data) {
            return null;
        }
        
        return $this->hydrate($data);
    }
    
    private function hydrate(array $data): Achat
    {
        $achat = new Achat($data['id']);
        $achat->setReference($data['reference'])
              ->setCodeRecharge($data['code_recharge'])
              ->setNumeroCompteur($data['numero_compteur'])
              ->setMontant($data['montant'])
              ->setNbreKwt($data['nbre_kwt'])
              ->setTranche($data['tranche'])
              ->setPrixKw($data['prix_kw'])
              ->setDateAchat(new \DateTime($data['date_achat']))
              ->setStatut($data['statut'])
              ->setClientNom($data['client_nom']);
        
        return $achat;
    }

    private function genererReference(): string
    {
        $date = date('Ymd');
        $timestamp = time();
        $random = rand(1000, 9999);
        
        // Format: WOY-YYYYMMDD-TTTT (T = 4 derniers chiffres du timestamp)
        return "WOY-{$date}-" . substr($timestamp . $random, -4);
    }
    
    private function genererCodeRecharge(): string
    {
        // Générer un code unique basé sur timestamp + random
        $timestamp = microtime(true) * 10000; // Microsecondes
        
        $codes = [];
        for ($i = 0; $i < 4; $i++) {
            $codes[] = str_pad(rand(1000, 9999), 4, '0', STR_PAD_LEFT);
        }
        
        return implode('-', $codes);
    }
}